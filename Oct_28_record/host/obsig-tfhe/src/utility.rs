use chrono::Local;
use std::collections::HashMap;

use bincode;
use hex::ToHex;
use rand::{rng, RngExt};
use rand::seq::SliceRandom;
use serde::{de::DeserializeOwned, Serialize};
use sha2::{Digest, Sha256};
use std::fs;
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, OnceLock};
use std::time::Duration;
use rand::distr::Alphanumeric;
use tfhe::shortint::parameters::*;
use tfhe::shortint::ClassicPBSParameters;
use crate::server::{BatchStat, ShardStat};
/*
False Positive Rate (ep): 2^-32
Tag size (l): 32
 */

pub(crate) use crate::crypto_params::PARAM_KEY_1;
pub(crate) const L: usize = 32; // Required Tag Size
pub(crate) const SLOT_SIZE_CIPHERTEXT: usize = 2;

pub(crate) const TAG_PLAIN_TEXT_SPACE: usize = 2;
pub(crate) const MESSAGE_SPACE_MOD: usize = 4;
pub(crate) const RECIPIENT_ID_LENGTH: usize = 4;
pub(crate) const TAG_VALUE: u64 = 1u64;

pub fn split_random_chunks<T: Clone>(mut v: Vec<T>, y: usize) -> Vec<Vec<T>> {
    assert!(y > 0, "y must be > 0");

    v.shuffle(&mut rng());

    v.chunks(y).map(|c| c.to_vec()).collect()
}
pub(crate) fn ensure_dir(path: &Path) {
    if let Err(e) = fs::create_dir_all(path) {
        eprintln!("cache: create_dir_all({:?}) failed: {e}", path);
    }
}

fn write_bin<T: Serialize>(path: &Path, value: &T) {
    let bytes = match bincode::serialize(value) {
        Ok(b) => b,
        Err(e) => {
            eprintln!("cache: serialize({:?}) failed: {e}", path);
            return;
        }
    };

    if let Some(parent) = path.parent() {
        ensure_dir(parent);
    }

    // Write to a temporary file next to the destination (same filesystem => atomic rename).
    let tmp: PathBuf = path.with_extension("tmp");

    // Create/truncate tmp, write fully, flush, then rename.
    match fs::File::create(&tmp).and_then(|mut f| {
        f.write_all(&bytes)?;
        f.sync_all()?; // stronger than flush; ok to remove if you want speed over durability
        Ok(())
    }) {
        Ok(()) => {
            if let Err(e) = fs::rename(&tmp, path) {
                eprintln!("cache: rename({:?} -> {:?}) failed: {e}", tmp, path);
                let _ = fs::remove_file(&tmp);
            }
        }
        Err(e) => {
            eprintln!("cache: write({:?}) failed: {e}", tmp);
            let _ = fs::remove_file(&tmp);
        }
    }
}

fn read_bin<T: DeserializeOwned>(path: &Path) -> Option<T> {
    let buf = fs::read(path).ok()?;
    bincode::deserialize(&buf).ok()
}

/// Hash a serializable object (e.g., CompressedPublicKey) to a short hex string.
pub(crate) fn hash_of<T: Serialize>(obj: &T) -> String {
    let bytes = bincode::serialize(obj).unwrap_or_default();
    let mut hasher = Sha256::new();
    hasher.update(&bytes);
    let digest = hasher.finalize();
    let mut s = String::new();
    s.push_str(&digest.encode_hex::<String>()[..16]); // first 8 bytes as hex
    s
}

static PATH_LOCKS: OnceLock<Mutex<HashMap<PathBuf, Arc<Mutex<()>>>>> = OnceLock::new();

// This is the critical one: TFHE shortint engine is effectively single-writer.
static TFHE_BUILD_LOCK: OnceLock<Mutex<()>> = OnceLock::new();

fn lock_for(path: &Path) -> Arc<Mutex<()>> {
    let map = PATH_LOCKS.get_or_init(|| Mutex::new(HashMap::new()));
    let mut m = map.lock().unwrap();
    m.entry(path.to_path_buf())
        .or_insert_with(|| Arc::new(Mutex::new(())))
        .clone()
}

