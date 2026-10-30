# OSig TFHE HPU

## Oct 28, 2026 — Hardware Batch Depths 16 and 32

The 200 MHz implementations now include **`bpbs16_tpbs32` (b16)** and
**`bpbs32_tpbs48` (b32)**. Increasing hardware batch depth from 8 to 16 reduces
hardware time for requests of 16–32 ciphertexts from approximately 0.83–0.84 ms
to **0.56–0.57 ms per ciphertext**, a 1.46–1.47× improvement. Increasing
hardware batch depth to 32 provides no further measured throughput benefit.
All reported MsgOnly and BwAnd decryption checks pass.

Hardware batch depth is distinct from the number of ciphertexts in a client
request. Earlier request sizes of 16 or 32 were processed by the depth-8
implementation; today's results change the hardware batch configuration.

### Implementation Configurations

| Item | b16 | b32 |
| --- | --- | --- |
| Hardware configuration | `bpbs16_tpbs32` | `bpbs32_tpbs48` |
| `BATCH_PBS_NB` / `TOTAL_PBS_NB` | 16 / 32 | 32 / 48 |
| Target clock | 200 MHz | 200 MHz |
| Clock measured with `CYCLE` counter | 199.2 MHz | 200.36 MHz |
| Boot image | `BOOT_b16.BIN` | `BOOT_b32.BIN` |
| Kernel | `hpu_mini_b16.xclbin` | `hpu_mini_b32.xclbin` |
| Reported resource utilization | LUT 39.6% (355,943), BRAM 58% (561 tiles), URAM 21% (96) | LUT 40.0% (363,081), BRAM 77% (745 tiles), URAM 34% (156) |
| Post-route WNS at 200 MHz | +0.082 ns | +0.136 ns |

Artifacts, sources, keys, raw measurements and a reproduction guide are in
[`Oct_28_record/`](Oct_28_record/README.md); the system architecture is
described in [`Oct_28_record/ARCHITECTURE.md`](Oct_28_record/ARCHITECTURE.md).

The b16 configuration is generated with `scripts/gen_cfg_flow.py --cfg b16`.
It changes `pep_batch_definition_pkg` from 8 / 16 to 16 / 32 without changing
the datapath RTL. BSK/KSK is streamed once per hardware batch; a fuller batch
amortizes that traffic over more ciphertexts. The depth-8 reference uses 56%
BRAM, compared with 58% for b16 and 77% for b32.

### b16 Measurements

Cycle counts, hardware times, and client round-trip times are per ciphertext.
Speedup compares with the 200 MHz depth-8 implementation at the same request
size. Reported hardware times use the nominal 200 MHz clock.

| Request size | LUT | Hardware cycles / ciphertext | Hardware time / ciphertext | Round trip / ciphertext | Decryption checks | Hardware speedup vs. depth 8 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | MsgOnly | 1,322,709 | 6.61 ms | 6.88 ms | 10/10 | 1.01× |
| 1 | BwAnd | 1,323,104 | 6.62 ms | 6.88 ms | 16/16 | 1.01× |
| 8 | MsgOnly | 166,944 | 0.83 ms | 1.47 ms | 10/10 | 1.00× |
| 16 | MsgOnly | 113,953 | 0.57 ms | 1.14 ms | 10/10 | 1.47× |
| 16 | BwAnd | 113,651 | 0.57 ms | 1.18 ms | 16/16 | 1.46× |
| 32 | MsgOnly | 112,848 | 0.56 ms | 1.15 ms | 10/10 | 1.47× |
| 32 | BwAnd | 113,285 | 0.57 ms | 1.15 ms | 16/16 | 1.46× |

An eight-ciphertext request ends with a flush and runs as a half-full hardware
batch, still reading the complete key stream. Its performance therefore
remains close to depth 8. Single requests likewise require a complete key
stream and remain around 6.6 ms.

At approximately 1.15 ms round trip per ciphertext, hardware accounts for
only about half the time. TCP, XRT synchronization, and server copies add
approximately 0.55–0.60 ms per ciphertext. Host-side parallelism or pipelining
on the board is a remaining optimization opportunity.

Raw b16 measurements are recorded locally in
`build_kernel_b16/perf_batch/*.txt`.

### b32 Measurements

Slash-separated values refer to MsgOnly and BwAnd, respectively. Total
cycles are rounded totals for the request's PBS phase; all other times and
cycle counts are per ciphertext. Combined time entries reproduce the rounded
values in the supplied report.

