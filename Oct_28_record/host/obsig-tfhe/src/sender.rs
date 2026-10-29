use crate::utility;
use chrono::Local;
use serde::{Deserialize, Serialize};
use tfhe::shortint::ciphertext::CompactCiphertextList;
use tfhe::shortint::CompactPublicKey;

pub struct Sender {
    //fn: CreateRequest, SendRequest
}

impl Sender {
    pub fn new() -> Self {
        Sender {}
    }
    pub fn generate_signal(message: &Vec<u64>, public_key: &CompactPublicKey) -> MessageRequest {
        if message.len() != utility::SLOT_SIZE_CIPHERTEXT {
            panic!(
                "messages.len {} != utility::SLOT_SIZE_CIPHERTEXT {}",
                message.len(),
                utility::SLOT_SIZE_CIPHERTEXT
            );
        }

        let signal_ct = public_key.encrypt_slice(message);
        let vector = public_key.encrypt_slice(&vec![
            utility::TAG_VALUE;
            utility::L / utility::TAG_PLAIN_TEXT_SPACE
        ]);

        MessageRequest {
            signal: Signal {
                ciphertext: signal_ct,
            },
            tag: Tag { vector },
        }
    }

    fn dump(&self, fun_name: &str, msg: String) {
        println!("{} | SENDER: {} | {}", Local::now(), fun_name, msg);
    }
}
#[derive(Clone, Serialize, Deserialize)]
pub struct MessageRequest {
    pub signal: Signal,
    pub tag: Tag,
}
#[derive(Clone, Serialize, Deserialize)]
pub struct Signal {
    pub ciphertext: CompactCiphertextList,
}
#[derive(Clone, Serialize, Deserialize)]
pub struct Tag {
    pub vector: CompactCiphertextList,
}
