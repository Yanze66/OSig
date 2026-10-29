//! Exact value copied from TFHE 1.8.1 src/shortint/parameters/v1_4/hpu.rs.
//! That HPU module is not exported by the current shortint-only build.
//! scripts/audit_parameters.py checks the literal against the upstream source.
use tfhe::shortint::parameters::*;
pub const PARAM_KEY_1: KeySwitch32PBSParameters =
    KeySwitch32PBSParameters {
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
pub const PARAMETER_ID: &str = "v1_4_hpu_879_ks32_tuniform_2m128";