| Request size | LUT | Total PBS cycles | Hardware cycles / ciphertext | Hardware time / ciphertext | Round trip / ciphertext | Decryption checks |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | MsgOnly / BwAnd | 1.31M | 1,313,172 / 1,308,736 | 6.56 ms | 6.84 ms | 10/10, 16/16 |
| 8 | MsgOnly | 1.33M | 165,668 | 0.83 ms | 1.48 ms | 10/10 |
| 16 | MsgOnly / BwAnd | 1.82M | 113,718 / 113,725 | 0.57 ms | 1.16 ms | 10/10, 16/16 |
| 20 | MsgOnly | 2.28M | 114,074 | 0.57 ms | 1.13 ms | 10/10 |
| 24 | MsgOnly | 2.72M | 113,515 | 0.57 ms | 1.14 ms | 10/10 |
| 28 | MsgOnly | 3.18M | 113,512 | 0.57 ms | 1.10 ms | 10/10 |
| 32 | MsgOnly / BwAnd | 3.63M | 113,510 / 113,413 | 0.57 ms | 1.15 ms | 10/10, 16/16 |

For 32 ciphertexts, one b32 batch takes approximately 3.63M cycles, compared
with approximately 3.61M cycles for two b16 batches. From request sizes 16
through 32, b32 stays near 113.5k cycles per ciphertext. The increase to 77%
BRAM therefore brings no measured throughput improvement over b16.



### OSig Server (Alg4) with b16 and b32

Same workload and host as the Oct 27 comparison (ten recipients, CPU
baseline 52.71 s). Two runs each; `--verify-io -r 4` passes 4/4
`FINAL_INBOX_PASS` and `OSIG_HPU_CPU_VALIDATION_PASS` on both images.

| Configuration | Alg4 wall time (s) | Speedup vs. CPU | Total worker (s) | 4.1 Rectification | 4.2 Pertinency | 4.3 Filter / accumulate | 4.4 Inbox update | Board cycles / ciphertext | Board busy / Alg4 wall |
| ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- | ----- |
| 200 MHz depth 8    | 22.21–22.52  | 2.34–2.37× | 188.9–190.5 | 63.1–63.5 | 93.5–93.8 | 11.9–12.1 | 17.8–19.7 | 214.2k | 69% |
| 200 MHz b16, run 1 | 15.88  | 3.32× | 125.6 | 43.7 | 53.0 | 9.3 | 17.6 | 129.6k | 59% |
| 200 MHz b16, run 2 | 16.01  | 3.29× | 125.6 | 43.8 | 53.0 | 8.8 | 17.8 | 129.4k | 59% |
| 200 MHz b32, run 1 | 15.76  | 3.34× | 124.1 | 43.8 | 51.4 | 9.0 | 17.5 | 125.0k | 57% |
| 200 MHz b32, run 2 | 15.74  | 3.35× | 123.6 | 43.2 | 51.8 | 8.3 | 17.8 | 125.0k | 57% |

The pertinency AND chain benefits most: each round submits ten ciphertexts
per recipient, which depth 8 split into 8 + 2 batches and b16/b32 run as one.
b32 gains only 3% over b16 in OSig, from the 20-ciphertext filter requests
(16 + 4 under b16, a single batch under b32). Board busy time is now below
60% of the Alg4 wall time, so host-side work (packing, accumulation, cmux,
TCP queueing) is the larger share.



## Oct 27, 2026 — OSig Server: VCK190 vs. CPU

Offloading all KS+PBS operations in OSig rectification, pertinency checking,
and filtering to VCK190 `hpu_mini` reduces server processing (Alg4) for ten
recipients from **52.71 s on the CPU to 22.21–22.52 s at 200 MHz**
(2.34–2.37× speedup), or 26.75–26.81 s at 100 MHz. The validation runs
reported below match the CPU outputs bit for bit.

### 1. Comparison Setup

