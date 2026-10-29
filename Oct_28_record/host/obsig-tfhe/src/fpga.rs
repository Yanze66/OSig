//! FPGA backend for OSig: the hpu_mini (minimal KS+PBS) core on VCK190 behind hpu_server (TCP).
//!
//! * Keys: each recipient's ClientKey -> fresh CompressedServerKey -> HPU BSK/KSK DDR images
//!   (same conversion as step2_pbs_core/tools/hpu_key_tool: this RTL snapshot orders the big-LWE
//!   dimension 11-bit bit-reversed, so KSK rows are permuted and ciphertext masks reversed in/out).
//!   One key slot on the board per recipient.
//! * PBS: `pbs_batch` sends up to 32 big-LWE ciphertexts per request (cmd 9); the core pipelines
//!   them 8 at a time. Several rayon workers (one per inbox) use their own TCP connections, so
//!   network transfer of one batch overlaps PBS execution of another.
//! * LUTs: gid 1 MsgOnly (rectification), gid 7 BwAnd (pertinency), gid 5 MultCarryMsgLsb (filter).
use std::collections::HashMap;
use std::io::{Read, Write};
use std::net::TcpStream;
use std::path::Path;
use std::sync::{Mutex, OnceLock};
use std::time::Instant;

use tfhe::core_crypto::hpu::glwe_lookuptable::create_hpu_lookuptable;
use tfhe::core_crypto::prelude::*;
use tfhe::shortint::atomic_pattern::compressed::CompressedAtomicPatternServerKey;
use tfhe::shortint::ciphertext::Degree;
use tfhe::shortint::server_key::ShortintCompressedBootstrappingKey;
use tfhe::shortint::{Ciphertext, ClientKey, CompressedServerKey};
use tfhe_hpu_backend::asm::PbsLut;
use tfhe_hpu_backend::prelude::*;

pub const GID_MSG_ONLY: u64 = 1;
pub const GID_MULT_LSB: u64 = 5;
pub const GID_BW_AND: u64 = 7;
/// Custom LUTs reproducing tfhe-rs' smart bivariate packing for (pi: degree 1, x: degree 3):
/// tfhe scales the degree-3 operand by (pi.degree+1) = 2 and adds pi unscaled, so the LUT reads
/// v = 2*x + pi, lhs = (v/2) % 4, rhs = v % 2. With pi in the lowest bit, a "garbage" x whose
/// padding bit is set (ciphertext of another recipient) still yields 0 when pi = 0, exactly as on
/// the CPU; the built-in carry*msg packing (4*pi + x) does not have this property.
pub const GID_AND2: u64 = 40;  // lhs & rhs
pub const GID_MUL2: u64 = 41;  // (lhs * rhs) % 4
pub const PACK2_FACTOR: u8 = 2;
pub const BATCH_MAX: usize = 32;
const CT_BYTES: usize = 2049 * 8;
const BSK_PC_BYTES: usize = 14401536;
const KSK_PC_BYTES: usize = 10813440;

fn rev11(x: usize) -> usize { let mut r = 0; for b in 0..11 { if (x >> b) & 1 == 1 { r |= 1 << (10 - b); } } r }
fn fnv(p: &[u8]) -> u64 { let mut h: u64 = 14695981039346656037; for &b in p { h ^= b as u64; h = h.wrapping_mul(1099511628211); } h }
fn u64s_to_le(v: &[u64]) -> Vec<u8> { let mut o = Vec::with_capacity(v.len() * 8); for x in v { o.extend_from_slice(&x.to_le_bytes()); } o }

// ------------------------------------------------------------------------------------------------
// Key / LUT images
// ------------------------------------------------------------------------------------------------
pub struct HpuKeyImages { pub bsk: Vec<Vec<u8>>, pub ksk: Vec<Vec<u8>> }

/// Build the board images for one recipient from its ClientKey. Cached under `dir` (raw .bin files).
pub fn load_or_build_key_images(dir: &Path, cks: &ClientKey) -> (HpuKeyImages, bool) {
    let paths: Vec<_> = (0..4).map(|i| dir.join(format!("hpu_bsk_pc{i}.bin"))).chain((0..4).map(|i| dir.join(format!("hpu_ksk_pc{i}.bin")))).collect();
    if paths.iter().all(|p| p.exists()) {
        let bsk = (0..4).map(|i| std::fs::read(&paths[i]).unwrap()).collect::<Vec<_>>();
        let ksk = (4..8).map(|i| std::fs::read(&paths[i]).unwrap()).collect::<Vec<_>>();
        if bsk.iter().all(|b| b.len() == BSK_PC_BYTES) && ksk.iter().all(|k| k.len() == KSK_PC_BYTES) {
            return (HpuKeyImages { bsk, ksk }, true);
        }
    }
    let img = build_key_images(cks);
    std::fs::create_dir_all(dir).unwrap();
    for i in 0..4 { std::fs::write(&paths[i], &img.bsk[i]).unwrap(); std::fs::write(&paths[4 + i], &img.ksk[i]).unwrap(); }
    (img, false)
}

