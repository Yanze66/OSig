//! One known-matching diagnostic sample, outside all benchmark timers.
use crate::{receiver::Receiver, sender::Sender, utility};
use tfhe::shortint::{ciphertext::ShortintCompactCiphertextListCastingMode, Ciphertext};

fn report(label: &str, ciphertexts: &[Ciphertext]) {
    let raw_bytes: usize = ciphertexts.iter().map(|c| std::mem::size_of_val(c.ct.as_ref())).sum();
    let serialized_bytes = bincode::serialized_size(ciphertexts).unwrap();
    println!("\nIO {label}: count={} raw_coefficient_bytes={raw_bytes} bincode_list_bytes={serialized_bytes}", ciphertexts.len());
    println!("  element_type={}", std::any::type_name::<Ciphertext>());
    for (i, c) in ciphertexts.iter().enumerate() {
        let coefficients: &[u64] = c.ct.as_ref();
        println!("  [{i}] scalar=u64 lwe_dimension={} coefficients={} raw_bytes={} bincode_ciphertext_bytes={} message_modulus={} carry_modulus={} degree={:?} noise={:?} ciphertext_modulus={:?}",
            coefficients.len() - 1, coefficients.len(), std::mem::size_of_val(coefficients),
            bincode::serialized_size(c).unwrap(), c.message_modulus.0, c.carry_modulus.0,
            c.degree, c.noise_level(), c.ct.ciphertext_modulus());
        println!("      mask_first4={:?} body={}", &coefficients[..4.min(coefficients.len()-1)], coefficients.last().unwrap());
    }
}

pub fn run(receiver: &Receiver) {
    let message: Vec<u64> = (0..utility::SLOT_SIZE_CIPHERTEXT)
        .map(|i| (i % utility::MESSAGE_SPACE_MOD) as u64).collect();
    let request = Sender::generate_signal(&message, &receiver.pk1);
    println!("\n=== ONE MESSAGE / ONE RECEIVER IO INSPECTION ===");
    println!("receiver={} sample=known_matching plaintext_signal={message:?}", receiver.id);
    println!("This diagnostic creates a fresh message and exits without running the benchmark.");
    println!("Compact transport type={}", std::any::type_name_of_val(&request.tag.vector));
    println!("Transport bincode bytes: signal={} ptag={}",
        bincode::serialized_size(&request.signal.ciphertext).unwrap(),
        bincode::serialized_size(&request.tag.vector).unwrap());
    let mut tag = request.tag.vector.expand(ShortintCompactCiphertextListCastingMode::NoCasting).unwrap();
    let mut signal = request.signal.ciphertext.expand(ShortintCompactCiphertextListCastingMode::NoCasting).unwrap();
    report("rectification.input.signal", &signal);
    report("rectification.input.ptag", &tag);

    let key = &receiver.pk1_server;
    let mut pi = key.create_trivial(1);
    report("pertinency.input.initial_accumulator", std::slice::from_ref(&pi));
    let mut rectified_tag = Vec::with_capacity(tag.len());
    // Same extraction/AND ordering as filter_out_pertinent_message.
    // Save each tag immediately after extraction, before smart AND may mutate it.
    for item in &mut tag {
        key.message_extract_assign(item);
        rectified_tag.push(item.clone());
        key.smart_bitand_assign(&mut pi, item);
    }
    let pi_before_filter = pi.clone();
    for item in &mut signal {
        key.message_extract_assign(item);
    }
    report("rectification.output.signal", &signal);
    report("rectification.output.ptag = pertinency.input.ptag", &rectified_tag);
    report("pertinency.output.PI (before filtering; NOT batch PF)", std::slice::from_ref(&pi_before_filter));
    let decoded_signal: Vec<u64> = signal.iter().map(|c| receiver.sk1.decrypt(c)).collect();
    let decoded_tag: Vec<u64> = rectified_tag.iter().map(|c| receiver.sk1.decrypt(c)).collect();
    let decoded_pi = receiver.sk1.decrypt(&pi_before_filter);
    assert_eq!(decoded_signal, message);
    assert_eq!(decoded_tag, vec![utility::TAG_VALUE; utility::L / utility::TAG_PLAIN_TEXT_SPACE]);
    assert_eq!(decoded_pi, 1);
    println!("\nDEBUG ONLY decrypted rectified signal={decoded_signal:?} ptag={decoded_tag:?} PI={decoded_pi}");
    println!("Receiver secret key is used only for this diagnostic validation; server processing does not decrypt.");
    println!("Shared ServerKey bincode bytes={} (additional evaluation-key storage, not included in operand sizes)", bincode::serialized_size(key).unwrap());
    println!("Raw bytes count only LWE mask+body u64 coefficients; bincode bytes include metadata/framing and are not a hardware wire format.");
    println!("These are shortint API boundaries, not internal PBS/FFT buffers; evaluation keys and scratch memory are additional.");
}
