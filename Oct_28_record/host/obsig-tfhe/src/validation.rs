//! Explicit CPU test oracle. Private-key operations here never belong in the board service.
use crate::{postbox::Inbox, receiver::Receiver, sender::MessageRequest, Config};
use serde::Serialize;
use sha2::{Digest, Sha256};
use std::{collections::HashMap, fs, io::Write, path::Path, sync::{Mutex, OnceLock}};
use tfhe::shortint::Ciphertext;

#[derive(Clone, Debug, PartialEq)]
pub struct PlainMessage { pub owner: String, pub signal: Vec<u64> }
static INPUTS: OnceLock<Mutex<HashMap<String, PlainMessage>>> = OnceLock::new();
static COUNTS: Mutex<(usize, usize, usize, usize)> = Mutex::new((0,0,0,0));

fn id(message: &MessageRequest) -> String {
    format!("{:x}", Sha256::digest(bincode::serialize(message).unwrap()))
}
pub fn initialize() {
    // A failed/incomplete run must not leave an old successful marker in use.
    fs::create_dir("validation").expect("validation/ already exists; choose a fresh --run-dir for validation");
    fs::write("validation/FORMAT.txt", "CPU test vectors; not HPU-native key/memory layout. Each *.ctlist.bin is bincode Vec<tfhe::shortint::Ciphertext> with TFHE 1.8.1. Each *.u64le concatenates 2049 little-endian u64 coefficients per ciphertext (mask then body). SHA-256 covers raw bytes. The *.ctlist.bin metadata must also accompany software reconstruction. expected.txt records the owner and expected decrypted PI/filtered output. Private keys stay in the run's wallet; never deploy them to the board.\n").unwrap();
}
pub fn register_message(message: &MessageRequest, owner: &str, signal: &[u64]) {
    let expected=PlainMessage{owner:owner.to_owned(),signal:signal.to_vec()};
    if let Some(previous)=INPUTS.get_or_init(Default::default).lock().unwrap().insert(id(message),expected.clone()) {
        assert_eq!(previous,expected,"same ciphertext assigned conflicting plaintext expectations");
    }
}
pub fn lookup(message: &MessageRequest) -> PlainMessage {
    INPUTS.get().unwrap().lock().unwrap().get(&id(message)).expect("missing input oracle").clone()
}
fn write_bin<T: Serialize + ?Sized>(path: &Path, value: &T) {
    fs::write(path,bincode::serialize(value).unwrap()).unwrap();
}
fn save_list(dir: &Path, name: &str, list: &[Ciphertext]) {
    for ct in list {assert_eq!(ct.ct.as_ref().len(),2049);}
    let raw:Vec<u8>=list.iter().flat_map(|ct|ct.ct.as_ref().iter().flat_map(|x|x.to_le_bytes())).collect();
    fs::write(dir.join(format!("{name}.u64le")),&raw).unwrap();
    write_bin(&dir.join(format!("{name}.ctlist.bin")),list);
    let mut f=fs::OpenOptions::new().create(true).append(true).open(dir.join("files.csv")).unwrap();
    writeln!(f,"{name},{},{},{:x}",list.len(),raw.len(),Sha256::digest(&raw)).unwrap();
}
fn decode(receiver: &Receiver, list: &[Ciphertext])->Vec<u64> {
    list.iter().map(|ct|receiver.sk1.decrypt(ct)).collect()
}
pub fn decode_inbox(receiver:&Receiver,inbox:&Inbox)->Vec<Vec<u64>> {
    inbox.slots.iter().map(|s|decode(receiver,&s.ciphertext)).collect()
}