pub fn build_key_images(cks: &ClientKey) -> HpuKeyImages {
    let params = crate::hpu_params::hpu_mini_params();
    // A fresh server key for the same client key: any valid BSK/KSK of the same secret keys is
    // interchangeable with the CPU ServerKey (the CPU key is Fourier-domain and cannot be converted exactly).
    let csks = CompressedServerKey::new(cks);
    let ap_key = match &csks.compressed_ap_server_key {
        CompressedAtomicPatternServerKey::KeySwitch32(k) => k,
        _ => panic!("expected KeySwitch32 atomic pattern"),
    };
    let bsk = match ap_key.bootstrapping_key() {
        ShortintCompressedBootstrappingKey::Classic { bsk, .. } => bsk.clone().decompress_into_lwe_bootstrap_key(),
        _ => panic!("expected classic BSK"),
    };
    let hpu_bsk = HpuLweBootstrapKeyOwned::<u64>::create_from(bsk.as_view(), params.clone());
    let bsk_chunks: Vec<Vec<u8>> = hpu_bsk.into_container().iter().map(|c| u64s_to_le(c)).collect();

    let ksk = ap_key.key_switching_key().clone().decompress_into_lwe_keyswitch_key();
    let base_log = ksk.decomposition_base_log();
    let level = ksk.decomposition_level_count();
    let out_size = ksk.output_lwe_size();
    let ct_mod = ksk.ciphertext_modulus();
    let in_dim = ksk.input_key_lwe_dimension().0;
    assert_eq!(in_dim, 2048);
    let block = level.0 * out_size.0;
    let old = ksk.into_container();
    let mut new = vec![0u32; old.len()];
    for y in 0..in_dim { let src = rev11(y); new[y * block..(y + 1) * block].copy_from_slice(&old[src * block..(src + 1) * block]); }
    let ksk = LweKeyswitchKeyOwned::<u32>::from_container(new, base_log, level, out_size, ct_mod);
    let hpu_ksk = HpuLweKeyswitchKeyOwned::<u64>::create_from(ksk.as_view(), params.clone());
    let ksk_chunks: Vec<Vec<u8>> = hpu_ksk.into_container().iter().map(|c| u64s_to_le(c)).collect();
    assert_eq!(bsk_chunks.len(), 4); assert_eq!(ksk_chunks.len(), 4);
    for c in &bsk_chunks { assert_eq!(c.len(), BSK_PC_BYTES); }
    for c in &ksk_chunks { assert_eq!(c.len(), KSK_PC_BYTES); }
    HpuKeyImages { bsk: bsk_chunks, ksk: ksk_chunks }
}

pub fn lut_images() -> Vec<(u64, Vec<u8>)> {
    let params = crate::hpu_params::hpu_mini_params();
    let mut v: Vec<(u64, Vec<u8>)> = ["MsgOnly", "MultCarryMsgLsb", "BwAnd"].iter().map(|name| {
        let pbs = tfhe_hpu_backend::asm::Pbs::from_str_name(name);
        let gid = pbs.gid().0 as u64;
        (gid, u64s_to_le(create_hpu_lookuptable(&params, &pbs).as_ref()))
    }).collect();
    let f2 = PACK2_FACTOR as u64;
    v.push((GID_AND2, custom_lut_image(&params, |val| (((val / f2) % 4) & ((val % f2) % 4)) & 3)));
    v.push((GID_MUL2, custom_lut_image(&params, |val| (((val / f2) % 4) * ((val % f2) % 4)) & 3)));
    v
}

