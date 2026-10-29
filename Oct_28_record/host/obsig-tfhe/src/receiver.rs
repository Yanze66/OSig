use crate::postbox::Inbox;
use crate::profiling::CacheTiming;
use crate::utility;
use crate::utility::PARAM_KEY_1;
use chrono::{Duration, Local};
use std::path::PathBuf;
use std::time::Instant;
use tfhe::shortint::{
    ClientKey, CompactPublicKey, CompressedCompactPublicKey, ServerKey, ShortintParameterSet,
};
// ------------------------------
// Receiver
// ------------------------------

#[derive(Clone)]
pub struct Receiver {
    pub pk1: CompactPublicKey,
    pub pk1_server: ServerKey,
    pub sk1: ClientKey,
    pub id: String,
    k: usize, //expected_number_of_messages
}

impl Receiver {
    pub fn new(id: String, k: usize) -> (Self, CacheTiming) {
        // load or create all artifacts for key set #1 and #2
        let mut cache = CacheTiming::default();
        let kb1 = load_or_create_key_bundle(&id, 1, ShortintParameterSet::from(PARAM_KEY_1), &mut cache);

        (Receiver {
            // set #1
            pk1: kb1.pk,
            pk1_server: kb1.server_key,
            sk1: kb1.sk,

            id,
            k,
        }, cache)
    }

    pub fn read_inbox(&self, inbox: &Inbox) {
        let decrypted_inbox: Vec<Vec<u64>> = inbox
            .slots
            .iter()
            .map(|slot| {
                slot.ciphertext
                    .iter()
                    .map(|ciphertext| self.sk1.decrypt(ciphertext))
                    .collect()
            })
            .collect();

        self.dump(
            "read_inbox",
            format!("decrypted inbox {:?}", decrypted_inbox),
        );
    }

    pub fn read_inbox_test(&self, inbox: &Inbox) -> f64 {
        let start_time = Instant::now();

        let decrypted_inbox: Vec<Vec<u64>> = inbox
            .slots
            .iter()
            .rev()
            .map(|slot| {
                slot.ciphertext
                    .iter()
                    .map(|ciphertext| self.sk1.decrypt(ciphertext))
                    .collect()
            })
            .collect();

        let end_time = start_time.elapsed();

        //TODO Write Tests
/*
        let modulus = utility::MESSAGE_SPACE_MOD as u64;

        let cols = decrypted_inbox[0].len();

        // Basic shape/value checks
        for (ri, row) in decrypted_inbox.iter().enumerate() {
            assert_eq!(
                row.len(),
                cols,
                "row {ri} length mismatch: expected {cols}, got {}",
                row.len()
            );
            for (ci, &x) in row.iter().enumerate() {
                assert!(
                    x < modulus,
                    "value out of range at row {ri}, col {ci}: {x} (modulus {modulus})"
                );
            }
        }

        let mut test_row_start = decrypted_inbox.len() - self.k - 1;
        if test_row_start < 1 {
            test_row_start = 1
        }

        // Increment + circular across rows
        for r in test_row_start..decrypted_inbox.len() {
            for c in 0..cols {
                let prev = decrypted_inbox[r - 1][c];
                let expected = (prev + 1) % modulus;
                let got = decrypted_inbox[r][c];

                if got != expected {
                    println!(
                        "increment/circular check failed at row {r}, col {c}: prev={prev}, expected={expected}, got={got}"
                    );
                }
            }
        }
 */
        self.dump(
            "read_inbox",
            format!("decrypted inbox {:?}", decrypted_inbox),
        );

        end_time.as_secs_f64()
    }

    fn dump(&self, fun_name: &str, msg: String) {
        println!(
            "{} | RECEIVER_{}: {} | {}",
            Local::now(),
            self.id,
            fun_name,
            msg
        );
    }
}

// ------------------------------
// Key bundle + cache helpers
// ------------------------------

struct KeyBundle {
    sk: ClientKey,
    pk: CompactPublicKey,
    server_key: ServerKey,
}

fn load_or_create_key_bundle(id: &str, which: usize, param: ShortintParameterSet, cache: &mut CacheTiming) -> KeyBundle {
    let base: PathBuf = ["wallet", &id].iter().collect();
    utility::ensure_dir(&base);

    let sk_path = base.join(format!("sk.{which}.bin"));
    let server_key_path = base.join(format!("server_key.{which}.bin"));
    let pk_path = base.join(format!("pk.{which}.bin"));

    let sk: ClientKey = cache.load(&sk_path, || ClientKey::new(param));
    assert_eq!(sk.parameters(), param, "Cached ClientKey does not match requested parameters");
    let server_key: ServerKey = cache.load(&server_key_path, || ServerKey::new(&sk));
    let pk: CompactPublicKey = cache.load(&pk_path, || CompactPublicKey::new(&sk));

    KeyBundle { sk, pk, server_key }
}
