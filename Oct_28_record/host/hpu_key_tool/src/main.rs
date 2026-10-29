//! hpu_key_tool: convert TFHE-rs keys / LUTs / ciphertexts into the DDR images
//! expected by the hpu_mini core (step2 of the OSig VCK190 bring-up).
//!
//! Mirrors tfhe::integer::hpu::init_device (tfhe 1.8.1) without needing an HpuDevice:
//!   CompressedServerKey (KS32 atomic pattern) -> standard-domain BSK / u32 KSK
//!   -> HpuLweBootstrapKeyOwned / HpuLweKeyswitchKeyOwned (per-PC containers)
//!   -> one .bin per AXI PC, written to DDR verbatim by the board server.
mod hpu_params;

use sha2::{Digest, Sha256};
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::str::FromStr;

use tfhe::core_crypto::hpu::glwe_lookuptable::create_hpu_lookuptable;
use tfhe::core_crypto::prelude::CreateFrom;
use tfhe::shortint::atomic_pattern::compressed::CompressedAtomicPatternServerKey;
use tfhe::shortint::parameters::*;
use tfhe::shortint::server_key::ShortintCompressedBootstrappingKey;
use tfhe_hpu_backend::prelude::*;
use tfhe_hpu_backend::asm::PbsLut;

/// Same parameters as osig_hpu/host/src/crypto_params.rs (checked by audit script).
pub const PARAM_KEY_1: KeySwitch32PBSParameters = KeySwitch32PBSParameters {
    lwe_dimension: LweDimension(879),
    glwe_dimension: GlweDimension(1),
    polynomial_size: PolynomialSize(2048),
    lwe_noise_distribution: DynamicDistribution::new_t_uniform(3),
    glwe_noise_distribution: DynamicDistribution::new_t_uniform(17),
    pbs_base_log: DecompositionBaseLog(23),
    pbs_level: DecompositionLevelCount(1),
    ks_base_log: DecompositionBaseLog(2),
    ks_level: DecompositionLevelCount(8),
    message_modulus: MessageModulus(4),
    carry_modulus: CarryModulus(4),
    max_noise_level: MaxNoiseLevel::new(5),
    log2_p_fail: -128.0,
    post_keyswitch_ciphertext_modulus: CiphertextModulus32::new(1 << 21),
    ciphertext_modulus: CiphertextModulus::new_native(),
    modulus_switch_noise_reduction_params: ModulusSwitchType::CenteredMeanNoiseReduction,
};

/// This RTL snapshot (and its v2.9 mockup) orders the big-LWE dimension in 11-bit
/// bit-reversed order relative to the GLWE polynomial coefficients (tfhe 1.8.1's HPU
/// code targets a newer natural-order RTL). Apply the reversal on KSK rows and on
/// ciphertext masks; BSK and LUT formats are unchanged.
fn rev11(x: usize) -> usize { let mut r = 0; for b in 0..11 { if (x >> b) & 1 == 1 { r |= 1 << (10 - b); } } r }

fn write_with_sha(path: &Path, data: &[u8]) -> (String, usize) {
    let mut f = fs::File::create(path).unwrap();
    f.write_all(data).unwrap();
    let mut h = Sha256::new();
    h.update(data);
    (format!("{:x}", h.finalize()), data.len())
}

fn u64s_to_le_bytes(v: &[u64]) -> Vec<u8> {
    let mut out = Vec::with_capacity(v.len() * 8);
    for x in v {
        out.extend_from_slice(&x.to_le_bytes());
    }
    out
}