pub fn record_pair(receiver:&Receiver, message:&PlainMessage, batch:usize, index:usize,
    input_tag:&[Ciphertext], input_signal:&[Ciphertext], tag:&[Ciphertext], signal:&[Ciphertext],
    pi:&Ciphertext, filtered:&[Ciphertext]) {
    let matching=receiver.id==message.owner;
    if matching {
        assert_eq!(decode(receiver,input_signal),message.signal,"compact input expansion");
        assert_eq!(decode(receiver,tag),vec![1;16],"rectified matching tag");
        assert_eq!(decode(receiver,signal),message.signal,"rectified matching signal");
    }
    assert_eq!(receiver.sk1.decrypt(pi),u64::from(matching),"PI mismatch: receiver={} owner={} batch={} message={}",receiver.id,message.owner,batch,index);
    let expected=if matching {message.signal.clone()} else {vec![0;message.signal.len()]};
    assert_eq!(decode(receiver,filtered),expected,"filter continuation mismatch");
    let dir=Path::new("validation").join(&receiver.id).join(format!("batch_{batch:03}_message_{index:03}"));
    fs::create_dir_all(&dir).unwrap();
    for (name,list) in [("input_tag",input_tag),("input_signal",input_signal),("rectified_tag",tag),
        ("rectified_signal",signal),("pi",std::slice::from_ref(pi)),("filtered_signal",filtered)] {save_list(&dir,name,list);}
    fs::write(dir.join("expected.txt"),format!("parameter_id={}\nreceiver={}\nowner={}\nmatching={}\npi={}\nfiltered={expected:?}\n",crate::crypto_params::PARAMETER_ID,receiver.id,message.owner,matching,u64::from(matching))).unwrap();
    let mut counts=COUNTS.lock().unwrap();
    if matching {counts.0+=1;} else {counts.1+=1;}
}

pub fn check_update(receiver:&Receiver,before:&[Vec<u64>],inbox:&Inbox,plain:&[PlainMessage],batch:usize) {
    let matching:Vec<_>=plain.iter().filter(|p|p.owner==receiver.id).collect();
    assert!(matching.len()<=1,"prototype batch must contain at most one message per recipient");
    let mut expected=before.to_vec();
    if let Some(message)=matching.first() {
        expected.insert(0,message.signal.clone()); expected.truncate(before.len());
    }
    assert_eq!(decode_inbox(receiver,inbox),expected,"CMUX/inbox update receiver={} batch={}",receiver.id,batch);
    COUNTS.lock().unwrap().2+=1;
}
pub fn check_final(receiver:&Receiver,inbox:&Inbox,messages:usize) {
    // Independent oracle for generate_test_signals: newest signal is at slot zero.
    let expected:Vec<Vec<u64>>=(0..inbox.slots.len()).map(|slot| {
        if slot<messages {
            let i=messages-1-slot;
            (0..crate::utility::SLOT_SIZE_CIPHERTEXT).map(|j|((i+j)%crate::utility::MESSAGE_SPACE_MOD) as u64).collect()
        } else {vec![0;crate::utility::SLOT_SIZE_CIPHERTEXT]}
    }).collect();
    let actual=decode_inbox(receiver,inbox);
    assert_eq!(actual,expected,"final inbox receiver={}",receiver.id);
    let dir=Path::new("validation").join(&receiver.id);
    fs::create_dir_all(&dir).unwrap();
    let ciphertexts:Vec<_>=inbox.slots.iter().flat_map(|slot|slot.ciphertext.clone()).collect();
    save_list(&dir,"final_inbox",&ciphertexts);
    fs::write(dir.join("final_expected.txt"),format!("slot order: newest first\n{expected:?}\n")).unwrap();
    println!("FINAL_INBOX_PASS: {} {actual:?}",receiver.id);
    COUNTS.lock().unwrap().3+=1;
}
pub fn finish(config:&Config) {
    let counts=*COUNTS.lock().unwrap();
    assert_eq!(counts.0,config.num_recipients*config.num_messages);
    assert_eq!(counts.3,config.num_recipients);
    let summary=format!("OSIG_HPU_CPU_VALIDATION_PASS\nparameter_id={}\nmatching_pairs={}\nnonmatching_pairs={}\nbatch_inbox_checks={}\nfinal_inboxes={}\nconfig=batch:{},shard:{},recipients:{},messages:{},capacity:{}\nCPU execution only; FPGA not exercised.\n",crate::crypto_params::PARAMETER_ID,counts.0,counts.1,counts.2,counts.3,config.batch_size,config.shard_size,config.num_recipients,config.num_messages,config.inbox_cap);
    fs::write("validation/PASS.txt",&summary).unwrap();
    println!("{summary}");
}
