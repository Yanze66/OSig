use crate::postbox::Inbox;
use crate::receiver::Receiver;
use crate::sender::{MessageRequest, Sender};
use crate::server::{gen_inbox, Server, ShardStat};
use crate::utility::{dump, generate_sorted_strings};
use rayon::prelude::*;
use std::collections::{HashMap, VecDeque};
use std::path::PathBuf;
use std::u64;
use std::time::Instant;
use crate::profiling::{AlgorithmTiming, CacheTiming};
use tfhe::get_pbs_count;

use clap::Parser;

#[derive(Parser, Debug, Clone)]
#[command(author, version, about = "Oblivious Signalling Prototype")]
pub struct Config {
    /// Test-only decryption assertions and vector export (not a performance benchmark)
    #[arg(long)]
    pub verify_io: bool,

    /// Isolated runtime directory; original wallet/testcase are never reused
    #[arg(long, default_value = "runs/v1_4_hpu_879_ks32_tuniform_2m128")]
    pub run_dir: PathBuf,

    /// Print one matching signal/tag/PI diagnostic and exit without benchmarking
    #[arg(long)]
    pub inspect_io: bool,

    /// Max Size of batch (G)
    #[arg(short = 'g', long, default_value_t = 25)]
    pub batch_size: usize,

    /// Shard size (Q)
    #[arg(short = 'q', long, default_value_t = 10)]
    pub shard_size: usize,

    /// Total number of recipients
    #[arg(short = 'r', long, default_value_t = 10)]
    pub num_recipients: usize,

    /// Total number of messages per recipient
    #[arg(short = 'k', long, default_value_t = 4)]
    pub num_messages: usize,

    /// Total inbox capacity
    #[arg(short = 'v', long, default_value_t = 4)]
    pub inbox_cap: usize,

    /// Run rectification / pertinency / filter PBS on the VCK190 hpu_mini core (hpu_server ip:port)
    #[arg(long)]
    pub fpga: Option<String>,
}

mod crypto_params;
mod fpga;
mod hpu_params;
mod validation;
mod inspect_io;
mod profiling;
mod postbox;
mod receiver;
mod sender;
mod server;
mod utility;

