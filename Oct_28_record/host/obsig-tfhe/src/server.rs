use crate::postbox::{Inbox, PostBox};
use crate::profiling::{AlgorithmTiming, CacheTiming};
use crate::receiver::Receiver;
use crate::sender::MessageRequest;
use crate::{utility, Config};
use chrono::Local;
use rayon::prelude::*;
use std::collections::HashMap;
use std::time::{Duration, Instant};
use tfhe::shortint::ciphertext::ShortintCompactCiphertextListCastingMode;
use tfhe::shortint::{Ciphertext, CompactPublicKey, ServerKey};

pub struct Server {
    postbox: PostBox,
    config: Config
}

struct Job {
    duration: Duration,
    id: String,
    inbox: Option<Inbox>,
}

#[derive(Clone)]
pub struct BatchStat {
    pub(crate) filter_time: f64,
    pub(crate) cmux_time: f64,
    pub(crate) batch_size: f64,
}

/// Summed elapsed time of disjoint operation scopes across recipient workers.
/// These are worker durations, not parallel wall-clock time.
#[derive(Clone, Default)]
pub struct ProcessingProfile {
    pub rectification: Duration,
    pub pertinency_check: Duration,
    pub filter_accumulate: Duration,
    pub inbox_update: Duration,
}

impl ProcessingProfile {
    fn merge(&mut self, other: &Self) {
        self.rectification += other.rectification;
        self.pertinency_check += other.pertinency_check;
        self.filter_accumulate += other.filter_accumulate;
        self.inbox_update += other.inbox_update;
    }
}

pub struct ShardStat {
    pub signal_generation: AlgorithmTiming,
    pub signal_cache: CacheTiming,
    pub processing_worker_seconds: f64,
    pub decryption: AlgorithmTiming,
    pub profile: ProcessingProfile,
    pub id: String,
    pub total_process_duration: f64,
    pub per_message_filter_time: f64,
    pub per_message_cmux_time: f64,
    pub per_message_expansion_time: f64,
    pub per_inbox_decryption_time: f64,
    pub recipient_count: usize,
    pub total_processed_batch: usize,
    pub total_messages: usize,
}

pub fn gen_inbox(id: &String, public_key: &CompactPublicKey, server_key: &ServerKey, inbox_capacity: usize) -> Inbox {
    println!(
        "{} | SERVER: {} | {} {}",
        Local::now(),
        "gen_inbox",
        "generating inbox for",
        id
    );
    let inbox = Inbox::new(id.clone(), public_key.clone(), server_key.clone(), inbox_capacity);

    inbox
}

impl Server {
    pub fn new(id: String, config: Config) -> Self {
        Server {
            postbox: PostBox::new(id),
            config
        }
    }

    pub fn set_inbox(&mut self, id: &String, inbox: &Inbox) {
        self.postbox.set_inbox(id.clone(), inbox);
    }

    pub fn get_inbox(&self, id: &String) -> Inbox {
        let inbox_option = self.postbox.get_inbox(&id);
        if inbox_option.is_some() {
            let inbox_ref = inbox_option.unwrap();
            inbox_ref.clone()
        } else {
            panic!("INBOX NOT FOUND");
        }
    }

    pub fn send_message(&mut self, message_req_vec: Vec<MessageRequest>) {
        if message_req_vec.len() > self.config.batch_size{
            panic!(
                "message_req_vec.len {} > {}",
                message_req_vec.len(),
                self.config.batch_size
            );
        }

        self.postbox.push_new_message_to_q(message_req_vec);
    }

    pub fn expand_message_q(
        msg_q: &Vec<Vec<MessageRequest>>,
    ) -> (Vec<Vec<(Vec<Ciphertext>, Vec<Ciphertext>)>>, f64) {
        let start_time = Instant::now();

        let output: Vec<Vec<(Vec<Ciphertext>, Vec<Ciphertext>)>> = msg_q
            .par_iter()
            .map(|batch| {
                batch
                    .iter()
                    .map(|message_request| {
                        //expansion
                        let tag: Vec<Ciphertext> = message_request
                            .tag
                            .vector
                            .expand(ShortintCompactCiphertextListCastingMode::NoCasting)
                            .unwrap();

                        let signal: Vec<Ciphertext> = message_request
                            .signal
                            .ciphertext
                            .expand(ShortintCompactCiphertextListCastingMode::NoCasting)
                            .unwrap();

                        (tag, signal)
                    })
                    .collect()
            })
            .collect();

        let end_time = start_time.elapsed();


        (output, end_time.as_secs_f64())
    }