fn keygen(out: &Path, zero_noise: bool) {
    let params = hpu_params::hpu_mini_params();
    fs::create_dir_all(out.join("host_private")).unwrap();

    let mut tfhe_params = PARAM_KEY_1;
    if zero_noise {
        println!("ZERO-NOISE keys (debug oracle mode)");
        tfhe_params.lwe_noise_distribution = DynamicDistribution::new_gaussian_from_std_dev(StandardDev(0.0));
        tfhe_params.glwe_noise_distribution = DynamicDistribution::new_gaussian_from_std_dev(StandardDev(0.0));
    }
    println!("Generating shortint ClientKey (KS32, 879/2048)...");
    let cks = tfhe::shortint::ClientKey::new(tfhe_params);
    let csks = tfhe::shortint::CompressedServerKey::new(&cks);

    let ap_key = match &csks.compressed_ap_server_key {
        CompressedAtomicPatternServerKey::KeySwitch32(k) => k,
        _ => panic!("expected KeySwitch32 atomic pattern"),
    };

    // ---- BSK: standard domain -> NTT64 + GF64 shuffle, split per PC ----
    println!("Decompressing + converting BSK...");
    let bsk = match ap_key.bootstrapping_key() {
        ShortintCompressedBootstrappingKey::Classic { bsk, .. } => {
            bsk.clone().decompress_into_lwe_bootstrap_key()
        }
        _ => panic!("expected classic BSK"),
    };
    let hpu_bsk = HpuLweBootstrapKeyOwned::<u64>::create_from(bsk.as_view(), params.clone());
    let bsk_chunks = hpu_bsk.into_container();

    // ---- KSK: u32 -> 21-bit digits packed 3-per-u64, split per PC ----
    println!("Decompressing + converting KSK...");
    let ksk = ap_key
        .key_switching_key()
        .clone()
        .decompress_into_lwe_keyswitch_key();
    // reorder input-dimension blocks: HW row y holds tfhe row rev11(y)
    let base_log = ksk.decomposition_base_log();
    let level = ksk.decomposition_level_count();
    let out_size = ksk.output_lwe_size();
    let ct_mod = ksk.ciphertext_modulus();
    let in_dim = ksk.input_key_lwe_dimension().0;
    assert_eq!(in_dim, 2048);
    let block = level.0 * out_size.0;
    let old = ksk.into_container();
    let mut new = vec![0u32; old.len()];
    for y in 0..in_dim {
        let src = rev11(y);
        new[y*block..(y+1)*block].copy_from_slice(&old[src*block..(src+1)*block]);
    }
    let ksk = tfhe::core_crypto::prelude::LweKeyswitchKeyOwned::<u32>::from_container(new, base_log, level, out_size, ct_mod);
    let hpu_ksk = HpuLweKeyswitchKeyOwned::<u64>::create_from(ksk.as_view(), params.clone());
    let ksk_chunks = hpu_ksk.into_container();

    let mut manifest = serde_json::Map::new();
    manifest.insert("parameter_id".into(), "v1_4_hpu_879_ks32_tuniform_2m128".into());
    manifest.insert("config".into(), "psi16_gf64_n5c5c1_bpbs8_tpbs16_pem1_glwe1_bsk4_ksk4".into());

    let mut files = serde_json::Map::new();
    for (i, c) in bsk_chunks.iter().enumerate() {
        let p = out.join(format!("bsk_pc{i}.bin"));
        let (sha, len) = write_with_sha(&p, &u64s_to_le_bytes(c));
        println!("  bsk_pc{i}.bin  {len} bytes");
        files.insert(format!("bsk_pc{i}.bin"), serde_json::json!({"bytes": len, "sha256": sha}));
    }
    for (i, c) in ksk_chunks.iter().enumerate() {
        let p = out.join(format!("ksk_pc{i}.bin"));
        let (sha, len) = write_with_sha(&p, &u64s_to_le_bytes(c));
        println!("  ksk_pc{i}.bin  {len} bytes");
        files.insert(format!("ksk_pc{i}.bin"), serde_json::json!({"bytes": len, "sha256": sha}));
    }

    // Host-private material for later validation (never goes to the board).
    let ck_bytes = bincode::serialize(&cks).unwrap();
    let (sha, len) = write_with_sha(&out.join("host_private/client_key.bin"), &ck_bytes);
    files.insert("host_private/client_key.bin".into(), serde_json::json!({"bytes": len, "sha256": sha}));
    let sks_bytes = bincode::serialize(&csks).unwrap();
    let (sha, len) = write_with_sha(&out.join("host_private/compressed_server_key.bin"), &sks_bytes);
    files.insert("host_private/compressed_server_key.bin".into(), serde_json::json!({"bytes": len, "sha256": sha}));

    manifest.insert("files".into(), files.into());
    fs::write(out.join("manifest.json"), serde_json::to_string_pretty(&manifest).unwrap()).unwrap();
    println!("KEYGEN_DONE -> {}", out.display());
}

fn lut(out: &Path, names: &[&str]) {
    let params = hpu_params::hpu_mini_params();
    fs::create_dir_all(out).unwrap();
    for name in names {
        let pbs = hpu_asm::Pbs::from_str(&format!("Pbs{name}"))
            .unwrap_or_else(|e| panic!("unknown PBS LUT {name}: {e:?}"));
        let gid = pbs.gid().0;
        let hpu_lut = create_hpu_lookuptable(&params, &pbs);
        let data = u64s_to_le_bytes(hpu_lut.as_ref());
        let p = out.join(format!("lut_gid{gid}_{name}.bin"));
        let (_, len) = write_with_sha(&p, &data);
        println!("  {name}: gid={gid} {len} bytes -> {}", p.display());
    }
    println!("LUT_DONE");
}

fn testvec(keys: &Path, out: &Path) {
    let params = hpu_params::hpu_mini_params();
    fs::create_dir_all(out).unwrap();
    let cks: tfhe::shortint::ClientKey =
        bincode::deserialize(&fs::read(keys.join("host_private/client_key.bin")).unwrap()).unwrap();
    let csks: tfhe::shortint::CompressedServerKey =
        bincode::deserialize(&fs::read(keys.join("host_private/compressed_server_key.bin")).unwrap()).unwrap();
    let sks = csks.decompress();

    let mut expected = Vec::new();
    // MsgOnly (rectification): inputs with non-zero carry, incl. the degenerate 0 case.
    for (i, raw) in [0u64, 1, 2, 3, 5, 7, 9, 11, 13, 15].iter().enumerate() {
        // Build a ciphertext whose (carry|msg) nibble equals `raw`:
        // encrypt msg part then add carry via scalar ops on the CPU key.
        let msg = raw & 3;
        let carry = (raw >> 2) & 3;
        let mut ct = cks.encrypt(msg);
        if carry > 0 {
            let ct_c = cks.encrypt(carry); // value in msg slot
            let mut shifted = sks.unchecked_scalar_mul(&ct_c, 4);
            sks.unchecked_add_assign(&mut shifted, &ct);
            ct = shifted;
        }
        let cpu_out = sks.message_extract(&ct);
        let mut ct_hw = ct.ct.clone();
        {
            let src: Vec<u64> = ct.ct.get_mask().as_ref().to_vec();
            let mut dst = ct_hw.get_mut_mask();
            let dst = dst.as_mut();
            for y in 0..2048 { dst[y] = src[rev11(y)]; }
        }
        let hpu_in = tfhe::core_crypto::hpu::entities::HpuLweCiphertextOwned::<u64>::create_from(
            ct_hw.as_view(),
            params.clone(),
        );
        let in_words: Vec<u64> = hpu_in.into_container().into_iter().flatten().collect();
        let in_bytes = u64s_to_le_bytes(&in_words);
        let p = out.join(format!("msgonly_in_{i}.bin"));
        write_with_sha(&p, &in_bytes);
        expected.push(serde_json::json!({
            "case": format!("msgonly_{i}"),
            "input_file": format!("msgonly_in_{i}.bin"),
            "raw_value": raw,
            "lut": "MsgOnly", "gid": 1,
            "expected_plain": cks.decrypt(&cpu_out) & 3,
        }));
        println!("  msgonly_{i}: raw={raw} expect={}", cks.decrypt(&cpu_out) & 3);
    }
    fs::write(out.join("expected.json"), serde_json::to_string_pretty(&expected).unwrap()).unwrap();
    println!("TESTVEC_DONE -> {}", out.display());
}