pub(crate) fn load_or_create<T, F>(path: &Path, build: F) -> T
where
    T: Serialize + DeserializeOwned + Clone,
    F: FnOnce() -> T,
{
    // Fast path: already on disk
    if let Some(val) = read_bin::<T>(path) {
        return val;
    }

    // Prevent multiple threads building the same file simultaneously
    let path_lock = lock_for(path);
    let _path_guard = path_lock.lock().unwrap();

    // Re-check after per-path lock
    if let Some(val) = read_bin::<T>(path) {
        return val;
    }

    // Prevent TFHE engine mutable borrow conflicts across *all* builds
    let tfhe_lock = TFHE_BUILD_LOCK.get_or_init(|| Mutex::new(()));
    let _tfhe_guard = tfhe_lock.lock().unwrap();

    // Re-check again (another thread could have built it while we waited on TFHE lock)
    if let Some(val) = read_bin::<T>(path) {
        return val;
    }

    let val = build();
    write_bin(path, &val);
    val
}

pub(crate) fn dump(fun_name: &str, msg: String) {
    println!("{} | {} | {}", Local::now(), fun_name, msg);
}
pub fn generate_sorted_strings(length: usize, count: usize) -> Vec<String> {
    // If the count is 0, return an empty vector immediately.
    if count == 0 {
        return Vec::new();
    }

    // Handle the edge case of length 0.
    // The only string of length 0 is the empty string.
    if length == 0 {
        return vec![String::new()];
    }

    // We'll operate on a byte vector for efficiency.
    // Start with the first string: "aaa..."
    let mut current_bytes = vec![b'a'; length];
    let mut result = Vec::with_capacity(count);

    for _ in 0..count {
        // Convert the current byte vector to a String and add it to the result.
        // This is safe (and fast) because we guarantee our bytes are ASCII.
        let s = String::from_utf8(current_bytes.clone())
            .expect("Internal error: generated non-UTF8 bytes.");
        result.push(s);

        // Now, increment the byte vector to get the next string.
        // We start from the rightmost character and move left.
        let mut carry = true;
        for pos in (0..length).rev() {
            if !carry {
                break; // No carry, so we're done incrementing.
            }

            let b = current_bytes[pos];
            if b < b'z' {
                // Simple case: 'a' -> 'b', 'b' -> 'c', etc.
                current_bytes[pos] += 1;
                carry = false; // No carry needed.
            } else {
                // 'z' -> 'a'
                current_bytes[pos] = b'a';
                // We must 'carry' to the next position (to the left).
                carry = true;
            }
        }

        // If we still have a 'carry' after checking all positions,
        // it means we wrapped from "zzz..." back to "aaa...".
        // We have generated all possible strings.
        if carry {
            break;
        }
    }

    result
}

pub fn object_serialization_size_measure<T: Serialize>(name: &str, var: &T) {
    let mut serialized_data = Vec::new();
    bincode::serialize_into(&mut serialized_data, &var).expect("Could not serialize object.");

    println!(
        "Variable '{}' total usage: {} bytes",
        name,
        serialized_data.len()
    );
}

pub fn random_string(len: usize) -> String {
    rand::rng()
        .sample_iter(&Alphanumeric)
        .take(len)
        .map(char::from)
        .collect()
}

pub fn stats(durations: &[Duration], title: String) {
    if durations.is_empty() {
        println!("No durations available");
        return;
    }

    // Convert to float values (seconds)
    let mut values: Vec<f64> = durations.iter().map(|d| d.as_secs_f64()).collect();

    // SORT
    values.sort_by(|a, b| a.partial_cmp(b).unwrap());

    let n = values.len();

    // MIN / MAX
    let min = values[0];
    let max = values[n - 1];

    // MEAN
    let mean = values.iter().sum::<f64>() / n as f64;

    // MEDIAN
    let median = if n % 2 == 0 {
        (values[n / 2 - 1] + values[n / 2]) / 2.0
    } else {
        values[n / 2]
    };

    // STANDARD DEVIATION
    let var = values.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / n as f64;
    let stddev = var.sqrt();

    // Useful percentiles
    let p90 = values[(0.90 * (n as f64 - 1.0)) as usize];
    let p95 = values[(0.95 * (n as f64 - 1.0)) as usize];
    let p99 = values[(0.99 * (n as f64 - 1.0)) as usize];

    println!("{}", {title});
    println!("Count:     {}", n);
    println!("Min:       {:.3}", min);
    println!("Max:       {:.3}", max);
    println!("Mean:      {:.3}", mean);
    println!("Median:    {:.3}", median);
    println!("Std-Dev:   {:.3}", stddev);
    println!("P90:       {:.3}", p90);
    println!("P95:       {:.3}", p95);
    println!("P99:       {:.3}", p99);
    println!("===================================================");
}

