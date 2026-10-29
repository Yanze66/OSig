//! CPU oracle only. Does not contact a board or claim FPGA acceleration.
#[path = "../../crypto_params.rs"]
mod params;
use sha2::{Digest, Sha256};
use std::{error::Error, fs, io::Write, os::unix::fs::PermissionsExt, path::Path};
use tfhe::shortint::{gen_keys, Ciphertext};

type Result<T> = std::result::Result<T, Box<dyn Error>>;

fn save_ct(root: &Path, name: &str, ct: &Ciphertext, index: &mut fs::File) -> Result<()> {
    assert_eq!(ct.ct.as_ref().len(), 2049);
    let raw: Vec<u8> = ct.ct.as_ref().iter().flat_map(|x| x.to_le_bytes()).collect();
    let digest = format!("{:x}", Sha256::digest(&raw));
    fs::write(root.join(format!("{name}.u64le")), &raw)?;
    // The bincode file retains TFHE metadata; it is not an RTL memory format.
    let encoded = bincode::serialize(ct)?;
    let decoded: Ciphertext = bincode::deserialize(&encoded)?;
    assert_eq!(ct.ct.as_ref(), decoded.ct.as_ref());
    assert_eq!(encoded, bincode::serialize(&decoded)?);
    fs::write(root.join(format!("{name}.ct.bin")), encoded)?;
    writeln!(index, "{name},{},{digest}", raw.len())?;
    Ok(())
}

fn main() -> Result<()> {
    let args: Vec<_> = std::env::args_os().collect();
    if args.len() != 2 { return Err("Usage: cpu_reference NEW_OUTPUT_DIRECTORY".into()); }
    let root = Path::new(&args[1]);
    // Refuse to replace vectors/keys from an earlier run.
    fs::create_dir(root)?;
    let private = root.join("host_private");
    fs::create_dir(&private)?;
    fs::set_permissions(&private, fs::Permissions::from_mode(0o700))?;
    let vectors = root.join("vectors");
    fs::create_dir(&vectors)?;
    let mut index = fs::File::create(root.join("files.csv"))?;
    writeln!(index,"name,raw_bytes,raw_sha256")?;
    let mut expected = fs::File::create(root.join("expected.csv"))?;
    writeln!(expected,"operation,case,lhs,rhs,expected_plaintext")?;
    assert_eq!(params::PARAM_KEY_1.lwe_dimension.0,879);
    assert_eq!(params::PARAM_KEY_1.ks_base_log.0,2);
    assert_eq!(params::PARAM_KEY_1.ks_level.0,8);
    println!("PARAMETER_MATCH: TFHE V1_4 HPU KS32 TUniform 2M128. Generating independent test keys...");
    let (ck, sk) = gen_keys(params::PARAM_KEY_1);
    assert_eq!(ck.parameters(), params::PARAM_KEY_1.into());
    fs::write(root.join("PARAMETER_ID.txt"), params::PARAMETER_ID)?;
    fs::write(private.join("client_key.bin"), bincode::serialize(&ck)?)?;
    fs::write(private.join("cpu_server_key.bin"), bincode::serialize(&sk)?)?;
    fs::write(root.join("parameters.txt"), format!("{:?}\n",params::PARAM_KEY_1))?;
    let mut count = 0;
    // Include all carry values: an echo-only backend must fail these cases.
    for x in 0..16u64 {
        let mut ct = ck.unchecked_encrypt(x);
        assert_eq!(ck.decrypt_message_and_carry(&ct),x);
        save_ct(&vectors,&format!("extract_{x:02}_input"),&ct,&mut index)?;
        sk.message_extract_assign(&mut ct);
        assert_eq!(ck.decrypt_message_and_carry(&ct),x%4);
        assert!(ct.carry_is_empty());
        save_ct(&vectors,&format!("extract_{x:02}_cpu_output"),&ct,&mut index)?;
        writeln!(expected,"extract,{x},{x},,{}",x%4)?;
        count += 1;
    }
    println!("PASS: 16 message-extraction cases, including nonzero carry");
    // Match the application sequence: extract, smart AND, then CPU filtering.
    for a in 0..4u64 { for b in 0..4u64 {
        let id = a*4+b;
        let mut left = ck.encrypt(a);
        let mut right = ck.encrypt(b);
        sk.message_extract_assign(&mut right);
        save_ct(&vectors,&format!("and_{id:02}_lhs"),&left,&mut index)?;
        save_ct(&vectors,&format!("and_{id:02}_rhs"),&right,&mut index)?;
        sk.smart_bitand_assign(&mut left,&mut right);
        assert_eq!(ck.decrypt(&left),a&b);
        assert_eq!(ck.decrypt(&right),b);
        save_ct(&vectors,&format!("and_{id:02}_cpu_output"),&left,&mut index)?;
        save_ct(&vectors,&format!("and_{id:02}_rhs_after"),&right,&mut index)?;
        let mut signal = ck.encrypt(3);
        let filtered = sk.smart_mul_lsb(&mut left,&mut signal);
        assert_eq!(ck.decrypt(&filtered),((a&b)*3)%4);
        writeln!(expected,"and,{id},{a},{b},{}",a&b)?;
        count += 1;
    }}
    println!("PASS: 16 AND cases and 16 CPU multiplication continuations");
    // Exercise smart input refresh with carry, not just freshly extracted inputs.
    for (i,(a,b)) in [(15u64,3u64),(7,5),(12,9),(0,15)].into_iter().enumerate() {
        let mut left=ck.unchecked_encrypt(a);
        let mut right=ck.unchecked_encrypt(b);
        save_ct(&vectors,&format!("smart_{i}_lhs"),&left,&mut index)?;
        save_ct(&vectors,&format!("smart_{i}_rhs"),&right,&mut index)?;
        sk.smart_bitand_assign(&mut left,&mut right);
        assert_eq!(ck.decrypt(&left),(a&b)%4);
        assert_eq!(ck.decrypt(&right),b%4);
        save_ct(&vectors,&format!("smart_{i}_cpu_output"),&left,&mut index)?;
        save_ct(&vectors,&format!("smart_{i}_rhs_after"),&right,&mut index)?;
        writeln!(expected,"smart_and,{i},{a},{b},{}",(a&b)%4)?;
        count+=1;
    }
    // Sequential 16-tag reduction, including a non-matching tag.
    for matching in [true,false] {
        let mut pi=sk.create_trivial(1);
        for i in 0..16 {
            let value=if !matching && i==7 {0} else {1};
            let mut tag=ck.encrypt(value);
            sk.message_extract_assign(&mut tag);
            sk.smart_bitand_assign(&mut pi,&mut tag);
        }
        assert_eq!(ck.decrypt(&pi),u64::from(matching));
        count+=1;
    }
    index.sync_all()?;
    expected.sync_all()?;
    fs::write(root.join("PASS.txt"),format!("CPU_REFERENCE_PASS: {count} cases; plus 16 continuation checks. FPGA not exercised.\n"))?;
    println!("CPU_REFERENCE_PASS: {count} cases; plus 16 continuation checks. FPGA not exercised.");
    Ok(())
}