    pub fn filter_out_pertinent_message(
        inbox: &mut Inbox,
        batch: Vec<(Vec<Ciphertext>, Vec<Ciphertext>)>,
        verify: Option<(&Receiver, &[crate::validation::PlainMessage], usize)>,
    ) -> (Ciphertext, Vec<Ciphertext>, f64, ProcessingProfile) {
        if let Some(dev) = crate::fpga::get() {
            return Server::filter_out_pertinent_message_fpga(dev, inbox, batch, verify);
        }
        let start_time = Instant::now();

        let srv_key = &inbox.server_key;

        let mut profile = ProcessingProfile::default();
        let (mut pertinency_tags, mut signals): (Vec<Ciphertext>, Vec<Vec<Ciphertext>>) = batch
            .into_iter() //TODO: parallel candidate
            .enumerate()
            .map(|(message_index, (mut tag, signal))| {
                let mut pertinency_tag = inbox.one_trivial_ct.clone();
                let inputs = verify.map(|_| (tag.clone(), signal.clone()));
                let mut rectified_tags=Vec::new();
                let mut rectified_signals=Vec::new();

                tag.iter_mut().for_each(|mut tag_item| {
                    let start = Instant::now();
                    srv_key.message_extract_assign(&mut tag_item);
                    profile.rectification += start.elapsed();
                    if verify.is_some() { rectified_tags.push(tag_item.clone()); }
                    let start = Instant::now();
                    srv_key.smart_bitand_assign(&mut pertinency_tag, tag_item);
                    profile.pertinency_check += start.elapsed();
                });

                let pi_before_filter = verify.map(|_| pertinency_tag.clone());
                let signal: Vec<Ciphertext> = signal
                    .into_iter()
                    .map(|mut signal| {
                        let start = Instant::now();
                        srv_key.message_extract_assign(&mut signal);
                        if verify.is_some() { rectified_signals.push(signal.clone()); }
                        profile.rectification += start.elapsed();
                        let start = Instant::now();
                        let filtered = srv_key.smart_mul_lsb(&mut pertinency_tag, &mut signal);
                        profile.filter_accumulate += start.elapsed();
                        filtered
                    })
                    .collect();

                if let Some((receiver,plain,batch_index))=verify {
                    let (input_tag,input_signal)=inputs.as_ref().unwrap();
                    crate::validation::record_pair(receiver,&plain[message_index],batch_index,message_index,
                        input_tag,input_signal,&rectified_tags,&rectified_signals,pi_before_filter.as_ref().unwrap(),&signal);
                }
                (pertinency_tag, signal)
            })
            .unzip();

        let accumulate_start = Instant::now();
        let mut pertinency_indicator = pertinency_tags[0].clone();

        for i in 1..pertinency_tags.len() {
            srv_key.smart_add_assign(&mut pertinency_indicator, &mut pertinency_tags[i]);
        }

        let mut signal_acc = signals[0].clone();

        for i in 1..signals.len() {
            for j in 0..signal_acc.len() {
                srv_key.smart_add_assign(&mut signal_acc[j], &mut signals[i][j]);
            }
        }

        let end_time = start_time.elapsed();

        profile.filter_accumulate += accumulate_start.elapsed();
        (pertinency_indicator, signal_acc, end_time.as_secs_f64(), profile)
    }

