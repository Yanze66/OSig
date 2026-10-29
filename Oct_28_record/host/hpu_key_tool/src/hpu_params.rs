//! HpuParameters describing the hpu_mini core (step2):
//! PSI16 GF64 (radix cut n5c5c1), msg2_carry2_pfail128_132b_tuniform_144a47,
//! pem1_glwe1_bsk4_ksk4, PEP_BATCH_bpbs8_tpbs16, REGF reg64_coef32_seq4, AXI 256-bit.
//! Built via serde because HpuNttPrime is not re-exported by tfhe-hpu-backend 0.7.0.
use tfhe_hpu_backend::prelude::*;

const HPU_MINI_TOML: &str = r#"
[pbs_params]
lwe_dimension = 879
glwe_dimension = 1
polynomial_size = 2048
lwe_noise_distribution = { TUniformBound = 3 }
glwe_noise_distribution = { TUniformBound = 17 }
pbs_base_log = 23
pbs_level = 1
ks_base_log = 2
ks_level = 8
message_width = 2
carry_width = 2
ciphertext_width = 64
log2_p_fail = -128.0
modulus_switch_type = "CenteredMeanNoiseReduction"

[ntt_params]
core_arch = { GF64 = [5, 5, 1] }
batch_pbs_nb = 8
total_pbs_nb = 16
ct_width = 64
radix = 2
stg_nb = 11
prime_modulus = "GF64"
psi = 16
delta = 6

[ks_params]
width = 21
lbx = 2
lby = 32
lbz = 3

[pc_params]
ksk_pc = 4
ksk_bytes_w = 32
bsk_pc = 4
glwe_pc = 1
bsk_bytes_w = 32
pem_pc = 1
pem_bytes_w = 32
glwe_bytes_w = 32

[regf_params]
reg_nb = 64
coef_nb = 32

[isc_params]
depth = 64
min_iop_size = 1
"#;

pub fn hpu_mini_params() -> HpuParameters {
    toml::from_str(HPU_MINI_TOML).expect("invalid hpu_mini parameter TOML")
}