fn main() {
    let pipeline_start = Instant::now();
    println!("Server started");
    let config = Config::parse();
    std::fs::create_dir_all(&config.run_dir).unwrap();
    let run_dir = std::fs::canonicalize(&config.run_dir).unwrap();
    std::env::set_current_dir(&run_dir).unwrap();
    let marker = PathBuf::from("PARAMETER_ID.txt");
    if marker.exists() {
        assert_eq!(std::fs::read_to_string(&marker).unwrap(), crypto_params::PARAMETER_ID);
    } else {
        assert!(!PathBuf::from("wallet").exists() && !PathBuf::from("testcase").exists(),
            "Unmarked cache directory: use a fresh --run-dir");
        std::fs::write(&marker, crypto_params::PARAMETER_ID).unwrap();
    }
    std::fs::write("parameters.txt", format!("{:?}\n", utility::PARAM_KEY_1)).unwrap();
    println!("PARAMETERS: {}\nRUN_DIR: {}", crypto_params::PARAMETER_ID, run_dir.display());
    if config.verify_io {
        assert!(!config.inspect_io, "--verify-io and --inspect-io have different scopes");
        validation::initialize();
        println!("VALIDATION MODE: decryption/export overhead included; not a performance benchmark");
    }

    println!(
        "Starting server with G={}, Q={}, R={}, V={}",
        config.batch_size, config.shard_size, config.num_recipients, config.inbox_cap
    );

    let mut debug_receiver_id_map: HashMap<String, &Receiver> = HashMap::new();

    assert!(config.batch_size > 0 && config.shard_size > 0 && config.num_recipients > 0
        && config.num_messages > 0 && config.inbox_cap > 0, "all workload sizes must be positive");
    let (receiver_vec, key_timing, key_cache) =
        generate_receivers(config.num_recipients, utility::RECIPIENT_ID_LENGTH, &config);

    if config.inspect_io {
        inspect_io::run(&receiver_vec[0]);
        return;
    }

    // FPGA backend: one key slot per recipient (BSK/KSK images cached in wallet/<id>/), LUTs once.
    if let Some(addr) = &config.fpga {
        let t = Instant::now();
        fpga::init(addr);
        let dev = fpga::get().unwrap();
        dev.upload_luts();
        let images: Vec<(String, fpga::HpuKeyImages, bool)> = receiver_vec
            .par_iter()
            .map(|r| {
                let (img, cached) = fpga::load_or_build_key_images(&PathBuf::from("wallet").join(&r.id), &r.sk1);
                (r.id.clone(), img, cached)
            })
            .collect();
        let build_s = t.elapsed().as_secs_f64();
        let t_up = Instant::now();
        for (slot, (id, img, cached)) in images.iter().enumerate() {
            dev.upload_keys(id, slot as u64, img);
            println!("FPGA key slot {slot} <- recipient {id} ({})", if *cached { "cached images" } else { "built images" });
        }
        println!("FPGA_KEYS_READY recipients={} image_build_s={build_s:.3} upload_s={:.3} (outside the Alg4 benchmark)",
            receiver_vec.len(), t_up.elapsed().as_secs_f64());
    }

    receiver_vec.iter().for_each(|receiver| {
        debug_receiver_id_map.insert(receiver.id.clone(), receiver);
    });

    let inbox_start = Instant::now();
    let (receiver_inbox_vec, inbox_workers): (Vec<Inbox>, Vec<f64>) = receiver_vec
        .par_iter()
        .map(|receiver| {
            let start = Instant::now();
            let inbox = gen_inbox(&receiver.id, &receiver.pk1, &receiver.pk1_server, config.inbox_cap);
            (inbox, start.elapsed().as_secs_f64())
        })
        .unzip();
    let inbox_timing = AlgorithmTiming {
        wall_seconds: inbox_start.elapsed().as_secs_f64(),
        worker_seconds: inbox_workers.iter().sum(),
    };

    let receiver_inbox_vec_sharded: Vec<Vec<Inbox>> =
        utility::split_random_chunks(receiver_inbox_vec, config.shard_size);

    //FIXME: Thread management can be better
    let shard_stats: Vec<ShardStat> = receiver_inbox_vec_sharded
        .into_par_iter()
        .map(|receiver_inbox_vec| {
            let mut server: Server = Server::new(utility::random_string(3), config.clone());

            receiver_inbox_vec
                .iter()
                .for_each(|inbox: &Inbox| server.set_inbox(&inbox.id, inbox));

            let (message_batch_vec, signal_generation, signal_cache) =
                generate_test_signals(config.num_messages, &receiver_inbox_vec, &config);

            for (i, batch) in message_batch_vec.iter().enumerate() {
                println!("Batch {i}: {} messages", batch.len());
            }

            message_batch_vec.into_iter().for_each(|message_batch| {
                server.send_message(message_batch);
            });

            let mut stat = server.process_all_message2(&debug_receiver_id_map);
            stat.signal_generation = signal_generation;
            stat.signal_cache = signal_cache;
            stat
        })
        .collect();

    let pipeline_wall = pipeline_start.elapsed().as_secs_f64();
    report_algorithm_profile(&shard_stats, &key_timing, &key_cache, &inbox_timing,
        config.num_recipients, pipeline_wall);
    report_processing_profile(&shard_stats);

    let pbs_count = get_pbs_count();
    println!("PBS COUNT {pbs_count}");
    if let Some(dev) = fpga::get() {
        let st = *dev.stats.lock().unwrap();
        println!("FPGA_STATS requests={} ciphertexts={} pbs_cycles={} mean_pbs_cycles_per_ct={} wire_us={} mean_wire_us_per_ct={:.1}",
            st.requests, st.ciphertexts, st.pbs_cycles, if st.ciphertexts > 0 { st.pbs_cycles / st.ciphertexts } else { 0 },
            st.wire_us, if st.ciphertexts > 0 { st.wire_us as f64 / st.ciphertexts as f64 } else { 0.0 });
    }

    generate_object_size_measurement_test(&debug_receiver_id_map);
    if config.verify_io {
        validation::finish(&config);
    }


}