    /// Same computation as `filter_out_pertinent_message`, with every PBS of 4.1/4.2/4.3 executed on the
    /// VCK190 hpu_mini core in batches (up to 32 ciphertexts per request, 8 pipelined in the PE):
    ///   4.1 rectification : MsgOnly LUT on every tag digit and signal digit of the batch (one stream);
    ///   4.2 pertinency    : the CPU chain pi = 1 & t0 & ... & t15, one round per digit batched across
    ///                        the messages (custom LUT gid 40, packing 2*t + pi);
    ///   4.3 filter        : custom LUT gid 41 on (2*signal digit + pi) = smart_mul_lsb;
    ///   accumulation stays on the CPU exactly as before.
    ///   Packing follows tfhe's smart bivariate choice (scale the degree-3 operand by pi.degree+1 = 2,
    ///   pi unscaled in the lowest bit): on ciphertexts of other recipients (garbage, possibly with the
    ///   padding bit set) this keeps pi = 0 absorbing, exactly like the CPU; the HPU's built-in
    ///   carry*msg packing (4*pi + x) does not, which showed up as non-zero filtered signals.
    pub fn filter_out_pertinent_message_fpga(
        dev: &crate::fpga::Fpga,
        inbox: &mut Inbox,
        batch: Vec<(Vec<Ciphertext>, Vec<Ciphertext>)>,
        verify: Option<(&Receiver, &[crate::validation::PlainMessage], usize)>,
    ) -> (Ciphertext, Vec<Ciphertext>, f64, ProcessingProfile) {
        use crate::fpga::{GID_AND2, GID_MSG_ONLY, GID_MUL2, PACK2_FACTOR};
        let start_time = Instant::now();
        let srv_key = &inbox.server_key;
        let slot = dev.slot_of(&inbox.id);
        let mut profile = ProcessingProfile::default();
        let n_msg = batch.len();
        let inputs: Option<Vec<(Vec<Ciphertext>, Vec<Ciphertext>)>> = verify.map(|_| batch.clone());
        // tfhe's smart bivariate packing for (x: degree 3, pi: degree 1): 2*x + pi, pi in the lowest bit
        let pack2 = |x: &Ciphertext, pi: &Ciphertext| -> Ciphertext {
            let mut p = srv_key.unchecked_scalar_mul(x, PACK2_FACTOR);
            srv_key.unchecked_add_assign(&mut p, pi);
            p
        };

        // 4.1 rectification
        let t = Instant::now();
        let refs: Vec<&Ciphertext> = batch.iter().flat_map(|(tag, sig)| tag.iter().chain(sig.iter())).collect();
        let mut rect = dev.pbs_batch(slot, GID_MSG_ONLY, &refs, 3).into_iter();
        let mut tags: Vec<Vec<Ciphertext>> = Vec::with_capacity(n_msg);
        let mut sigs: Vec<Vec<Ciphertext>> = Vec::with_capacity(n_msg);
        for (tag, sig) in &batch {
            tags.push((0..tag.len()).map(|_| rect.next().unwrap()).collect());
            sigs.push((0..sig.len()).map(|_| rect.next().unwrap()).collect());
        }
        profile.rectification += t.elapsed();
        let rectified_tags = verify.map(|_| tags.clone());

        // 4.2 pertinency check: the CPU chain pi = 1 & t0 & t1 & ... & t15, one round per tag digit,
        // batched across the messages of the batch (same PBS count and packing as the CPU).
        let t = Instant::now();
        let n_digits = tags.iter().map(|v| v.len()).max().unwrap_or(0);
        let mut pertinency_tags: Vec<Ciphertext> = vec![inbox.one_trivial_ct.clone(); n_msg];
        for d in 0..n_digits {
            let idx: Vec<usize> = (0..n_msg).filter(|&m| d < tags[m].len()).collect();
            let packed: Vec<Ciphertext> = idx.iter().map(|&m| pack2(&tags[m][d], &pertinency_tags[m])).collect();
            let anded = dev.pbs_batch(slot, GID_AND2, &packed.iter().collect::<Vec<_>>(), 1);
            for (k, &m) in idx.iter().enumerate() { pertinency_tags[m] = anded[k].clone(); }
        }
        profile.pertinency_check += t.elapsed();
        let pi_before_filter = verify.map(|_| pertinency_tags.clone());

        // 4.3 filter (multiply each rectified signal digit by the pertinency tag), then accumulate on the CPU
        let t = Instant::now();
        let packed: Vec<Ciphertext> = (0..n_msg).flat_map(|m| sigs[m].iter().map(|s| pack2(s, &pertinency_tags[m])).collect::<Vec<_>>()).collect();
        let mut filtered = dev.pbs_batch(slot, GID_MUL2, &packed.iter().collect::<Vec<_>>(), 3).into_iter();
        let mut signals: Vec<Vec<Ciphertext>> = (0..n_msg).map(|m| (0..sigs[m].len()).map(|_| filtered.next().unwrap()).collect()).collect();
        profile.filter_accumulate += t.elapsed();

        if let Some((receiver, plain, batch_index)) = verify {
            let inputs = inputs.as_ref().unwrap();
            let rectified_tags = rectified_tags.as_ref().unwrap();
            let pi = pi_before_filter.as_ref().unwrap();
            for m in 0..n_msg {
                crate::validation::record_pair(receiver, &plain[m], batch_index, m,
                    &inputs[m].0, &inputs[m].1, &rectified_tags[m], &sigs[m], &pi[m], &signals[m]);
            }
        }

        let accumulate_start = Instant::now();
        let mut pertinency_indicator = pertinency_tags[0].clone();
        for i in 1..pertinency_tags.len() {
            srv_key.smart_add_assign(&mut pertinency_indicator, &mut pertinency_tags[i]);
        }
        let mut signal_acc = signals[0].clone();
        for i in 1..signals.len() {
            for j in 0..signal_acc.len() {
                srv_key.smart_add_assign(&mut signal_acc[j], &mut signals[i][j]);
            }
        }
        let end_time = start_time.elapsed();
        profile.filter_accumulate += accumulate_start.elapsed();
        (pertinency_indicator, signal_acc, end_time.as_secs_f64(), profile)
    }