/// Same construction as tfhe's `create_hpu_lookuptable` (single-function LUT) for an arbitrary
/// function over the 16 (carry|msg) values: box fill, negate the first half box, rotate, HPU layout.
fn custom_lut_image(params: &HpuParameters, f: impl Fn(u64) -> u64) -> Vec<u8> {
    let p = params.pbs_params;
    let mut acc = GlweCiphertext::new(0u64, GlweDimension(p.glwe_dimension).to_glwe_size(), PolynomialSize(p.polynomial_size),
        CiphertextModulus::try_new_power_of_2(p.ciphertext_width).expect("ciphertext width"));
    let modulus_sup = 1usize << (p.message_width + p.carry_width);
    let box_size = p.polynomial_size / modulus_sup;
    let delta = 1u64 << (u64::BITS - (p.message_width + p.carry_width + 1) as u32);
    {
        let mut view = acc.as_mut_view();
        view.get_mut_mask().as_mut().fill(0);
        let mut body = view.get_mut_body();
        let body = body.as_mut();
        for (msg_value, lut_box) in body.chunks_exact_mut(box_size).enumerate() {
            lut_box.fill(f(msg_value as u64).wrapping_mul(delta));
        }
        let half = box_size / 2;
        for a in body[0..half].iter_mut() { *a = a.wrapping_neg(); }
        body.rotate_left(half);
    }
    u64s_to_le(HpuGlweLookuptableOwned::<u64>::create_from(acc.as_view(), params.clone()).as_ref())
}

trait PbsByName { fn from_str_name(name: &str) -> Self; }
impl PbsByName for tfhe_hpu_backend::asm::Pbs {
    fn from_str_name(name: &str) -> Self {
        use std::str::FromStr;
        tfhe_hpu_backend::asm::Pbs::from_str(&format!("Pbs{name}")).unwrap_or_else(|e| panic!("unknown PBS LUT {name}: {e:?}"))
    }
}

// ------------------------------------------------------------------------------------------------
// Ciphertext <-> board format
// ------------------------------------------------------------------------------------------------
fn ct_to_hw(ct: &Ciphertext, params: &HpuParameters) -> Vec<u8> {
    let mut hw = ct.ct.clone();
    {
        let src: Vec<u64> = ct.ct.get_mask().as_ref().to_vec();
        let mut dst = hw.get_mut_mask();
        let dst = dst.as_mut();
        for y in 0..2048 { dst[y] = src[rev11(y)]; }
    }
    let hpu = HpuLweCiphertextOwned::<u64>::create_from(hw.as_view(), params.clone());
    let words: Vec<u64> = hpu.into_container().into_iter().flatten().collect();
    u64s_to_le(&words)
}

fn hw_to_ct(template: &Ciphertext, bytes: &[u8], params: &HpuParameters, degree: u64) -> Ciphertext {
    let words: Vec<u64> = bytes[..CT_BYTES].chunks_exact(8).map(|c| u64::from_le_bytes(c.try_into().unwrap())).collect();
    let hpu = HpuLweCiphertextOwned::<u64>::from_container(vec![words], params.clone());
    let mut cpu = LweCiphertextOwned::<u64>::from(hpu.as_view());
    {
        let src: Vec<u64> = cpu.get_mask().as_ref().to_vec();
        let mut dst = cpu.get_mut_mask();
        let dst = dst.as_mut();
        for y in 0..2048 { dst[rev11(y)] = src[y]; }
    }
    let mut out = template.clone();
    out.ct = cpu;
    out.degree = Degree::new(degree);
    out.set_noise_level_to_nominal();
    out
}

// ------------------------------------------------------------------------------------------------
// TCP client (connection pool) and batch PBS
// ------------------------------------------------------------------------------------------------
struct Reply { status: u32, hw_cycles: u64, payload: Vec<u8> }

fn request(s: &mut TcpStream, cmd: u32, arg0: u64, arg1: u64, payload: &[u8]) -> Result<Reply, String> {
    let id = 1u32;
    let mut h = Vec::with_capacity(40 + payload.len());
    h.extend_from_slice(b"HPQ1");
    h.extend_from_slice(&id.to_be_bytes()); h.extend_from_slice(&cmd.to_be_bytes());
    h.extend_from_slice(&(payload.len() as u32).to_be_bytes());
    h.extend_from_slice(&arg0.to_be_bytes()); h.extend_from_slice(&arg1.to_be_bytes());
    h.extend_from_slice(&fnv(payload).to_be_bytes());
    h.extend_from_slice(payload);
    s.write_all(&h).map_err(|e| e.to_string())?;
    let mut r = [0u8; 40]; s.read_exact(&mut r).map_err(|e| format!("reply header: {e}"))?;
    if &r[..4] != b"HPR1" { return Err("bad reply magic".into()); }
    let status = u32::from_be_bytes(r[8..12].try_into().unwrap());
    let len = u32::from_be_bytes(r[12..16].try_into().unwrap()) as usize;
    let hw_cycles = u64::from_be_bytes(r[16..24].try_into().unwrap());
    let digest = u64::from_be_bytes(r[32..40].try_into().unwrap());
    let mut payload = vec![0u8; len]; s.read_exact(&mut payload).map_err(|e| format!("reply payload: {e}"))?;
    if fnv(&payload) != digest { return Err("reply digest mismatch".into()); }
    Ok(Reply { status, hw_cycles, payload })
}