pub fn generate_object_size_measurement_test(debug_receiver_id_map: &HashMap<String, &Receiver>) {
    let msg_vec: Vec<u64> = (0..utility::SLOT_SIZE_CIPHERTEXT)
        .map(|x| ((x) % utility::MESSAGE_SPACE_MOD) as u64)
        .collect();
    let tag_vec = &vec![utility::TAG_VALUE; utility::L / utility::TAG_PLAIN_TEXT_SPACE];

    let mut test_vec = Vec::new();
    test_vec.extend_from_slice(&msg_vec);
    test_vec.extend_from_slice(tag_vec);

    let (id, receiver) = debug_receiver_id_map.iter().next().unwrap().clone();

    let cipher = receiver.pk1.encrypt_slice(&test_vec);

    println!("Object Size Report");
    utility::object_serialization_size_measure("receiver pk", &receiver.pk1);
    utility::object_serialization_size_measure("receiver server_key", &receiver.pk1_server);
    utility::object_serialization_size_measure("receiver sk", &receiver.sk1);
    utility::object_serialization_size_measure("sender ciphertext", &cipher);
}

pub fn generate_test_signals(
    num_messages: usize,
    receiver_inbox_vec: &Vec<Inbox>,
    config: &Config,
) -> (Vec<Vec<MessageRequest>>, AlgorithmTiming, CacheTiming) {
    let wall_start = Instant::now();
    utility::dump(
        "generate_message_request_batches",
        format!(
            "Generating {} messages for {} recipients",
            num_messages, config.num_recipients
        ),
    );

    let generated: Vec<(VecDeque<MessageRequest>, f64, CacheTiming)> = receiver_inbox_vec
        .par_iter()
        .enumerate()
        .map(|(_index, inbox)| {
            let worker_start = Instant::now();
            let mut cache = CacheTiming::default();
            // testcase/{id}/messages
            let base: PathBuf = PathBuf::from("testcase").join(&inbox.id).join("messages");
            utility::ensure_dir(&base);

            let pk_hash = utility::hash_of(&inbox.public_key);

            let message_req_vec: VecDeque<MessageRequest> = (0..num_messages)
                .collect::<Vec<usize>>()
                .iter()
                .map(|i| {
                    let msg_vec: Vec<u64> = (0..utility::SLOT_SIZE_CIPHERTEXT)
                        .map(|x| ((x + i) % utility::MESSAGE_SPACE_MOD) as u64)
                        .collect();

                    let msg_path = base.join(format!("msg.{:?}.{pk_hash}.bin", msg_vec));

                    // load_or_create must RETURN MessageRequest
                    let msg_req: MessageRequest = cache.load(&msg_path, || {
                        Sender::generate_signal(&msg_vec, &&inbox.public_key)
                    });

                    if config.verify_io {
                        validation::register_message(&msg_req, &inbox.id, &msg_vec);
                    }
                    msg_req
                })
                .collect();

            (message_req_vec, worker_start.elapsed().as_secs_f64(), cache)
        })
        .collect();
    let mut worker_seconds = 0.0;
    let mut cache = CacheTiming::default();
    let mut message_req_test_set_per_receiver: Vec<_> = generated.into_iter()
        .map(|(messages, seconds, worker_cache)| {
            worker_seconds += seconds;
            cache.merge(&worker_cache);
            messages
        }).collect();

    let mut testcases: Vec<Vec<MessageRequest>> = Vec::new();
    loop {
        let mut batch: Vec<MessageRequest> = Vec::with_capacity(config.batch_size);

        // One "round": try to take at most one message from each recipient
        for q in message_req_test_set_per_receiver.iter_mut() {
            if batch.len() == config.batch_size {
                break;
            }
            if let Some(msg) = q.pop_front() {
                batch.push(msg);
            }
        }

        // If we couldn't collect any messages, we are done
        if batch.is_empty() {
            break;
        }

        testcases.push(batch);
    }
    (testcases, AlgorithmTiming { wall_seconds: wall_start.elapsed().as_secs_f64(), worker_seconds }, cache)
}