    pub fn cmux_shift_inbox(
        inbox: &mut Inbox,
        signal_acc: &Vec<Ciphertext>,
        pertinency_flag: &Ciphertext,

    ) -> f64 {
        let start_time = Instant::now();

        let srv_key = &inbox.server_key;

        for index in (0..inbox.slots.len()).rev() {
            let mut cipher: Vec<Ciphertext> = Vec::new();
            let mut slot_prev: Vec<Ciphertext> = Vec::new();
            let slot_curr = inbox.slots.get_mut(index).unwrap().ciphertext.clone();

            if index == 0 {
                slot_prev = signal_acc.clone();
            } else {
                slot_prev = inbox.slots.get_mut(index - 1).unwrap().ciphertext.clone();
            }

            for j in 0..slot_curr.len() {
                let new_slot_ct =
                    unsafe_smart_cmux(&srv_key, &pertinency_flag, &slot_prev[j], &slot_curr[j]);
                cipher.push(new_slot_ct);
            }

            inbox.slots[index].ciphertext = cipher;
        }
        let end_time = start_time.elapsed();
        end_time.as_secs_f64()
    }

    pub fn process_all_message2(
        &mut self,
        debug_receiver_id_map: &HashMap<String, &Receiver>,
    ) -> ShardStat {
        let shard_start = Instant::now();

        let (expanded_msg_q, total_time_for_expansion) =
            Server::expand_message_q(&self.postbox.msg_q);

        let total_messages: usize = expanded_msg_q.iter().map(|x| x.len()).sum();
        let per_message_expansion_time = total_time_for_expansion / total_messages as f64;

        let mut profile = ProcessingProfile::default();
        let mut processing_worker_seconds = 0.0;
        let batch_stat_vec: Vec<BatchStat> = expanded_msg_q
            .iter()
            .enumerate()
            // .progress()
            .map(|(batch_index,batch)| {
                let plain:Vec<_>=if self.config.verify_io { self.postbox.msg_q[batch_index].iter().map(crate::validation::lookup).collect() } else {Vec::new()};
                let processed_inbox_with_stat: Vec<_> = self
                    .postbox
                    .inbox_id_vec
                    .par_iter()
                    .map(|id| {
                        let worker_start = Instant::now();
                        let mut inbox: Inbox = self.postbox.get_inbox(id).unwrap().clone();
                        let batch = batch.clone();
                        let batch_len = batch.len();
                        let receiver=debug_receiver_id_map[id];
                        let before=self.config.verify_io.then(||crate::validation::decode_inbox(receiver,&inbox));
                        let verify=self.config.verify_io.then_some((receiver,plain.as_slice(),batch_index));

                        let (pertinency_flag, signal_acc, total_time_for_filter, mut worker_profile) =
                            Server::filter_out_pertinent_message(&mut inbox, batch, verify);

                        let total_for_cmux_shift =
                            Server::cmux_shift_inbox(&mut inbox, &signal_acc, &pertinency_flag);

                        worker_profile.inbox_update = Duration::from_secs_f64(total_for_cmux_shift);
                        if let Some(before)=before {
                            crate::validation::check_update(receiver,&before,&inbox,&plain,batch_index);
                        }
                        (
                            inbox,
                            BatchStat {
                                cmux_time: total_for_cmux_shift,
                                filter_time: total_time_for_filter,
                                batch_size: batch_len as f64,
                            },
                            worker_profile,
                            worker_start.elapsed().as_secs_f64(),
                        )
                    })
                    .collect();

                for (_, _, worker_profile, worker_seconds) in &processed_inbox_with_stat {
                    processing_worker_seconds += worker_seconds;
                    profile.merge(worker_profile);
                }
                let processed_inbox: Vec<Inbox> = processed_inbox_with_stat
                    .clone()
                    .into_iter()
                    .map(|(inbox, _, _, _)| inbox)
                    .collect();
                let batch_stats: Vec<BatchStat> = processed_inbox_with_stat
                    .into_iter()
                    .map(|(_, batch_stat, _, _)| batch_stat)
                    .collect();

                processed_inbox.iter().for_each(|(inbox)| {
                    self.set_inbox(&inbox.id, inbox);
                });

                let vec_time_cmux: Vec<f64> =
                    batch_stats.iter().map(|stat| stat.cmux_time).collect();
                let vec_time_filter: Vec<f64> = batch_stats
                    .into_iter()
                    .map(|stat| stat.filter_time)
                    .collect();

                let per_batch_filter_time = utility::get_mean(&vec_time_filter);
                let per_batch_cmux_time = utility::get_mean(&vec_time_cmux);

                let per_message_filter_time = per_batch_filter_time / batch.len() as f64; //doubt
                let per_message_cmux_time = per_batch_cmux_time / batch.len() as f64;

                BatchStat {
                    filter_time: per_message_filter_time,
                    cmux_time: per_message_cmux_time,
                    batch_size: batch.len() as f64,
                }
            })
            .collect();

        let shard_duration = shard_start.elapsed().as_secs_f64();

        let (per_message_filter_time, per_message_cmux_time) =
            utility::calculate_global_means(&batch_stat_vec);

        let decryption_start = Instant::now();
        let decryption_time_vec: Vec<f64> = self
            .postbox
            .inbox_id_vec
            .par_iter()
            .map(|id| {
                if self.config.verify_io {
                    crate::validation::check_final(debug_receiver_id_map[id],self.postbox.get_inbox(id).unwrap(),self.config.num_messages);
                }
                let decryption_time = debug_receiver_id_map
                    .get(id)
                    .unwrap()
                    .read_inbox_test(self.postbox.get_inbox(&id).unwrap());

                decryption_time
            })
            .collect();

        let decryption = AlgorithmTiming {
            wall_seconds: decryption_start.elapsed().as_secs_f64(),
            worker_seconds: decryption_time_vec.iter().sum(),
        };
        let per_inbox_decryption_time = utility::get_mean(&decryption_time_vec);

        ShardStat {
            signal_generation: AlgorithmTiming::default(),
            signal_cache: CacheTiming::default(),
            processing_worker_seconds,
            decryption,
            profile,
            id: self.postbox.id.clone(),
            total_process_duration: shard_duration,
            per_message_filter_time,
            per_message_cmux_time,
            per_message_expansion_time,
            per_inbox_decryption_time,
            recipient_count: self.postbox.inbox_id_vec.len(),
            total_processed_batch: self.postbox.msg_q.len(),
            total_messages,
        }
    }

