//! hpu-client: Ubuntu-side TCP client for hpu_server on VCK190 (std only).
//! Frames: "HPQ1" id cmd len arg0 arg1 digest | reply "HPR1" id status len hw_cycles us digest
use std::fs;
use std::io::{Read, Write};
use std::net::TcpStream;
use std::path::{Path, PathBuf};
use std::time::Instant;

fn fnv(p: &[u8]) -> u64 { let mut h: u64 = 14695981039346656037; for &b in p { h ^= b as u64; h = h.wrapping_mul(1099511628211); } h }

struct Reply { status: u32, hw_cycles: u64, us: u64, payload: Vec<u8> }

fn request(s: &mut TcpStream, id: u32, cmd: u32, arg0: u64, arg1: u64, payload: &[u8]) -> Result<Reply, String> {
    let mut h = Vec::with_capacity(40);
    h.extend_from_slice(b"HPQ1");
    h.extend_from_slice(&id.to_be_bytes()); h.extend_from_slice(&cmd.to_be_bytes());
    h.extend_from_slice(&(payload.len() as u32).to_be_bytes());
    h.extend_from_slice(&arg0.to_be_bytes()); h.extend_from_slice(&arg1.to_be_bytes());
    h.extend_from_slice(&fnv(payload).to_be_bytes());
    s.write_all(&h).map_err(|e| e.to_string())?; s.write_all(payload).map_err(|e| e.to_string())?;
    let mut r = [0u8; 40]; s.read_exact(&mut r).map_err(|e| format!("reply header: {e}"))?;
    if &r[..4] != b"HPR1" { return Err("bad reply magic".into()); }
    let rid = u32::from_be_bytes(r[4..8].try_into().unwrap());
    if rid != id { return Err(format!("reply id {rid} != {id}")); }
    let status = u32::from_be_bytes(r[8..12].try_into().unwrap());
    let len = u32::from_be_bytes(r[12..16].try_into().unwrap()) as usize;
    let hw_cycles = u64::from_be_bytes(r[16..24].try_into().unwrap());
    let us = u64::from_be_bytes(r[24..32].try_into().unwrap());
    let digest = u64::from_be_bytes(r[32..40].try_into().unwrap());
    let mut payload = vec![0u8; len]; s.read_exact(&mut payload).map_err(|e| format!("reply payload: {e}"))?;
    if fnv(&payload) != digest { return Err("reply digest mismatch".into()); }
    Ok(Reply { status, hw_cycles, us, payload })
}

fn connect(addr: &str) -> TcpStream { let s = TcpStream::connect(addr).expect("connect"); s.set_nodelay(true).ok(); s }

fn print_regs(p: &[u8]) {
    for e in p.chunks_exact(8) {
        let r = u32::from_be_bytes(e[..4].try_into().unwrap()); let v = u32::from_be_bytes(e[4..8].try_into().unwrap());
        println!("  reg 0x{r:02x} = 0x{v:08x}");
    }
}