/// BwAnd (OSig pertinency AND): the HPU BwAnd LUT (gid 7) reads val = (carry<<2)|msg and
/// returns (carry & msg) & 3, so operand a goes to the carry slot and b to the msg slot:
/// packed = ct_a * 4 + ct_b (linear part on the CPU, as in the HPU firmware's iop_bw).
/// All 16 (a, b) pairs; expected plaintext is a & b.
fn testvec_bwand(keys: &Path, out: &Path) {
    let params = hpu_params::hpu_mini_params();
    fs::create_dir_all(out).unwrap();
    let cks: tfhe::shortint::ClientKey =
        bincode::deserialize(&fs::read(keys.join("host_private/client_key.bin")).unwrap()).unwrap();
    let csks: tfhe::shortint::CompressedServerKey =
        bincode::deserialize(&fs::read(keys.join("host_private/compressed_server_key.bin")).unwrap()).unwrap();
    let sks = csks.decompress();

    let mut expected = Vec::new();
    let mut i = 0;
    for a in 0u64..4 {
        for b in 0u64..4 {
            let ct_a = cks.encrypt(a);
            let ct_b = cks.encrypt(b);
            let mut packed = sks.unchecked_scalar_mul(&ct_a, 4);
            sks.unchecked_add_assign(&mut packed, &ct_b);
            // sanity: the packed nibble decrypts to (a<<2)|b
            let nibble = cks.decrypt_message_and_carry(&packed) & 15;
            assert_eq!(nibble, (a << 2) | b, "packing check failed for a={a} b={b}");

            let mut ct_hw = packed.ct.clone();
            {
                let src: Vec<u64> = packed.ct.get_mask().as_ref().to_vec();
                let mut dst = ct_hw.get_mut_mask();
                let dst = dst.as_mut();
                for y in 0..2048 { dst[y] = src[rev11(y)]; }
            }
            let hpu_in = tfhe::core_crypto::hpu::entities::HpuLweCiphertextOwned::<u64>::create_from(
                ct_hw.as_view(),
                params.clone(),
            );
            let in_words: Vec<u64> = hpu_in.into_container().into_iter().flatten().collect();
            let p = out.join(format!("bwand_in_{i}.bin"));
            write_with_sha(&p, &u64s_to_le_bytes(&in_words));
            expected.push(serde_json::json!({
                "case": format!("bwand_{i}"),
                "input_file": format!("bwand_in_{i}.bin"),
                "a": a, "b": b, "raw_value": (a << 2) | b,
                "lut": "BwAnd", "gid": 7,
                "expected_plain": a & b,
            }));
            println!("  bwand_{i}: a={a} b={b} packed={} expect={}", (a << 2) | b, a & b);
            i += 1;
        }
    }
    fs::write(out.join("expected.json"), serde_json::to_string_pretty(&expected).unwrap()).unwrap();
    println!("TESTVEC_BWAND_DONE -> {}", out.display());
}