    fn post_job_task(&mut self, job: Job, duration_vec: &mut Vec<Duration>) {
        utility::dump(
            "server.run.handle_job",
            format!(
                "Got job completed for: {}, time taken {} secs",
                job.id,
                job.duration.as_secs()
            ),
        );
        if (job.inbox.is_some()) {
            let inbox = job.inbox.unwrap();
            self.set_inbox(&inbox.id, &inbox);
        }
        duration_vec.push(job.duration)

        // debug_receiver_id_map
        //     .get(&job.inbox.id)
        //     .unwrap()
        //     .read_inbox(&job.inbox);
    }
}

pub fn job(
    msg_vec: &Vec<MessageRequest>,
    inbox: &mut Inbox,
    debug_receiver_id_map: HashMap<String, &Receiver>,
) {
    let srv_key = &inbox.server_key;

    let (mut pertinency_tags, mut signals): (Vec<Ciphertext>, Vec<Vec<Ciphertext>>) = msg_vec
        .into_iter()
        .map(|msg_req| {
            let mut pertinency_tag = inbox.one_trivial_ct.clone();

            let mut tag: Vec<Ciphertext> = msg_req
                .tag
                .vector
                .expand(ShortintCompactCiphertextListCastingMode::NoCasting)
                .unwrap();

            tag.iter_mut().for_each(|mut tag_item| {
                srv_key.message_extract_assign(&mut tag_item);
                srv_key.smart_bitand_assign(&mut pertinency_tag, tag_item);
            });

            let signal: Vec<Ciphertext> = msg_req
                .signal
                .ciphertext
                .expand(ShortintCompactCiphertextListCastingMode::NoCasting)
                .unwrap()
                .into_iter()
                .map(|mut signal| {
                    srv_key.message_extract_assign(&mut signal);
                    srv_key.smart_mul_lsb(&mut pertinency_tag, &mut signal)
                })
                .collect();

            (pertinency_tag, signal)
        })
        .unzip();

    let mut pertinency_indicator = pertinency_tags[0].clone();

    for i in 1..pertinency_tags.len() {
        srv_key.smart_add_assign(&mut pertinency_indicator, &mut pertinency_tags[i]);
    }

    let mut signal_acc = signals[0].clone();

    for i in 1..signals.len() {
        for j in 0..signal_acc.len() {
            srv_key.smart_add_assign(&mut signal_acc[j], &mut signals[i][j]);
        }
    }

    //CMux SHIFITNG

    for index in (0..inbox.slots.len()).rev() {
        let mut cipher: Vec<Ciphertext> = Vec::new();
        let mut slot_prev: Vec<Ciphertext> = Vec::new();
        let slot_curr = inbox.slots.get_mut(index).unwrap().ciphertext.clone();

        if index == 0 {
            slot_prev = signal_acc.clone();
        } else {
            slot_prev = inbox.slots.get_mut(index - 1).unwrap().ciphertext.clone();
        }

        for j in 0..slot_curr.len() {
            let new_slot_ct = unsafe_smart_cmux(
                &srv_key,
                &pertinency_indicator,
                &slot_prev[j],
                &slot_curr[j],
            );
            cipher.push(new_slot_ct);
        }

        inbox.slots[index].ciphertext = cipher;
    }

    // debug_print(
    //     debug_receiver_id_map,
    //     pertinency_tags,
    //     signal_acc,
    //     pertinency_indicator,
    //     inbox,
    // );
}