| Item | CPU baseline | FPGA path |
| --- | --- | --- |
| Command | `obsig-tfhe --run-dir runs/bench_r10` | Same binary with `--fpga 192.168.50.2:5002` |
| Parameters | `v1_4_hpu_879_ks32_tuniform_2m128`: N=2048, k=1, LWE 879, PBS 23/1, KS 2/8, KS32 | Same |
| Workload | G=25, Q=10, R=10, V=4; ten recipients, ten messages per round, 16-bit tags and 2-bit signals | Same keys and messages from `runs/bench_r10` |
| Host CPU | Intel Core i9-14900K, 24 cores / 32 threads; tfhe-rs 1.8.1, x86 FFT; Rayon parallelism across ten inboxes | Same host, with PBS requests sent to the board |
| FPGA | — | VCK190 (`xcvc1902`), `hpu_mini`: one PE, PSI16 NTT, `BATCH_PBS_NB=8`, `TOTAL_PBS_NB=16`; keys resident in board DDR |
| Connection | — | Direct Gigabit Ethernet (`eno2` ↔ `end0`), HPQ1 TCP protocol; command 9 (`PBS_BATCH`) accepts up to 32 ciphertexts per request |
| Work split | All operations on CPU | PBS for 4.1 rectification, 4.2 pertinency AND chains, and 4.3 filtering multiplication on FPGA; packing, accumulation (`smart_add`), and 4.4 inbox updates (`cmux`) on CPU |

The CPU baseline executes all 15,680 PBS operations on the CPU. The FPGA
path executes 14,400 on the board and 1,280 inbox-update PBS operations on
the CPU.

### 2. Results

#### 2.1 Server Processing (Alg4), Ten Recipients

| Configuration | Alg4 wall time | Speedup vs. CPU | Total worker_s | 4.1 Rectification | 4.2 Pertinency | 4.3 Filter / accumulate | 4.4 Inbox update |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CPU baseline | 52.71 s | 1.00× | 398.7 | 186.2 | 165.8 | 25.2 | 19.0 |
| FPGA 100 MHz, run 1 | 26.75 s | 1.97× | 234.1 | 84.0 | 114.8 | 15.3 | 18.1 |
| FPGA 100 MHz, run 2 | 26.81 s | 1.97× | 234.6 | 84.1 | 115.1 | 15.3 | 18.1 |
| FPGA 200 MHz, run 1 | 22.52 s | 2.34× | 190.5 | 63.1 | 93.8 | 11.9 | 19.7 |
| FPGA 200 MHz, run 2 | 22.21 s | 2.37× | 188.9 | 63.5 | 93.5 | 12.1 | 17.8 |

`worker_s` and the four stage columns are sums of elapsed seconds across ten
recipient tasks, including waiting; they are not CPU time. Individual stages
have no separate wall-clock measurement because the workers interleave.

The full pipeline, including key generation, signal generation, and decryption,
takes 56.8 s on CPU, 43.0–44.4 s with FPGA at 100 MHz, and 38.4–39.2 s at
200 MHz. Uploading the FPGA key images (approximately 101 MB of BSK+KSK per
recipient; approximately 15 s for ten recipients) is one-time preparation
excluded from these timings.

#### 2.2 On-Board PBS Statistics from OSig Runs

| Configuration | Requests | Ciphertexts | Mean hardware cycles / ciphertext | Mean hardware time / ciphertext | Board busy time / Alg4 wall time |
| --- | --- | --- | --- | --- | --- |
| 100 MHz | 920 | 14,400 | 139.6k | 1.40 ms | 20.1 s / 26.8 s = 75% |
| 200 MHz | 920 | 14,400 | 214.2k | 1.07 ms | 15.4 s / 22.4 s = 69% |

These values come from `FPGA_STATS`. The logged `mean_wire_us_per_ct`
(11–14 ms) includes ten recipient threads queueing for the same board.
It is not the network overhead or isolated round-trip latency of one request.

#### 2.3 Microbenchmarks: Single Requests and Batches

All step2 test-vector outputs passed decryption checks. Times and cycle
counts below are per ciphertext; hardware speedup compares 200 MHz with
100 MHz.

| Batch size | LUT | 100 MHz cycles | 100 MHz hardware time | 200 MHz cycles | 200 MHz hardware time | 200 MHz round trip | Hardware speedup |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | MsgOnly | 789k | 7.89 ms | 1,337k | 6.69 ms | 6.96 ms | 1.18× |
| 1 | BwAnd | 789k | 7.89 ms | 1,336k | 6.68 ms | 7.71 ms | 1.18× |
| 8 | MsgOnly | 113.9k | 1.14 ms | 167.5k | 0.84 ms | 1.46 ms | 1.36× |
| 16 | MsgOnly | 113.1k | 1.13 ms | 167.0k | 0.84 ms | 1.41 ms | 1.35× |
| 16 | BwAnd | 113.3k | 1.13 ms | 166.3k | 0.83 ms | 1.40 ms | 1.36× |
| 32 | MsgOnly | 112.9k | 1.13 ms | 166.4k | 0.83 ms | 1.43 ms | 1.36× |
| 32 | BwAnd | 112.8k | 1.13 ms | 165.8k | 0.83 ms | 1.38 ms | 1.36× |