/// CPU reference timing with the very same keys/parameters the board uses:
/// MsgOnly = shortint message_extract (KS + PBS), BwAnd = apply_lookup_table on the packed ct.
/// Single ciphertext, single thread (tfhe-rs x86 FFT path). Prints JSON for the comparison doc.
fn bench_cpu(keys: &Path, iters: usize) {
    let cks: tfhe::shortint::ClientKey =
        bincode::deserialize(&fs::read(keys.join("host_private/client_key.bin")).unwrap()).unwrap();
    let csks: tfhe::shortint::CompressedServerKey =
        bincode::deserialize(&fs::read(keys.join("host_private/compressed_server_key.bin")).unwrap()).unwrap();
    let sks = csks.decompress();

    // MsgOnly input: msg 3 with carry 1 (raw nibble 7), same construction as testvec.
    let ct_m = {
        let ct = cks.encrypt(3);
        let ct_c = cks.encrypt(1);
        let mut s = sks.unchecked_scalar_mul(&ct_c, 4);
        sks.unchecked_add_assign(&mut s, &ct);
        s
    };
    // BwAnd input: a=3, b=1 packed as ct_a*4 + ct_b.
    let ct_p = {
        let a = cks.encrypt(3);
        let b = cks.encrypt(1);
        let mut s = sks.unchecked_scalar_mul(&a, 4);
        sks.unchecked_add_assign(&mut s, &b);
        s
    };
    let bwand_lut = sks.generate_lookup_table(|x| ((x >> 2) & (x & 3)) & 3);

    fn stats(mut v: Vec<f64>) -> serde_json::Value {
        v.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let mean = v.iter().sum::<f64>() / v.len() as f64;
        serde_json::json!({"n": v.len(), "min_ms": v[0], "median_ms": v[v.len()/2], "mean_ms": mean, "max_ms": v[v.len()-1]})
    }
    // warm-up
    for _ in 0..3 { let _ = sks.message_extract(&ct_m); let _ = sks.apply_lookup_table(&ct_p, &bwand_lut); }

    let mut t_msg = Vec::with_capacity(iters);
    let mut out_m = None;
    for _ in 0..iters {
        let t = std::time::Instant::now();
        let r = sks.message_extract(&ct_m);
        t_msg.push(t.elapsed().as_secs_f64() * 1e3);
        out_m = Some(r);
    }
    let mut t_and = Vec::with_capacity(iters);
    let mut out_p = None;
    for _ in 0..iters {
        let t = std::time::Instant::now();
        let r = sks.apply_lookup_table(&ct_p, &bwand_lut);
        t_and.push(t.elapsed().as_secs_f64() * 1e3);
        out_p = Some(r);
    }
    assert_eq!(cks.decrypt(&out_m.unwrap()) & 3, 3);
    assert_eq!(cks.decrypt(&out_p.unwrap()) & 3, 3 & 1);
    let threads = std::thread::available_parallelism().map(|n| n.get()).unwrap_or(0);
    let cpu = fs::read_to_string("/proc/cpuinfo").ok()
        .and_then(|s| s.lines().find(|l| l.starts_with("model name")).map(|l| l.split(':').nth(1).unwrap_or("").trim().to_string()))
        .unwrap_or_default();
    let j = serde_json::json!({
        "cpu_model": cpu, "logical_cpus": threads, "single_ciphertext_single_thread": true,
        "tfhe_version": "1.8.1 (shortint KS32, x86 FFT backend)",
        "msgonly_ms": stats(t_msg), "bwand_ms": stats(t_and),
    });
    println!("{}", serde_json::to_string_pretty(&j).unwrap());
    println!("BENCH_CPU_DONE");
}

fn verify(keys: &Path, hexfile: &Path, expected_plain: u64) {
    use tfhe::core_crypto::prelude::*;
    let params = hpu_params::hpu_mini_params();
    let cks: tfhe::shortint::ClientKey =
        bincode::deserialize(&fs::read(keys.join("host_private/client_key.bin")).unwrap()).unwrap();

    // Parse hex dump: one 256-bit AXI word per line, MSB-first hex of little-endian bytes.
    let mut bytes = Vec::new();
    for line in fs::read_to_string(hexfile).unwrap().lines() {
        let line = line.trim();
        if line.is_empty() { continue; }
        let mut w: Vec<u8> = (0..line.len() / 2)
            .map(|i| u8::from_str_radix(&line[2 * i..2 * i + 2], 16).unwrap())
            .collect();
        w.reverse(); // back to little-endian byte order
        bytes.extend_from_slice(&w);
    }
    assert!(bytes.len() >= 2049 * 8, "dump too short: {} bytes", bytes.len());
    let words: Vec<u64> = bytes[..2049 * 8]
        .chunks_exact(8)
        .map(|c| u64::from_le_bytes(c.try_into().unwrap()))
        .collect();

    // Official HPU -> CPU conversion (lsb2msb etc.)
    let hpu_ct = HpuLweCiphertextOwned::<u64>::from_container(vec![words], params);
    let mut cpu_ct = LweCiphertextOwned::<u64>::from(hpu_ct.as_view());
    {
        let src: Vec<u64> = cpu_ct.get_mask().as_ref().to_vec();
        let mut dst = cpu_ct.get_mut_mask();
        let dst = dst.as_mut();
        for y in 0..2048 { dst[rev11(y)] = src[y]; }
    }

    // Decrypt with the big LWE secret key, decode with rounding (delta = 2^59).
    let ap = match &cks.atomic_pattern {
        tfhe::shortint::client_key::atomic_pattern::AtomicPatternClientKey::KeySwitch32(k) => k,
        _ => panic!("expected KS32 client key"),
    };
    let raw = decrypt_lwe_ciphertext(&ap.large_lwe_secret_key(), &cpu_ct).0;
    let decoded = (raw.wrapping_add(1u64 << 58) >> 59) & 31;
    println!("raw=0x{raw:016x} decoded={decoded} expected={expected_plain}");
    if decoded == expected_plain {
        println!("VERIFY_PASS");
    } else {
        println!("VERIFY_FAIL");
        std::process::exit(1);
    }
}