fn debug_print(
    debug_receiver_id_map: HashMap<String, &Receiver>,
    pertinency_tags: Vec<Ciphertext>,
    signal_acc: Vec<Ciphertext>,
    pertinency_indicator: Ciphertext,
    inbox: &mut Inbox,
) {
    let decrypted_tags: Vec<u64> = pertinency_tags
        .into_iter()
        .map(|tag| {
            debug_receiver_id_map
                .get(&inbox.id)
                .unwrap()
                .sk1
                .decrypt(&tag)
        })
        .collect();

    let decrypted_sig_acc: Vec<u64> = signal_acc
        .into_iter()
        .map(|sig_item| {
            debug_receiver_id_map
                .get(&inbox.id)
                .unwrap()
                .sk1
                .decrypt(&sig_item)
        })
        .collect();

    let plain_pertinency_indicator = debug_receiver_id_map
        .get(&inbox.id)
        .unwrap()
        .sk1
        .decrypt(&pertinency_indicator);

    println!(
        "Tags {:?} PI {plain_pertinency_indicator} acc {:?}",
        decrypted_tags, decrypted_sig_acc
    );
}

/* it's called "unsafe" because 
this is not making sure the ct_control to be 0 or 1. it is expected in a boolean form.
*/
pub fn unsafe_smart_cmux(
    server_key: &ServerKey,
    ct_control: &Ciphertext,
    ct_true: &Ciphertext,
    ct_false: &Ciphertext,
) -> Ciphertext {
    let mut c = ct_control.clone();
    let mut t = ct_true.clone();
    let mut f = ct_false.clone();

    // diff = (t - f)
    server_key.smart_sub_assign(&mut t, &mut f);

    // gated = c * diff  (mul_lsb is the typical shortint multiply primitive)
    let mut gated = server_key.smart_mul_lsb(&mut t, &mut c);

    // res = f + gated
    server_key.smart_add(&mut gated, &mut f)
}
