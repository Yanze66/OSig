use crate::sender::MessageRequest;
use crate::utility;
use chrono::Local;
use rand::{RngExt};
use std::collections::HashMap;
use std::path::PathBuf;
use tfhe::shortint::{Ciphertext, CompactPublicKey, ServerKey};

pub struct PostBox {
    pub id: String,
    inbox_map: HashMap<String, Inbox>,
    pub inbox_id_vec: Vec<String>,
    pub msg_q: Vec<Vec<MessageRequest>>,
}

#[derive(Clone)]
pub struct Inbox {
    pub id: String,
    pub public_key: CompactPublicKey,
    pub server_key: ServerKey,
    pub slots: Vec<Slot>,
    pub three_trivial_ct: Ciphertext,
    pub one_trivial_ct: Ciphertext,
    pub zero_trivial_ct: Ciphertext,
}
#[derive(Clone)]
pub struct Slot {
    pub ciphertext: Vec<Ciphertext>,
}

impl PostBox {
    pub fn new(id: String) -> Self {
        PostBox {
            id,
            inbox_map: HashMap::new(),
            inbox_id_vec: Vec::new(),
            msg_q: Vec::new(),
        }
    }

    pub fn set_inbox(&mut self, id: String, inbox: &Inbox) {
        if !self.inbox_id_vec.contains(&id) {
            self.inbox_id_vec.push(id.clone());
        }
        self.inbox_map.insert(id, inbox.clone());
    }

    pub fn get_inbox(&self, id: &str) -> Option<&Inbox> {
        let inbox_option = self.inbox_map.get(id);
        inbox_option
    }

    pub fn push_new_message_to_q(&mut self, message_req_vec: Vec<MessageRequest>) {
        self.msg_q.push(message_req_vec);
    }

    pub fn get_msg_q_size(&self) -> usize {
        self.msg_q.len()
    }

    pub fn get_a_random_inbox(&self) -> Inbox {
        if self.inbox_id_vec.is_empty() {
            panic!("No inboxes registered");
        }

        let mut rng = rand::rng();
        let idx = rng.random_range(0..self.inbox_id_vec.len());

        self.inbox_map.get(&self.inbox_id_vec[idx]).unwrap().clone()
    }

    pub fn get_message_by_index(&self, index: usize) -> Vec<MessageRequest> {
        self.msg_q[index].clone()
    }

    fn dump(&self, fun_name: &str, msg: String) {
        println!("{} | POSTBOX: {} | {}", Local::now(), fun_name, msg);
    }
}
impl Inbox {
    pub fn new(id: String, public_key: CompactPublicKey, server_key: ServerKey, inbox_capacity: usize) -> Self {
        // Build cache folder: wallet/{id}/inbox/
        let base: PathBuf = ["wallet", &id, "inbox"].iter().collect();
        utility::ensure_dir(&base);

        // Tie cache to the *public key* too (avoid stale cache if key changes for same id)
        let pk_hash = utility::hash_of(&public_key);

        let zero_trivial_ct_path = base.join(format!("zero_trivial_ct.{pk_hash}.bin"));
        let one_trivial_ct_path = base.join(format!("one_trivial_ct.{pk_hash}.bin"));
        let three_trivial_ct_path = base.join(format!("three_trivial_ct.{pk_hash}.bin"));

        let zero_trivial_ct =
            utility::load_or_create(&zero_trivial_ct_path, || server_key.create_trivial(0));
        let one_trivial_ct =
            utility::load_or_create(&one_trivial_ct_path, || server_key.create_trivial(1));
        let three_trivial_ct =
            utility::load_or_create(&three_trivial_ct_path, || server_key.create_trivial(3));

        let slots: Vec<Slot> = (0..inbox_capacity)
            .map(|_| Slot {
                ciphertext: vec![zero_trivial_ct.clone(); utility::SLOT_SIZE_CIPHERTEXT],
            })
            .collect();

        let mut slot_filter_vector = vec![one_trivial_ct.clone()];
        slot_filter_vector.append(&mut vec![zero_trivial_ct.clone(); (inbox_capacity - 1)]);

        Self {
            id,
            slots,
            server_key,
            public_key,
            three_trivial_ct,
            one_trivial_ct,
            zero_trivial_ct,
        }
    }
}