fn ks_ref(keys: &Path, ct_file: &Path) {
    use tfhe::core_crypto::prelude::*;
    let csks: tfhe::shortint::CompressedServerKey =
        bincode::deserialize(&fs::read(keys.join("host_private/compressed_server_key.bin")).unwrap()).unwrap();
    let ap_key = match &csks.compressed_ap_server_key {
        CompressedAtomicPatternServerKey::KeySwitch32(k) => k,
        _ => panic!("expected KeySwitch32"),
    };
    let ksk = ap_key.key_switching_key().clone().decompress_into_lwe_keyswitch_key();

    // input big-LWE ciphertext: 2049 little-endian u64
    let bytes = fs::read(ct_file).unwrap();
    let words: Vec<u64> = bytes[..2049 * 8].chunks_exact(8)
        .map(|c| u64::from_le_bytes(c.try_into().unwrap())).collect();
    let in_ct = LweCiphertextOwned::from_container(words, CiphertextModulus::new_native());

    let mut out_ct = LweCiphertextOwned::<u32>::new(
        0u32,
        LweDimension(879).to_lwe_size(),
        CiphertextModulus::try_new_power_of_2(21).unwrap(),
    );
    keyswitch_lwe_ciphertext_with_scalar_change(&ksk, &in_ct, &mut out_ct);

    // mod-switch each coefficient from 2^21 to 2N = 4096 (floor of top 12 bits)
    for (i, &x) in out_ct.as_ref().iter().enumerate() {
        let floor12 = (x >> 9) & 0xFFF;
        println!("{i} {x:06x} {floor12}");
    }
}


/// Zero-noise BSK oracle: official/own per-PC images -> tfhe unshuffle -> inverse NTT ->
/// check the GGSW relation in Z_2^64 with recovered secrets.
fn bsk_oracle(fmt: &str, files: &[String], secrets: &Path) {
    use tfhe::core_crypto::prelude::*;
    const P: u64 = 0xFFFF_FFFF_0000_0001; // 2^64 - 2^32 + 1
    let params = hpu_params::hpu_mini_params();
    let n = 2048usize;

    let load = |f: &str| -> Vec<u64> {
        if fmt == "bin" {
            fs::read(f).unwrap().chunks_exact(8).map(|c| u64::from_le_bytes(c.try_into().unwrap())).collect()
        } else {
            let mut out = Vec::new();
            for line in fs::read_to_string(f).unwrap().lines() {
                let l = line.trim();
                if l.is_empty() || l.starts_with("//") { continue; }
                let mut w: Vec<u8> = (0..l.len()/2).map(|i| u8::from_str_radix(&l[2*i..2*i+2], 16).unwrap_or(0)).collect();
                w.reverse();
                out.extend(w.chunks_exact(8).map(|c| u64::from_le_bytes(c.try_into().unwrap())));
            }
            out
        }
    };
    let pcs: Vec<Vec<u64>> = files.iter().map(|f| load(f)).collect();
    let hpu_bsk = HpuLweBootstrapKeyOwned::<u64>::from_container(pcs, params.clone());
    let ntt_bsk = NttLweBootstrapKeyOwned::<u64>::from(hpu_bsk.as_view());
    let data = ntt_bsk.into_container();
    let data: &[u64] = data.as_ref();

    let sec: serde_json::Value = serde_json::from_str(&fs::read_to_string(secrets).unwrap()).unwrap();
    let s_small: Vec<u64> = sec["s_small"].as_array().unwrap().iter().map(|v| v.as_u64().unwrap()).collect();
    let s_big: Vec<u64> = sec["s_big"].as_array().unwrap().iter().map(|v| v.as_u64().unwrap()).collect();

    let plan = tfhe_ntt::prime64::Plan::try_new(n, P).expect("ntt plan");
    // calibrate inverse scaling with a round trip
    let mut probe: Vec<u64> = (0..n as u64).map(|i| (i * 7919 + 13) % P).collect();
    let orig = probe.clone();
    plan.fwd(&mut probe);
    plan.inv(&mut probe);
    let scale = {
        // probe[1] = orig[1] * scale mod P
        let inv_orig = modinv(orig[1], P);
        mulmod(probe[1], inv_orig, P)
    };
    let scale_inv = modinv(scale, P);
    println!("inv-NTT scale factor = {scale} (1 means normalized, 2048 means unnormalized)");

    let w41: u64 = 1u64 << 41;
    let ggsw_sz = 2 * 2 * n; // level=1, (k+1) rows, (k+1) polys
    let mut clean_rows = 0; let mut total_rows = 0;
    for i in 0..8usize {
        for g in 0..2usize {
            let base = i * ggsw_sz + g * 2 * n;
            let mut a: Vec<u64> = data[base..base + n].to_vec();
            let mut b: Vec<u64> = data[base + n..base + 2 * n].to_vec();
            plan.inv(&mut a); plan.inv(&mut b);
            // scale back, then undo the signed reduction: values in the upper half of Z_p
            // represent negative 64-bit coefficients (v - p  ==  v + (2^64 - p) mod 2^64)
            // exact inverse of tfhe's modswitch_from_power_of_two_to_ntt_prime (round(v*p/2^64))
            let fix = |v: u64| { let v = mulmod(v, scale_inv, P) as u128; (((v << 64) + (P as u128 >> 1)) / P as u128) as u64 };
            for x in a.iter_mut() { *x = fix(*x); }
            for x in b.iter_mut() { *x = fix(*x); }
            // r = b - a (*) s_big  (negacyclic, mod 2^64)
            let mut conv = vec![0u64; n];
            for (y, &sy) in s_big.iter().enumerate() {
                if sy == 0 { continue; }
                for nn in 0..n {
                    let idx = nn + y;
                    if idx < n { conv[idx] = conv[idx].wrapping_add(a[nn]); }
                    else { conv[idx - n] = conv[idx - n].wrapping_sub(a[nn]); }
                }
            }
            let r: Vec<u64> = (0..n).map(|k| b[k].wrapping_sub(conv[k])).collect();
            total_rows += 1;
            let m = s_small[i].wrapping_mul(w41);
            let small = |x: u64| (x as i64).unsigned_abs() < (1u64 << 20); // tolerate rare modswitch collisions
            let ok = if g == 1 {
                small(r[0].wrapping_sub(m)) && r[1..].iter().all(|&x| small(x))
            } else {
                // row 0: a' = a + m  => r = -m * s_big (as polynomial)
                (0..n).all(|k| small(r[k].wrapping_sub(m.wrapping_mul(s_big[k]).wrapping_neg())))
            };
            if ok { clean_rows += 1; }
            if i < 3 {
                println!("ggsw {i} row {g}: s={} r[0]=0x{:016x} r[1]=0x{:016x} r[2]=0x{:016x} nonzero_tail={} -> {}",
                    s_small[i], r[0], r[1], r[2], r[1..].iter().filter(|&&x| x != 0).count(), if ok {"CLEAN"} else {"unclean"});
            }
        }
    }
    println!("BSK_ORACLE clean rows {clean_rows}/{total_rows}");
}
fn mulmod(a: u64, b: u64, p: u64) -> u64 { ((a as u128 * b as u128) % p as u128) as u64 }
fn modinv(a: u64, p: u64) -> u64 { // p prime
    let mut e = p - 2; let mut base = a % p; let mut acc = 1u64;
    while e > 0 { if e & 1 == 1 { acc = mulmod(acc, base, p); } base = mulmod(base, base, p); e >>= 1; }
    acc
}