pub fn generate_receivers(num_recipients: usize, recipient_id_length: usize, config: &Config) -> (Vec<Receiver>, AlgorithmTiming, CacheTiming) {
    let wall_start = Instant::now();
    dump(
        "generate_receivers",
        format!("Generating {} receivers", num_recipients),
    );

    let recipient_ids = generate_sorted_strings(recipient_id_length, num_recipients);

    let generated: Vec<_> = recipient_ids
        .par_iter()
        .map(|recipient_id| {
            dump(
                "generate_receivers",
                format!("generating recipient {}", recipient_id),
            );
            let start = Instant::now();
            let (receiver, cache) = Receiver::new(recipient_id.to_string(), config.num_messages);
            let seconds = start.elapsed().as_secs_f64();
            dump(
                "generate_receivers",
                format!("recipient {} generated", recipient_id),
            );

            (receiver, seconds, cache)
        })
        .collect();

    dump(
        "generate_receivers",
        "Recipient Wallets have been created.".to_string(),
    );

    let mut worker_seconds = 0.0;
    let mut cache = CacheTiming::default();
    let receivers = generated.into_iter().map(|(receiver, seconds, worker_cache)| {
        worker_seconds += seconds;
        cache.merge(&worker_cache);
        receiver
    }).collect();
    (receivers, AlgorithmTiming { wall_seconds: wall_start.elapsed().as_secs_f64(), worker_seconds }, cache)
}

/// Printed after workers finish, so reporting does not pollute measured scopes.
fn report_processing_profile(stats: &[ShardStat]) {
    println!("\nOSig processing profile (seconds; summed worker elapsed time, NOT wall time)");
    println!("PROFILE_CSV,shard,stage,worker_seconds,stage_percent,ms_per_message_recipient,message_recipient_pairs,batch_recipient_pairs");
    for shard in stats {
        let stages = [
            ("rectification", shard.profile.rectification.as_secs_f64()),
            ("pertinency_check", shard.profile.pertinency_check.as_secs_f64()),
            ("filter_accumulate", shard.profile.filter_accumulate.as_secs_f64()),
            ("inbox_update", shard.profile.inbox_update.as_secs_f64()),
        ];
        let total: f64 = stages.iter().map(|(_, seconds)| seconds).sum();
        let pairs = shard.total_messages * shard.recipient_count;
        let batch_pairs = shard.total_processed_batch * shard.recipient_count;
        println!("PROFILE_CONTEXT,shard={},server_wall_seconds={:.6},expansion_wall_seconds={:.6},rayon_threads={}",
            shard.id, shard.total_process_duration,
            shard.per_message_expansion_time * shard.total_messages as f64,
            rayon::current_num_threads());
        for (name, seconds) in stages {
            let percent = if total > 0.0 { 100.0 * seconds / total } else { 0.0 };
            let per_pair = if pairs > 0 { 1000.0 * seconds / pairs as f64 } else { 0.0 };
            println!("PROFILE_CSV,{},{},{:.9},{:.3},{:.6},{},{}",
                shard.id, name, seconds, percent, per_pair, pairs, batch_pairs);
        }
    }
}