fn write_hex_dump(path: &Path, ct: &[u8]) {
    // 513 lines of 256-bit words (bytes reversed per line), same as the XSim dump; zero-padded
    let mut data = ct.to_vec(); data.resize(513 * 32, 0);
    let mut out = String::new();
    for w in data.chunks_exact(32) { for b in w.iter().rev() { out.push_str(&format!("{b:02x}")); } out.push('\n'); }
    fs::write(path, out).unwrap();
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let usage = "usage: hpu-client <ip:port> ping | reg-write <reg> <value> | load-keys <keys_dir> | pbs <gid> <in.bin> <out.hex> | run-testvec <testvec_dir> <out_dir> [gid] [file_prefix=msgonly] | run-testvec-batch <testvec_dir> <out_dir> <gid> <prefix> <batch_n> [repeat]";
    if a.len() < 3 { eprintln!("{usage}"); std::process::exit(2); }
    let mut s = connect(&a[1]);
    let mut id = 1u32;
    match a[2].as_str() {
        "ping" => { let r = request(&mut s, id, 1, 0, 0, &[]).unwrap(); println!("status={} us={}", r.status, r.us); print_regs(&r.payload); }
        "reg-write" => {
            // reg-write <reg> <value>  (server accepts only 0x38 BPIP_CTRL and 0x3C BPIP_TIMEOUT); prints the regdump
            let parse = |t: &str| -> u64 { if let Some(h) = t.strip_prefix("0x") { u64::from_str_radix(h, 16).unwrap() } else { t.parse().unwrap() } };
            let r = request(&mut s, id, 10, parse(&a[3]), parse(&a[4]), &[]).unwrap();
            println!("status={} us={}", r.status, r.us); print_regs(&r.payload);
            if r.status != 0 { std::process::exit(1); }
        }
        "load-keys" => {
            let dir = PathBuf::from(&a[3]);
            for q in 0..4u64 {
                for (cmd, name) in [(2u32, format!("bsk_pc{q}.bin")), (3u32, format!("ksk_pc{q}.bin"))] {
                    let data = fs::read(dir.join(&name)).expect(&name);
                    let t = Instant::now(); let r = request(&mut s, id, cmd, q, 0, &data).unwrap(); id += 1;
                    println!("{name}: status={} {} bytes in {:.1}s", r.status, data.len(), t.elapsed().as_secs_f64());
                    assert_eq!(r.status, 0);
                }
            }
            for entry in fs::read_dir(dir.join("lut")).expect("lut dir") {
                let p = entry.unwrap().path();
                let fname = p.file_name().unwrap().to_string_lossy().to_string();
                if !fname.starts_with("lut_gid") || !fname.ends_with(".bin") { continue; }
                let gid: u64 = fname["lut_gid".len()..].split('_').next().unwrap().parse().unwrap();
                let data = fs::read(&p).unwrap();
                let r = request(&mut s, id, 4, gid, 0, &data).unwrap(); id += 1;
                println!("{fname}: gid={gid} status={}", r.status); assert_eq!(r.status, 0);
            }
            let r = request(&mut s, id, 5, 0, 0, &[]).unwrap();
            println!("KEYS_COMMIT status={}", r.status); print_regs(&r.payload); assert_eq!(r.status, 0);
            println!("LOAD_KEYS_DONE");
        }
        "pbs" => {
            let gid: u64 = a[3].parse().unwrap();
            let data = fs::read(&a[4]).unwrap(); assert_eq!(data.len(), 2049 * 8);
            let r = request(&mut s, id, 6, gid, 0, &data).unwrap();
            println!("status={} hw_cycles={} us={}", r.status, r.hw_cycles, r.us);
            if r.status != 0 { print_regs(&r.payload); std::process::exit(1); }
            write_hex_dump(Path::new(&a[5]), &r.payload); println!("wrote {}", a[5]);
        }
        "run-testvec" => {
            let gid: u64 = a.get(5).map(|g| g.parse().unwrap()).unwrap_or(1);
            let prefix = a.get(6).map(|s| s.as_str()).unwrap_or("msgonly");
            let out = PathBuf::from(&a[4]); fs::create_dir_all(&out).unwrap();
            let mut n = 0;
            for i in 0..64 {
                let p = PathBuf::from(&a[3]).join(format!("{prefix}_in_{i}.bin"));
                if !p.exists() { continue; }
                let data = fs::read(&p).unwrap();
                let r = request(&mut s, id, 6, gid, 0, &data).unwrap(); id += 1;
                if r.status != 0 { println!("case {i}: status {}", r.status); print_regs(&r.payload); std::process::exit(1); }
                write_hex_dump(&out.join(format!("hw_out_case{i}.hex")), &r.payload);
                println!("case {i}: hw_cycles={} round_trip_us={}", r.hw_cycles, r.us); n += 1;
            }
            println!("RUN_TESTVEC_DONE cases={n}");
        }
        "run-testvec-batch" => {
            // run-testvec-batch <testvec_dir> <out_dir> <gid> <prefix> <batch_n> [repeat]
            let gid: u64 = a[5].parse().unwrap();
            let prefix = a[6].as_str();
            let bn: usize = a[7].parse().unwrap(); assert!((1..=32).contains(&bn), "batch_n must be 1..=32");
            let repeat: usize = a.get(8).map(|s| s.parse().unwrap()).unwrap_or(1);
            let out = PathBuf::from(&a[4]); fs::create_dir_all(&out).unwrap();
            let mut files: Vec<(usize, Vec<u8>)> = Vec::new();
            for i in 0..64 {
                let p = PathBuf::from(&a[3]).join(format!("{prefix}_in_{i}.bin"));
                if p.exists() { files.push((i, fs::read(&p).unwrap())); }
            }
            assert!(!files.is_empty(), "no {prefix}_in_*.bin in {}", a[3]);
            // batches of exactly bn ciphertexts, cycling through the files so every file appears at least once
            let nb = (files.len() + bn - 1) / bn;
            let mut written = std::collections::HashSet::new();
            let mut tot_pbs_cycles = 0u64; let mut tot_us = 0u64; let mut tot_ct = 0usize;
            for rep in 0..repeat {
                for b in 0..nb {
                    let idx: Vec<usize> = (0..bn).map(|k| (b * bn + k) % files.len()).collect();
                    let mut payload = Vec::with_capacity(bn * 2049 * 8);
                    for &k in &idx { payload.extend_from_slice(&files[k].1); }
                    let t = Instant::now();
                    let r = request(&mut s, id, 9, gid, bn as u64, &payload).unwrap(); id += 1;
                    let rt_us = t.elapsed().as_micros() as u64;
                    if r.status != 0 { println!("batch {b}: status {}", r.status); print_regs(&r.payload); std::process::exit(1); }
                    assert_eq!(r.payload.len(), bn * 2049 * 8);
                    for (slot, &k) in idx.iter().enumerate() {
                        let case = files[k].0;
                        if written.insert(case) {
                            write_hex_dump(&out.join(format!("hw_out_case{case}.hex")), &r.payload[slot * 2049 * 8..(slot + 1) * 2049 * 8]);
                        }
                    }
                    println!("rep {rep} batch {b}: n={bn} pbs_cycles={} per_ct_cycles={} server_us={} round_trip_us={rt_us} per_ct_us={:.1}",
                             r.hw_cycles, r.hw_cycles / bn as u64, r.us, rt_us as f64 / bn as f64);
                    tot_pbs_cycles += r.hw_cycles; tot_us += rt_us; tot_ct += bn;
                }
            }
            println!("RUN_TESTVEC_BATCH_DONE cases={} batches={} ciphertexts={tot_ct} mean_per_ct_cycles={} mean_per_ct_us={:.1}",
                     written.len(), nb * repeat, tot_pbs_cycles / tot_ct as u64, tot_us as f64 / tot_ct as f64);
        }
        _ => { eprintln!("{usage}"); std::process::exit(2); }
    }
}