A single-threaded CPU PBS with the same parameters takes approximately
15.0 ms. At 200 MHz, amortized batch hardware time is approximately 18×
faster and amortized round-trip time approximately 10.7× faster than that
single-threaded reference. These ratios compare batch amortization against
single-operation CPU latency; the parallel application comparison is in 2.1.

Raw microbenchmark data resides in the local build workspace under
`step2_pbs_core/build_kernel_200/perf_batch/*.txt` (200 MHz) and
`step2_pbs_core/build_kernel/perf_batch/*.txt` (100 MHz).

### 3. Correctness and Clock Verification

- At 200 MHz, step2 MsgOnly passes 10/10 vectors for single requests and
  batches of 8, 16, and 32. BwAnd passes 16/16 for single requests and
  batches of 16 and 32. `verify_hw_outputs.sh` checks decrypted outputs.
- OSig `--verify-io -r 4` covers four recipients, 16 matching pairs, and
  48 nonmatching pairs. Both 100 MHz and 200 MHz runs report 4/4
  `FINAL_INBOX_PASS` and `OSIG_HPU_CPU_VALIDATION_PASS`. Checks cover
  rectified tags, PI, filtered signals, and inbox updates against the CPU
  path. Local logs: `logs/fpga_verify_r4.log` and
  `logs/fpga_verify_r4_200mhz.log`.
- Comparing the kernel `CYCLE` counter against a two-second wall-clock
  interval measures 200.25 MHz. The earlier test that replaced only the
  xclbin, before replacing `BOOT.BIN`, measured 99.9 MHz.

### 4. Interpretation

1. **Alg4 speedup is 2.3–2.4× at 200 MHz.** The CPU already runs ten
   recipients in parallel with Rayon, while one FPGA PE serves the ten
   threads serially. Inbox updates remain on the CPU: 1,280 PBS operations,
   approximately 18 worker-seconds, or 10% of FPGA-path worker time.
2. **Doubling the clock yields approximately 1.18× for single requests and
   1.36× for batches.** Batch cycles per ciphertext rise from approximately
   113k to 167k; single-request cycles rise from 789k to 1,337k. A two-point
   model, `t = c / f + m`, estimates approximately 59k frequency-scaled
   cycles plus 0.54 ms of fixed time per batched ciphertext (about 65% of
   time at 200 MHz). For single requests, the estimates are approximately
   240k cycles plus 5.5 ms. The report attributes the fixed component to
   streaming BSK/KSK from DDR, reading approximately 101 MB per PBS batch.
   The measurements indicate key bandwidth as the current bottleneck,
   ahead of NTT compute. Priorities are larger on-chip BSK/KSK caches,
   reuse across batches, and recipient-grouped scheduling before higher
   clocks or additional PEs.
3. **OSig averages 214k cycles per ciphertext versus 167k in the
   microbenchmark.** Each pertinency AND-chain round has ten ciphertexts
   per recipient. With groups of eight, this becomes 8 + 2, leaving the
   final group only one-quarter occupied. Rectification and filtering
   submit larger groups (160 and 20 ciphertexts); rectification fills
   groups of eight, while filtering still has a partial final group.
   Combining work across rounds or recipients may improve utilization,
   subject to key-slot constraints: changing recipients changes keys.
4. **Host overhead is visible.** For batches of 32, round-trip time exceeds
   hardware time by approximately 0.55–0.60 ms per ciphertext, including
   two 16 KB TCP transfers, XRT synchronization, and server copies. With
   hardware time around 0.83 ms at 200 MHz, this is approximately 40% of
   round-trip time. Board utilization drops from 75% to 69%; host packing,
   accumulation, and queueing leave gaps between board operations.

### 5. CMA Configuration