#[derive(Default, Clone, Copy, Debug)]
pub struct FpgaStats { pub requests: u64, pub ciphertexts: u64, pub pbs_cycles: u64, pub wire_us: u64 }

pub struct Fpga {
    addr: String,
    pool: Mutex<Vec<TcpStream>>,
    params: HpuParameters,
    slots: Mutex<HashMap<String, u64>>,
    pub stats: Mutex<FpgaStats>,
}

static FPGA: OnceLock<Fpga> = OnceLock::new();

pub fn init(addr: &str) {
    let f = Fpga { addr: addr.to_string(), pool: Mutex::new(Vec::new()), params: crate::hpu_params::hpu_mini_params(),
                   slots: Mutex::new(HashMap::new()), stats: Mutex::new(FpgaStats::default()) };
    f.with_conn(|s| { let r = request(s, 1, 0, 0, &[])?; if r.status != 0 { return Err(format!("ping status {}", r.status)); } Ok(()) }).expect("FPGA ping");
    if FPGA.set(f).is_err() { panic!("fpga::init called twice"); }
}

pub fn get() -> Option<&'static Fpga> { FPGA.get() }

impl Fpga {
    fn with_conn<T>(&self, f: impl FnOnce(&mut TcpStream) -> Result<T, String>) -> Result<T, String> {
        let mut s = match self.pool.lock().unwrap().pop() { Some(s) => s, None => {
            let s = TcpStream::connect(&self.addr).map_err(|e| format!("connect {}: {e}", self.addr))?; s.set_nodelay(true).ok(); s } };
        let r = f(&mut s);
        if r.is_ok() { self.pool.lock().unwrap().push(s); }
        r
    }
    pub fn slot_of(&self, id: &str) -> u64 { *self.slots.lock().unwrap().get(id).unwrap_or_else(|| panic!("no key slot for recipient {id}")) }

    /// Upload one recipient's keys into `slot` and commit. LUTs are uploaded by `upload_luts`.
    pub fn upload_keys(&self, id: &str, slot: u64, img: &HpuKeyImages) {
        self.with_conn(|s| {
            for pc in 0..4u64 {
                let r = request(s, 2, pc, slot, &img.bsk[pc as usize])?; if r.status != 0 { return Err(format!("BSK upload status {} (slot {slot}, pc {pc})", r.status)); }
                let r = request(s, 3, pc, slot, &img.ksk[pc as usize])?; if r.status != 0 { return Err(format!("KSK upload status {} (slot {slot}, pc {pc})", r.status)); }
            }
            let r = request(s, 5, slot, 0, &[])?; if r.status != 0 { return Err(format!("commit status {}", r.status)); }
            Ok(())
        }).expect("key upload");
        self.slots.lock().unwrap().insert(id.to_string(), slot);
    }
    pub fn upload_luts(&self) {
        self.with_conn(|s| { for (gid, data) in lut_images() { let r = request(s, 4, gid, 0, &data)?; if r.status != 0 { return Err(format!("LUT {gid} status {}", r.status)); } } Ok(()) }).expect("LUT upload");
    }

    /// Apply the PBS `gid` to every ciphertext (all under the key of `slot`); outputs carry `out_degree`.
    pub fn pbs_batch(&self, slot: u64, gid: u64, cts: &[&Ciphertext], out_degree: u64) -> Vec<Ciphertext> {
        let mut out = Vec::with_capacity(cts.len());
        for chunk in cts.chunks(BATCH_MAX) {
            let mut payload = Vec::with_capacity(chunk.len() * CT_BYTES);
            for ct in chunk { payload.extend_from_slice(&ct_to_hw(ct, &self.params)); }
            let t = Instant::now();
            let r = self.with_conn(|s| request(s, 9, gid | (slot << 16), chunk.len() as u64, &payload)).expect("FPGA request");
            let wire = t.elapsed().as_micros() as u64;
            if r.status != 0 { panic!("FPGA PBS batch failed: status {} (slot {slot}, gid {gid}, n {})", r.status, chunk.len()); }
            assert_eq!(r.payload.len(), chunk.len() * CT_BYTES);
            { let mut st = self.stats.lock().unwrap(); st.requests += 1; st.ciphertexts += chunk.len() as u64; st.pbs_cycles += r.hw_cycles; st.wire_us += wire; }
            for (i, ct) in chunk.iter().enumerate() { out.push(hw_to_ct(ct, &r.payload[i * CT_BYTES..(i + 1) * CT_BYTES], &self.params, out_degree)); }
        }
        out
    }
}