fn report_algorithm_profile(
    shards: &[ShardStat],
    keys: &AlgorithmTiming,
    key_cache: &CacheTiming,
    inboxes: &AlgorithmTiming,
    recipients: usize,
    pipeline_wall: f64,
) {
    let mut csv_rows = Vec::new();
    let mut row = |scope: &str, name: &str, wall: Option<f64>, worker: f64, count: usize| {
        csv_rows.push(profiling::row(scope, name, wall, worker, count));
    };
    println!("\n================ OSig Algorithm 1-5 profile ================");
    println!("All times in seconds. Recipients = {recipients}; Rayon threads = {}", rayon::current_num_threads());
    println!("Workload pipeline wall time: {pipeline_wall:.6} s (excludes compilation, final reports and object-size benchmark)");
    println!("wall_s = elapsed real time; worker_s = sum of timed recipient tasks (includes waits, NOT CPU time)");
    println!("worker_s/recipient = worker_s / recipient count, averaged over the ENTIRE workload, NOT per message");
    println!("Alg1/2 scope is all recipients. Alg3/4/5 scope is each shard; shards may overlap, so do not sum wall times across shards.");
    println!("\n{:<32} {:>14} {:>16} {:>20}", "Algorithm / step", "wall_s", "worker_s", "worker_s/recipient");
    row("all", "Alg1 KeyGen/load", Some(keys.wall_seconds), keys.worker_seconds, recipients);
    row("all", "Alg2 InboxGen", Some(inboxes.wall_seconds), inboxes.worker_seconds, recipients);
    println!("Alg1 cache: loaded={} built={} key objects; actual build worker_s={:.6}; build worker_s/recipient={:.6}",
        key_cache.loaded, key_cache.built, key_cache.build_seconds, key_cache.build_seconds / recipients as f64);
    println!("Alg1 uses fixed ParamsGen constants; no runtime parameter search. Alg2 includes key clones, cached trivial ciphertexts and slot allocation.");
    for shard in shards {
        let q = shard.recipient_count;
        let stages = [
            ("Alg4.1 Rectification", shard.profile.rectification.as_secs_f64()),
            ("Alg4.2 Pertinency check", shard.profile.pertinency_check.as_secs_f64()),
            ("Alg4.3 Filter and accumulate", shard.profile.filter_accumulate.as_secs_f64()),
            ("Alg4.4 Inbox update", shard.profile.inbox_update.as_secs_f64()),
        ];
        let stage_sum: f64 = stages.iter().map(|(_, seconds)| seconds).sum();
        println!("\nShard {}: {} recipients, {} messages, {} batches", shard.id, q, shard.total_messages, shard.total_processed_batch);
        println!("SERVER PROCESSING (Alg4) actual wall time: {:.6} s", shard.total_process_duration);
        println!("{:<32} {:>14} {:>16} {:>20}", "Algorithm / step", "wall_s", "worker_s", "worker_s/recipient");
        row(&shard.id, "Alg3 SignalGen/load", Some(shard.signal_generation.wall_seconds), shard.signal_generation.worker_seconds, q);
        row(&shard.id, "Alg4 Server processing", Some(shard.total_process_duration), shard.processing_worker_seconds, q);
        for (name, seconds) in stages {
            row(&shard.id, name, None, seconds, q);
        }
        row(&shard.id, "Alg4 four-step subtotal", None, stage_sum, q);
        row(&shard.id, "Alg4 other recipient work", None, (shard.processing_worker_seconds - stage_sum).max(0.0), q);
        row(&shard.id, "Alg5 ReadInbox", Some(shard.decryption.wall_seconds), shard.decryption.worker_seconds, q);
        println!("Alg3 cache: loaded={} built={} messages; actual encryption worker_s={:.6}; encryption worker_s/recipient={:.6}",
            shard.signal_cache.loaded, shard.signal_cache.built, shard.signal_cache.build_seconds,
            shard.signal_cache.build_seconds / q as f64);
        println!("Alg4 expansion wall_s={:.6} (included in server wall, outside recipient worker timers)",
            shard.per_message_expansion_time * shard.total_messages as f64);
    }
    println!("N/A: step wall times are not measured separately because workers interleave steps concurrently.");
    println!("Alg4 worker total includes per-recipient inbox/batch clones and steps; excludes expansion and outer collection/writeback.");
    println!("Alg5 worker time measures decryption; its wall time also includes scheduling and debug output.");
    println!("============================================================\n");
    println!("ALGORITHM_CSV,scope,algorithm,wall_seconds,worker_seconds,worker_seconds_per_recipient,recipients");
    for line in csv_rows { println!("{line}"); }

}