The ten recipients' keys occupy approximately 1 GB. For this board setup,
set **`cma=1536M` in `uEnv.txt`**. CMA must fit within the lower 2 GB region;
a 2 GB command-line CMA allocation is not supported in this configuration.

### 6. Planned Optimizations

- **Key caching:** Expand on-chip BSK/KSK caching and reuse keys across
  batches to reduce DDR traffic. *(Superseded on Oct 28: the 23 GB/s figure
  came from the additive model. The measured key stream is 101 MB in about
  6.6 ms, roughly 15 GB/s, and for batches of 12 or more ciphertexts the
  bottleneck is NTT throughput, not key bandwidth.)*
- **Batch scheduling:** Merge compatible work into fuller batches and
  group by recipient/key to reduce partially occupied batches.
- **NTT core and compute scaling:** Evaluate NTT acceleration with AIE and
  an additional PE after addressing the key-bandwidth bottleneck.

The results above summarize the supplied Oct 27 report. Referenced logs and
build artifacts remain in the local project; this update adds only README
content. Earlier dated measurements are retained below as historical snapshots.

## Oct 26, 2026 — On-Board PBS Validation

The HPU implementation now runs successfully on the VCK190 board.
**On-board PBS testing now covers MsgOnly (`gid 1`) and BwAnd (`gid 7`),
with single-ciphertext CPU/FPGA measurements for both paths.**
The initial MsgOnly validation run confirmed
correct decrypted outputs and ciphertext reuse through a subsequent PBS.
The initial validation results and the subsequent same-day performance
comparison are recorded below.

### Test Setup

| Item | Configuration |
| --- | --- |
| Board | VCK190 |
| Platform | `xilinx_vck190_base_202510_1` |
| SD card image | `build_kernel/package/sd_card.img` |
| Image hash record | `build_kernel/BUILD_STATUS.json` in the build workspace |
| Connection | Direct Ethernet connection between Ubuntu host and board |
| Host interface | `eno2`, `192.168.50.1/24` |
| Board interface | `end0`, `192.168.50.2/24` |

The board network interface is `end0`. The image and build status paths refer
to local build artifacts; they are not included in this README-only repository.

### Validation Results

| Test | Result |
| --- | --- |
| Network ping | 0% packet loss; RTT approximately 0.17 ms |
| `hpu-client ping` | `MAGIC=0x4850554d VERSION=1 ERROR=0` |
| `load-keys` | 4 × BSK + 4 × KSK + 3 LUTs; `KEYS_COMMIT status=0`; approximately 1.6 s |
| `run-testvec` — MsgOnly, `gid 1` | 10/10 test cases completed with `status=0` |
| `verify_hw_outputs.sh` | `HW_VERIFY pass=10 fail=0` |
| Ciphertext reuse — cases 2, 3, and 7 | Outputs passed through another PBS; 3/3 `VERIFY_PASS` |

In the ciphertext reuse checks, the raw decrypted values returned close to
the ideal encoding, consistent with noise refresh.

### Measured Performance

| Measurement | Result |
| --- | --- |
| Hardware cycles per PBS | Approximately 788,000–791,000 cycles |
| Hardware execution time at 100 MHz | Approximately 7.9 ms per PBS |
| TCP round-trip time | Approximately 8.2–8.3 ms |
| Simulation reference | 565,645 cycles per PBS |

The board run took approximately 224,000 more cycles per PBS than simulation.
The test notes attribute this overhead to real DDR read latency for BSK/KSK;
the simulation uses an ideal AXI memory model.

### Validation Milestone

The initial MsgOnly run met the Phase A acceptance criteria: correct decrypted
results and reusable output ciphertexts. Phase A permits execution slower than
the CPU. The subsequent same-day measurements below add BwAnd testing and a
CPU comparison, showing a single-ciphertext latency improvement on both paths.

### CPU vs. FPGA: Single-Ciphertext KS+PBS

Both implementations use the same keys and parameter set:
`param_msg2_carry2_pfail128_132b_tuniform_144a47`
(`N=2048`, `k=1`, `LWE_K=879`, PBS decomposition `23/1`, KS decomposition
`2/8`, KS32).
The two OSig paths are MsgOnly rectification (`gid 1`) and BwAnd correlation
AND (`gid 7`). **Each measurement processes one ciphertext through one KS+PBS
operation, without batching.**

#### Performance Comparison