/// Permutation search: try candidate stream->frequency mappings on raw per-PC BSK images.
fn bsk_perm_search(fmt: &str, files: &[String], secrets: &Path) {
    const P: u64 = 0xFFFF_FFFF_0000_0001;
    let n = 2048usize;
    let load = |f: &str| -> Vec<u64> {
        if fmt == "bin" {
            fs::read(f).unwrap().chunks_exact(8).map(|c| u64::from_le_bytes(c.try_into().unwrap())).collect()
        } else {
            let mut out = Vec::new();
            for line in fs::read_to_string(f).unwrap().lines() {
                let l = line.trim();
                if l.is_empty() || l.starts_with("//") { continue; }
                let mut w: Vec<u8> = (0..l.len()/2).map(|i| u8::from_str_radix(&l[2*i..2*i+2], 16).unwrap_or(0)).collect();
                w.reverse();
                out.extend(w.chunks_exact(8).map(|c| u64::from_le_bytes(c.try_into().unwrap())));
            }
            out
        }
    };
    let pcs: Vec<Vec<u64>> = files.iter().map(|f| load(f)).collect();
    let sec: serde_json::Value = serde_json::from_str(&fs::read_to_string(secrets).unwrap()).unwrap();
    let s_small: Vec<u64> = sec["s_small"].as_array().unwrap().iter().map(|v| v.as_u64().unwrap()).collect();
    let s_big: Vec<u64> = sec["s_big"].as_array().unwrap().iter().map(|v| v.as_u64().unwrap()).collect();
    let plan = tfhe_ntt::prime64::Plan::try_new(n, P).unwrap();
    let scale_inv = modinv(2048, P);

    fn bsk_order(cut: &[u8]) -> Vec<usize> {
        if cut.len() == 1 { return (0..(1usize << cut[0])).collect(); }
        let left = 1usize << cut[0];
        let sub = bsk_order(&cut[1..]);
        let mut out = Vec::new();
        for j in 0..left { for &idx in &sub { out.push(left * idx + j); } }
        out
    }
    let rev11 = |x: usize| -> usize { let mut r = 0; for b in 0..11 { if (x >> b) & 1 == 1 { r |= 1 << (10 - b); } } r };
    let cuts: Vec<(&str, Vec<u8>)> = vec![("551", vec![5,5,1]), ("155", vec![1,5,5]), ("515", vec![5,1,5])];
    let inters: Vec<(&str, Box<dyn Fn(usize, usize, usize, usize, usize) -> usize>)> = vec![
        ("j_outer,(2t+l)", Box::new(|k, l, j, t, fl| k*2048 + j*1024 + (2*t + l)*8 + fl)),
        ("j_outer,(l*64+t)", Box::new(|k, l, j, t, fl| k*2048 + j*1024 + (l*64 + t)*8 + fl)),
        ("l_outer,(2t+j)", Box::new(|k, l, j, t, fl| k*2048 + l*1024 + (2*t + j)*8 + fl)),
        ("l_outer,(j*64+t)", Box::new(|k, l, j, t, fl| k*2048 + l*1024 + (j*64 + t)*8 + fl)),
    ];
    let w41: u64 = 1u64 << 41;
    let small = |x: u64| (x as i64).unsigned_abs() < (1u64 << 20);
    let mut best: Vec<(usize, String)> = Vec::new();
    for (cname, cut) in &cuts {
        let order = bsk_order(cut);
        let mut inv_order = vec![0usize; n]; for (i, &o) in order.iter().enumerate() { inv_order[o] = i; }
        let perms: Vec<(&str, Box<dyn Fn(usize) -> usize>)> = vec![
            ("identity", Box::new(|c| c)),
            ("bitrev", Box::new(move |c| rev11(c))),
            ("order", Box::new({ let o = order.clone(); move |c| o[c] })),
            ("rev(order)", Box::new({ let o = order.clone(); move |c| rev11(o[c]) })),
            ("inv_order", Box::new({ let o = inv_order.clone(); move |c| o[c] })),
            ("rev(inv_order)", Box::new({ let o = inv_order.clone(); move |c| rev11(o[c]) })),
            ("order(rev)", Box::new({ let o = order.clone(); move |c| o[rev11(c)] })),
            ("inv_order(rev)", Box::new({ let o = inv_order.clone(); move |c| o[rev11(c)] })),
        ];
        for (iname, inter) in &inters {
            for (pname, perm) in &perms {
                for swap_ab in [false, true] {
                    for repr in ["modsw", "unsigned", "signed"] {
                        for norm in ["unnorm", "norm"] {
                            let sc = if norm == "unnorm" { scale_inv } else { 1u64 };
                            let mut clean = 0; let mut total = 0;
                            for i in 0..6usize {
                                for g in 0..2usize {
                                    let mut polys = [vec![0u64; n], vec![0u64; n]];
                                    for j in 0..2usize {
                                        for c in 0..n {
                                            let t = c / 32; let f = c % 32; let q = f / 8; let fl = f % 8;
                                            let e = inter(i, g, j, t, fl);
                                            polys[j][perm(c)] = pcs[q][e];
                                        }
                                        plan.inv(&mut polys[j]);
                                        for x in polys[j].iter_mut() {
                                            let v = mulmod(*x, sc, P);
                                            *x = match repr {
                                                "modsw" => { let v = v as u128; (((v << 64) + (P as u128 >> 1)) / P as u128) as u64 }
                                                "signed" => { if v >= (P + 1) / 2 { v.wrapping_add(0xFFFF_FFFF) } else { v } }
                                                _ => v,
                                            };
                                        }
                                    }
                                    let (a, b) = if swap_ab { (&polys[1], &polys[0]) } else { (&polys[0], &polys[1]) };
                                    let mut conv = vec![0u64; n];
                                    for (y, &sy) in s_big.iter().enumerate() {
                                        if sy == 0 { continue; }
                                        for nn in 0..n { let idx = nn + y;
                                            if idx < n { conv[idx] = conv[idx].wrapping_add(a[nn]); } else { conv[idx-n] = conv[idx-n].wrapping_sub(a[nn]); } }
                                    }
                                    let r: Vec<u64> = (0..n).map(|k| b[k].wrapping_sub(conv[k])).collect();
                                    let m = s_small[i].wrapping_mul(w41);
                                    let ok1 = small(r[0].wrapping_sub(m)) && r[1..].iter().all(|&x| small(x));
                                    let ok0 = (0..n).all(|k| small(r[k].wrapping_sub(m.wrapping_mul(s_big[k]).wrapping_neg())));
                                    total += 1;
                                    if (g == 1 && ok1) || (g == 0 && ok0) { clean += 1; }
                                }
                            }
                            let tag = format!("cut={cname} inter={iname} perm={pname} swap={swap_ab} repr={repr} {norm}");
                            if clean > 0 { println!("{tag}: clean {clean}/{total}"); }
                            best.push((clean, tag));
                        }
                    }
                }
            }
        }
    }
    best.sort_by(|a, b| b.0.cmp(&a.0));
    println!("top: {:?}", &best[..3.min(best.len())]);
}