pub fn calculate_global_means(stats: &[BatchStat]) -> (f64, f64) {
    if stats.is_empty() {
        return (0.0, 0.0);
    }

    let mut total_filter_sum = 0.0;
    let mut total_cmux_sum = 0.0;
    let mut total_messages = 0.0;

    for batch in stats {
        total_filter_sum += batch.filter_time * batch.batch_size;
        total_cmux_sum += batch.cmux_time * batch.batch_size;
        total_messages += batch.batch_size;
    }

    if total_messages == 0.0 {
        return (0.0, 0.0);
    }

    (
        total_filter_sum / total_messages,
        total_cmux_sum / total_messages
    )
}

pub fn report_full_metrics(shard_stats: &[ShardStat], pbs_count: &u64 ) {
    if shard_stats.is_empty() {
        println!("No shard data available.");
        return;
    }

    let mut total_messages = 0;
    let mut total_recipients = 0;
    let mut total_duration_sum = 0.0;
    let mut max_duration = 0.0;

    let mut weighted_filter = 0.0;
    let mut weighted_cmux = 0.0;
    let mut weighted_expansion = 0.0;
    let mut weighted_decryption = 0.0;

    for shard in shard_stats {
        let msg_count = shard.total_messages as f64;
        let recp_count = shard.recipient_count as f64;

        total_messages += shard.total_messages;
        total_recipients += shard.recipient_count;
        total_duration_sum += shard.total_process_duration;

        if shard.total_process_duration > max_duration {
            max_duration = shard.total_process_duration;
        }

        weighted_filter += shard.per_message_filter_time * msg_count;
        weighted_cmux += shard.per_message_cmux_time * msg_count;
        weighted_expansion += shard.per_message_expansion_time * msg_count;
        weighted_decryption += shard.per_inbox_decryption_time * recp_count;
    }

    let f_total_msg = total_messages as f64;
    let f_total_recp = total_recipients as f64;
    let num_shards = shard_stats.len() as f64;

    let throughput_msg = f_total_msg / max_duration;
    let throughput_recp = f_total_recp / max_duration;
    let parallel_efficiency = total_duration_sum / (max_duration * num_shards);

    let mean_filter = weighted_filter / f_total_msg;
    let mean_cmux = weighted_cmux / f_total_msg;
    let mean_expansion = weighted_expansion / f_total_msg;
    let mean_decryption = if total_recipients > 0 { weighted_decryption / f_total_recp } else { 0.0 };
    let mean_latency_total = mean_filter + mean_cmux + mean_expansion;

    println!("==========================================");
    println!("       GLOBAL PARALLEL SHARD REPORT       ");
    println!("==========================================");
    println!("Shards:             {}", num_shards);
    println!("Total Messages:     {}", total_messages);
    println!("Total Recipients:   {}", total_recipients);
    println!("Wall-clock Time:    {:.4}s", max_duration);
    println!("Parallel Efficiency: {:.2}%", parallel_efficiency * 100.0);
    println!("------------------------------------------");
    println!("THROUGHPUT");
    println!("  Msg/sec:          {:.2}", throughput_msg);
    println!("  Recipients/sec:   {:.2}", throughput_recp);
    println!("------------------------------------------");
    println!("LATENCY (Weighted Mean)");
    println!("  Expansion:        {:.6}s /msg", mean_expansion);
    println!("  Filter:           {:.6}s /msg", mean_filter);
    println!("  CMUX:             {:.6}s /msg", mean_cmux);
    println!("  Decryption:       {:.6}s /recipient", mean_decryption);
    println!("  TOTAL (Processing): {:.6}s /msg", mean_latency_total);
    println!("==========================================");

    // CSV Block for easy copy-paste
    println!("\nCSV Export:");
    println!("shards,total_msg,total_recp,wall_time,efficiency,tp_msg,tp_recp,m_exp,m_filt,m_cmux,m_decr,m_total,pbs_count");
    println!(
        "{},{},{},{:.4},{:.4},{:.2},{:.2},{:.6},{:.6},{:.6},{:.6},{:.6},{}",
        num_shards, total_messages, total_recipients, max_duration, parallel_efficiency,
        throughput_msg, throughput_recp, mean_expansion, mean_filter, mean_cmux, mean_decryption, mean_latency_total, pbs_count
    );
}

pub fn get_mean(data: &[f64]) -> f64 {
    if data.is_empty() {
        return 0.0;
    }

    let sum: f64 = data.iter().sum();
    sum / data.len() as f64
}