| Path | FPGA hardware cycles, median (range; samples) | FPGA hardware time | Client TCP round trip (range) | CPU tfhe-rs time, median (range; samples) | Speedup: hardware / round trip |
| --- | --- | --- | --- | --- | --- |
| MsgOnly | 789,105 (786,508–791,659; n=30) | 7.89 ms | 8.23 ms (8.15–8.27) | 15.06 ms (14.83–17.07; n=50) | 1.91× / 1.83× |
| BwAnd | 789,297 (787,356–791,469; n=48) | 7.89 ms | 8.22 ms (8.15–8.27) | 15.01 ms (14.87–15.28; n=50) | 1.90× / 1.82× |

Hardware speedup is CPU median latency divided by FPGA hardware latency;
round-trip speedup is CPU median latency divided by client TCP round-trip
latency. Ranges are observed minimum–maximum values. Speedups are reproduced
from the supplied benchmark summary. For BwAnd, the displayed rounded times
(`15.01 / 8.22`) give approximately 1.83×, while the unrounded medians in the
raw files (`15.005292 ms / 8.2225 ms`, `perf_cpu.json` and
`perf_fpga/summary.json`) give 1.825×, which rounds to the reported 1.82×.

#### Platform and Overhead

| Item | Value |
| --- | --- |
| FPGA clock | 100 MHz; VCK190; `xilinx_vck190_base_202510_1`; kernel connected to `clk_out2` |
| XSim reference, ideal AXI memory model | 565,645 cycles |
| Additional on-board cycles | Approximately 224,000; attributed to real DDR reads of BSK/KSK |
| Round-trip overhead beyond hardware execution | 0.27–0.38 ms: TCP transfer of a 16 KB ciphertext in each direction, XRT register polling, and DDR writes/readback |
| Idle ping, register readback only | 8–20 µs, measured on the server; distinct from network ping RTT |
| CPU baseline | Intel Core i9-14900K, single thread, tfhe-rs 1.8.1 shortint KS32, x86 FFT backend |

The two FPGA paths have nearly identical cycle counts: changing LUT contents
changes the GLWE table but not the number of cycles in the PBS datapath.
The CPU paths likewise use the same KS+PBS flow through `message_extract`
and `apply_lookup_table`.

#### Measurement Method

- **FPGA:** Run `hpu-client run-testvec` for three rounds per path: 10 MsgOnly
  cases × 3 (30 samples) and 16 BwAnd cases × 3 (48 samples). Read hardware
  cycles from `LAST_PBS_CYCLES` at `0xA8`, counting from `PBS_F` dispatch to
  ACK, including KS and DDR reads of BSK/KSK. The Ubuntu client measures
  elapsed time around each TCP request. Raw results are in
  `build_kernel/perf_fpga/msgonly_runs.txt` and
  `build_kernel/perf_fpga/bwand_runs.txt`; the summary is in
  `build_kernel/perf_fpga/summary.json`.
- **CPU:** Run `hpu_key_tool bench-cpu keys 50` with the same client/server
  keys used for the board tests, stored under `host_private/`. After three
  warm-up iterations, time 50 iterations per path. MsgOnly calls
  `ServerKey::message_extract`; BwAnd calls `apply_lookup_table` with LUT
  `(x >> 2) & (x & 3)`. Decrypt and check the results after timing.
  Raw results are in `build_kernel/perf_cpu.json`.

These paths identify local benchmark artifacts; the data files and keys are
not included in this README-only update.

#### Interpretation

- At 100 MHz, the minimal single-PBS kernel achieves approximately **1.8×
  end-to-end speedup** over the single-threaded desktop CPU baseline
  (CPU time / FPGA round-trip time). This exceeds the correctness-only
  Phase A acceptance requirement.
- This measurement does not represent the full HPU's intended operating
  point. The full HPU targets higher clocks and pipelined batches of 8–16
  PBS operations (`PEP_BATCH_bpbs8_tpbs16`). This kernel uses a batch depth
  of one, leaving much of the pipeline underutilized. The potential benefit
  of batching must be established with throughput measurements.
- The CPU baseline is also single-threaded. tfhe-rs can process multiple
  ciphertexts in parallel with Rayon, and the i9-14900K has 32 logical
  processors. Parallel OSig workloads can reduce amortized CPU time per
  ciphertext. **This table compares single-ciphertext latency, not system
  throughput.**