/// Graded diagnosis with the tfhe-1.8.1 baseline mapping and several s_big orderings.
fn bsk_diagnose(fmt: &str, files: &[String], secrets: &Path) {
    const P: u64 = 0xFFFF_FFFF_0000_0001;
    let n = 2048usize;
    let load = |f: &str| -> Vec<u64> {
        if fmt == "bin" {
            fs::read(f).unwrap().chunks_exact(8).map(|c| u64::from_le_bytes(c.try_into().unwrap())).collect()
        } else {
            let mut out = Vec::new();
            for line in fs::read_to_string(f).unwrap().lines() {
                let l = line.trim();
                if l.is_empty() || l.starts_with("//") { continue; }
                let mut w: Vec<u8> = (0..l.len()/2).map(|i| u8::from_str_radix(&l[2*i..2*i+2], 16).unwrap_or(0)).collect();
                w.reverse();
                out.extend(w.chunks_exact(8).map(|c| u64::from_le_bytes(c.try_into().unwrap())));
            }
            out
        }
    };
    let pcs: Vec<Vec<u64>> = files.iter().map(|f| load(f)).collect();
    let sec: serde_json::Value = serde_json::from_str(&fs::read_to_string(secrets).unwrap()).unwrap();
    let s_small: Vec<u64> = sec["s_small"].as_array().unwrap().iter().map(|v| v.as_u64().unwrap()).collect();
    let s_big0: Vec<u64> = sec["s_big"].as_array().unwrap().iter().map(|v| v.as_u64().unwrap()).collect();
    let plan = tfhe_ntt::prime64::Plan::try_new(n, P).unwrap();
    let scale_inv = modinv(2048, P);
    fn bsk_order(cut: &[u8]) -> Vec<usize> {
        if cut.len() == 1 { return (0..(1usize << cut[0])).collect(); }
        let left = 1usize << cut[0]; let sub = bsk_order(&cut[1..]);
        let mut out = Vec::new(); for j in 0..left { for &idx in &sub { out.push(left * idx + j); } } out
    }
    let rev11 = |x: usize| -> usize { let mut r = 0; for b in 0..11 { if (x >> b) & 1 == 1 { r |= 1 << (10 - b); } } r };
    let order = bsk_order(&[5, 5, 1]);
    // recover coefficient-domain (a,b) for ggsw i, row g under the baseline mapping
    let recover = |i: usize, g: usize| -> (Vec<u64>, Vec<u64>) {
        let mut polys = [vec![0u64; n], vec![0u64; n]];
        for j in 0..2usize {
            for c in 0..n {
                let t = c / 32; let f = c % 32; let q = f / 8; let fl = f % 8;
                let e = i*2048 + j*1024 + (2*t + g)*8 + fl;
                polys[j][rev11(order[c])] = pcs[q][e];
            }
            plan.inv(&mut polys[j]);
            for x in polys[j].iter_mut() {
                let v = mulmod(*x, scale_inv, P) as u128;
                *x = (((v << 64) + (P as u128 >> 1)) / P as u128) as u64;
            }
        }
        (polys[0].clone(), polys[1].clone())
    };
    let small = |x: u64| (x as i64).unsigned_abs() < (1u64 << 20);
    let variants: Vec<(&str, Vec<u64>)> = vec![
        ("identity", s_big0.clone()),
        ("bitrev11", (0..n).map(|y| s_big0[rev11(y)]).collect()),
        ("reverse", (0..n).map(|y| s_big0[n-1-y]).collect()),
        ("neg-reverse", (0..n).map(|y| s_big0[(n - y) % n]).collect()),
    ];
    for (vname, s_big) in &variants {
        let mut tail_clean_total = 0usize; let mut msgs = Vec::new();
        for i in 0..6usize {
            let (a, b) = recover(i, 1);
            let mut conv = vec![0u64; n];
            for (y, &sy) in s_big.iter().enumerate() {
                if sy == 0 { continue; }
                for nn in 0..n { let idx = nn + y;
                    if idx < n { conv[idx] = conv[idx].wrapping_add(a[nn]); } else { conv[idx-n] = conv[idx-n].wrapping_sub(a[nn]); } }
            }
            let r: Vec<u64> = (0..n).map(|k| b[k].wrapping_sub(conv[k])).collect();
            tail_clean_total += r[1..].iter().filter(|&&x| small(x)).count();
            msgs.push(format!("s={} r0=0x{:016x}", s_small[i], r[0]));
        }
        println!("s_big={vname:12} avg tail clean = {:.1}/2047 | {}", tail_clean_total as f64 / 6.0, msgs.join(" ; "));
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(|s| s.as_str()) {
        Some("keygen") => keygen(
            &PathBuf::from(args.get(2).expect("keygen <outdir> [zero]")),
            args.get(3).map(|s| s == "zero").unwrap_or(false),
        ),
        Some("lut") => lut(&PathBuf::from(args.get(2).expect("lut <outdir>")), &["None", "MsgOnly", "BwAnd", "MultCarryMsgLsb"]),
        Some("ks-ref") => ks_ref(
            &PathBuf::from(args.get(2).expect("ks-ref <keydir> <ctfile>")),
            &PathBuf::from(args.get(3).expect("ks-ref <keydir> <ctfile>")),
        ),
        Some("bsk-perm-search") => bsk_perm_search(
            args.get(2).expect("bsk-perm-search <hex|bin> <pc0..pc3> <secrets.json>"),
            &args[3..7],
            &PathBuf::from(args.get(7).expect("secrets json")),
        ),
        Some("bsk-diagnose") => bsk_diagnose(
            args.get(2).expect("bsk-diagnose <hex|bin> <pc0..pc3> <secrets.json>"),
            &args[3..7],
            &PathBuf::from(args.get(7).expect("secrets json")),
        ),
        Some("bsk-oracle") => bsk_oracle(
            args.get(2).expect("bsk-oracle <hex|bin> <pc0> <pc1> <pc2> <pc3> <secrets.json>"),
            &args[3..7],
            &PathBuf::from(args.get(7).expect("secrets json")),
        ),
        Some("verify") => verify(
            &PathBuf::from(args.get(2).expect("verify <keydir> <hexfile> <expected>")),
            &PathBuf::from(args.get(3).expect("verify <keydir> <hexfile> <expected>")),
            args.get(4).expect("verify <keydir> <hexfile> <expected>").parse().unwrap(),
        ),
        Some("testvec") => testvec(
            &PathBuf::from(args.get(2).expect("testvec <keydir> <outdir>")),
            &PathBuf::from(args.get(3).expect("testvec <keydir> <outdir>")),
        ),
        Some("bench-cpu") => bench_cpu(
            &PathBuf::from(args.get(2).expect("bench-cpu <keydir> [iters]")),
            args.get(3).map(|s| s.parse().unwrap()).unwrap_or(50),
        ),
        Some("testvec-bwand") => testvec_bwand(
            &PathBuf::from(args.get(2).expect("testvec-bwand <keydir> <outdir>")),
            &PathBuf::from(args.get(3).expect("testvec-bwand <keydir> <outdir>")),
        ),
        _ => eprintln!("usage: hpu_key_tool keygen <outdir> | lut <outdir> | testvec <keydir> <outdir> | testvec-bwand <keydir> <outdir>"),
    }
}