- The approximately 224,000 extra cycles relative to ideal-memory simulation
  identify DDR access as a major optimization target. Candidates include
  BSK/KSK caching, prefetching, or placing BSK in closer memory.

#### Next Measurements

1. **Batch throughput:** Submit multiple `PBS_F` commands through the register
   FIFO and measure amortized time per ciphertext.
2. **Higher clock rates:** The reported post-route WNS for `hpu_mini` is
   +0.55 ns at 100 MHz. Try relinking at 150–200 MHz and recheck timing and
   correctness; the current timing result does not establish closure at
   those higher frequencies.
3. **CPU parallel throughput:** Process N ciphertexts using Rayon and report
   amortized time per ciphertext as a corresponding throughput baseline.

## Oct 15, 2026 — Synthesis Resource Snapshot

This snapshot summarizes `hpu_hierarchy.rpt` for the Oct 15 progress update.
**Oct 15 is the reporting milestone; the original report was generated on
September 29, 2026, at 17:19:58.**

### Report Context

| Item | Value |
| --- | --- |
| Source report | `hpu_hierarchy.rpt` |
| Tool | Vivado 2025.1 (lin64), build 6140274 |
| Top-level design | `hpu_3parts` |
| Target device | `xcvc1902-vsva2197-2MP-e-S` |
| Design state | Synthesized |
| Report command | `report_utilization -hierarchical -hierarchical_depth 6` |

### Overall Resource Usage

| Resource | Used |
| --- | ---: |
| Total LUTs | 391,188 |
| Logic LUTs | 359,118 |
| LUTRAMs | 8,422 |
| SRLs | 23,648 |
| Flip-flops | 670,663 |
| RAMB36 | 688 |
| RAMB18 | 34 |
| URAM | 98 |
| DSP blocks | 1,161 |

Total LUTs include logic LUTs, LUTRAMs, and SRLs. Block RAM usage corresponds
to **705 equivalent 36 Kb tiles**, calculated as `688 + 34 / 2`.

### Top-Level Hierarchy Breakdown

Core rows include their descendants. Values are transcribed from the source
report, with the reported design total shown separately.

| Instance | Total LUTs | Logic LUTs | LUTRAMs | SRLs | FFs | RAMB36 | RAMB18 | URAM | DSP blocks |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Direct top-level logic | 10 | 10 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `hpu_3parts_1in3_core` | 139,001 | 123,036 | 5,514 | 10,451 | 258,001 | 484 | 34 | 96 | 7 |
| `hpu_3parts_2in3_core` | 125,577 | 122,177 | 192 | 3,208 | 183,233 | 76 | 0 | 2 | 578 |
| `hpu_3parts_3in3_core` | 126,545 | 113,844 | 2,716 | 9,985 | 214,392 | 128 | 0 | 0 | 576 |
| `p1_p2_sll` | 2 | 2 | 0 | 0 | 1,658 | 0 | 0 | 0 | 0 |
| `p2_p1_sll` | 2 | 2 | 0 | 0 | 4,184 | 0 | 0 | 0 | 0 |
| `p2_p3_sll` | 2 | 2 | 0 | 0 | 4,748 | 0 | 0 | 0 | 0 |
| `p3_p2_sll` | 2 | 2 | 0 | 0 | 4,312 | 0 | 0 | 0 | 0 |
| **Reported design total** | 391,188 | 359,118 | 8,422 | 23,648 | 670,663 | 688 | 34 | 98 | 1,161 |

The displayed child rows sum to 391,141 LUTs and 670,528 FFs, which are
47 LUTs (43 logic LUTs and 4 SRLs) and 135 FFs below the reported design total.
The original values are preserved; the overall figures above use the report's
top-level row rather than a sum of child rows.

### Progress Summary

- A synthesized resource snapshot is available for the three-core `hpu_3parts` design.
- Core 1 contains most of the block RAM and URAM: 484 RAMB36, 34 RAMB18, and 96 of the design's 98 URAM blocks.
- DSP usage is concentrated in cores 2 and 3: 578 and 576 blocks, respectively, totaling 1,154 of 1,161 DSP blocks.
- The four `sll` instances together account for 8 LUTs and 14,902 flip-flops.

These are synthesis-stage resource counts. This report does not establish
post-route utilization, timing closure, operating frequency, latency,
throughput, or board-level validation.

This update contains only the README. The source `.rpt` is summarized above
and is not included in the repository.
