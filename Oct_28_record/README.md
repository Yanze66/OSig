# Oct 28, 2026 record — hpu_mini on VCK190 for OSig: artifacts and reproduction

This folder is a self-contained snapshot of everything needed to reproduce the
measurements reported in the top-level README up to Oct 28, 2026: the three
200 MHz FPGA images (hardware batch depth 8, 16 and 32), the board-side server,
the host-side programs, the keys and test vectors, the raw measurement files
and the working documents. The system architecture is described in
[ARCHITECTURE.md](ARCHITECTURE.md).

## 1. Contents

| Path | What it is |
| --- | --- |
| `images/` | `BOOT_200.BIN` + `hpu_mini_200.xclbin` (depth 8, `bpbs8_tpbs16`), `BOOT_b16.BIN` + `hpu_mini_b16.xclbin` (`bpbs16_tpbs32`), `BOOT_b32.BIN` + `hpu_mini_b32.xclbin` (`bpbs32_tpbs48`), all at 200 MHz; `uEnv.txt` (CMA 1536 MB); `SHA256SUMS`. BOOT.BIN and xclbin of one image always go together (flat platform, see §3). |
| `board/` | `server.cpp` — the board program (`hpu_server`, XRT native API, TCP front end); `hpu_server` — its AArch64 build (Oct 28 version: `BPIP_TIMEOUT` 1,000,000, command 10 `REG_WRITE`); `run_server.sh`, `uEnv.txt`, `build_board.sh` (cross-compile with the PetaLinux 2025.1 SDK). |
| `host/hpu-client/` | Rust (std only) test client: `ping`, `reg-write`, `load-keys`, `pbs`, `run-testvec`, `run-testvec-batch`. |
| `host/hpu_key_tool/` | Rust tool (tfhe-rs 1.8.1 + tfhe-hpu-backend 0.7.0): key generation and conversion to the board DDR layout, LUT images, test vectors, decryption check (`verify`), CPU reference benchmark (`bench-cpu`). |
| `host/obsig-tfhe/` | The OSig prototype (Alg1–Alg5) with the FPGA back end (`src/fpga.rs`, `--fpga ip:port`). |
| `host/bin/` | x86-64 release builds of the three programs above (Ubuntu 24.04, glibc). |
| `host/scripts/verify_hw_outputs.sh` | Decrypts `hw_out_case*.hex` with `hpu_key_tool verify` and compares with `expected.json`. |
| `kernel/` | `rtl/` (hpu_mini top, Vitis wrapper, test bench, patched `pe_pbs`, generated `pep_batch` packages), `kernel.xml` (user-managed kernel description with pointer arguments), `scripts/` (`gen_cfg_flow.py`, generated `cfg_b16/`, `cfg_b32/`, the 100/200 MHz depth-8 flow, XSim script). The Zama HPU RTL itself is not included (see §6). |
| `keys/` | Board key images used by all step2 measurements: `bsk_pc0..3.bin` (4 × 14,401,536 B), `ksk_pc0..3.bin` (4 × 10,813,440 B), `lut/*.bin`, `testvec/` (MsgOnly, 10 cases), `testvec_bwand/` (BwAnd, 16 cases), `host_private/` (the matching tfhe-rs client key and compressed server key, test keys only). |
| `data/perf/` | Raw per-request measurements: `100mhz_bpbs8/`, `200mhz_bpbs8/`, `200mhz_b16/`, `200mhz_b32/` (+ `old_timeout10k/`, the pre-fix b32 data), `100mhz_single/` (Oct 26 single-PBS runs, `summary.json`, `perf_cpu.json`). |
| `data/logs/` | OSig logs: `cpu_baseline.log`, `fpga_bench_r10_{100mhz,200mhz,b16,b32}*.log`, `fpga_verify_r4*.log`, `cpu_verify_r4.log`. |
| `data/docs/` | Working documents (Chinese): `PERF_BATCH.md` (all batch measurements and the performance model), `DEPLOY.md` (board procedure, key slots, CMA, image swap, server update), `memory_layout.md` (DDR layouts and register map), `OSIG_FPGA_VS_CPU.md` (OSig comparison). |

## 2. Hardware and software used

| Item | Value |
| --- | --- |
| Board | AMD VCK190 (`xcvc1902-vsva2197-2MP-e-S`), platform `xilinx_vck190_base_202510_1` (flat, non-DFX), PetaLinux 2025.1 on the SD card, XRT native API (`xrt::ip`, user-managed kernel). |
| Host | Ubuntu 24.04, Intel Core i9-14900K (24C/32T), Rust stable (edition 2024 needed by `obsig-tfhe`), tfhe-rs `=1.8.1`, tfhe-hpu-backend `=0.7.0`. |
| Link | Direct Gigabit Ethernet: host `eno2` 192.168.50.1/24, board `end0` 192.168.50.2/24, TCP port 5002. |
| Tools for rebuilding the FPGA image | Vivado/Vitis 2025.1, the Zama `hpu_fpga` RTL snapshot (July 2026), Python 3 with jinja2 for the batch package generator. |
| TFHE parameters | `v1_4_hpu_879_ks32_tuniform_2m128` / `param_msg2_carry2_pfail128_132b_tuniform_144a47`: N=2048, k=1, LWE 879, PBS decomposition 23/1, KS decomposition 2/8, KS32. |

## 3. Board setup

1. Flash the base-platform SD image once (the Vitis package output `sd_card.img`; not included here because it is 1+ GB and identical except for BOOT.BIN/xclbin). Put `images/uEnv.txt` on the boot partition so the kernel command line contains `cma=1536M` (ten recipients' keys need about 1 GB of CMA; a 2 GB value does not boot).
2. Choose an image and copy both files of it. The VCK190 base platform is flat: `load_xclbin` at run time only loads metadata, the PL bitstream comes from the PDI inside `BOOT.BIN` on the boot partition. Changing the kernel (clock or batch depth) therefore always means replacing `BOOT.BIN` and rebooting; the xclbin must be from the same build (XRT then logs "already downloaded").
   On the board (serial console), with the files served by `python3 -m http.server 8000 --bind 192.168.50.1` from `images/` on the host:
   ```sh
   cp /run/media/mmcblk0p1/BOOT.BIN /run/media/mmcblk0p1/BOOT.prev
   wget http://192.168.50.1:8000/BOOT_b16.BIN -O /run/media/mmcblk0p1/BOOT.BIN
   mkdir -p ~/hpu && wget http://192.168.50.1:8000/hpu_mini_b16.xclbin -O ~/hpu/hpu_mini.xclbin
   sync && reboot
   ```
3. After the reboot, set the address (lost on every boot) and start the server:
   ```sh
   ip link set end0 up && ip addr add 192.168.50.2/24 dev end0
   cd ~/hpu && ./hpu_server ./hpu_mini.xclbin 5002
   ```
   Expected output: `hpu_mini MAGIC ok, VERSION=1 ... key_slots=16` and `HPU_SERVER_READY port=5002`. `grep -i cma /proc/meminfo` should show `CmaTotal: 1572864 kB`.
4. To update only the server program (no reboot): stop it, `wget http://192.168.50.1:8000/hpu_server -O ~/hpu/hpu_server && chmod +x ~/hpu/hpu_server`, start it again. The server binary in `board/` is the Oct 28 version; a `ping` from the host must show `reg 0x3c = 0x000f4240` (1,000,000-cycle batch timeout). Older servers (timeout 10,000 cycles) split 32-ciphertext requests into two batches on the b32 image.

## 4. Host-side reproduction

All commands below run on the Ubuntu host from this folder. Use the prebuilt
binaries in `host/bin/` or rebuild them (`cargo build --release` in
`host/hpu-client`, `host/hpu_key_tool`, `host/obsig-tfhe`; the latter two
download tfhe-rs from crates.io).

```bash
export R=$(pwd)                 # this Oct_28_record folder
export B=192.168.50.2:5002
export C=$R/host/bin/hpu-client
```

### 4.1 Register read-back and clock check

```bash
$C $B ping            # reg 0x00 = 0x4850554d ("HPUM"), reg 0x1c = 0 (no error)
```
Clock: read the free-running 64-bit counter (`0xb4:0xb0`) with two pings two
seconds apart and divide the difference by the wall-clock interval. Measured:
200.25 MHz (depth 8), 199.2 MHz (b16, includes ping latency), 200.36 MHz (b32).

### 4.2 Keys, single-ciphertext tests, batch tests

```bash
$C $B load-keys $R/keys                                   # 8 key parts + 3 LUTs, ~1.6 s, LOAD_KEYS_DONE
# single requests (one KS+PBS per TCP request)
$C $B run-testvec $R/keys/testvec        out/msgonly_single          # gid 1 MsgOnly, 10 cases
$C $B run-testvec $R/keys/testvec_bwand  out/bwand_single 7 bwand    # gid 7 BwAnd, 16 cases
$R/host/scripts/verify_hw_outputs.sh out/msgonly_single                              # HW_VERIFY pass=10 fail=0
$R/host/scripts/verify_hw_outputs.sh out/bwand_single $R/keys/testvec_bwand bwand    # HW_VERIFY pass=16 fail=0
# batched requests: n ciphertexts per request (1..32), 3 repetitions
for n in 8 16 32; do
  $C $B run-testvec-batch $R/keys/testvec out/msgonly_n$n 1 msgonly $n 3 | tee out/msgonly_n$n.txt
  $R/host/scripts/verify_hw_outputs.sh out/msgonly_n$n
done
for n in 16 32; do
  $C $B run-testvec-batch $R/keys/testvec_bwand out/bwand_n$n 7 bwand $n 3 | tee out/bwand_n$n.txt
  $R/host/scripts/verify_hw_outputs.sh out/bwand_n$n $R/keys/testvec_bwand bwand
done
```
Each line printed by `run-testvec-batch` gives `pbs_cycles` (board cycle
counter from the first PBS DOp push to the last PBS acknowledgement),
`per_ct_cycles`, `server_us` (server-side time for the request) and
`round_trip_us` (client-side). `verify_hw_outputs.sh` decrypts every output
with the client key and compares with `expected.json`.

Note: `load-keys` uses key slot 0, and an OSig run overwrites slot 0 with
recipient 0's keys. Run `load-keys` again before step2 tests after any OSig run
(otherwise all decryptions fail while the hardware reports no error).

### 4.3 OSig: CPU baseline, FPGA runs, validation

Run from `host/obsig-tfhe/` (the FPGA back end caches each recipient's key
images under `./wallet/<recipient id>/`). The first run with a new `--run-dir`
generates the wallets and messages and caches them there; later runs reuse
them, so CPU and FPGA runs use identical inputs.

```bash
cd $R/host/obsig-tfhe
../bin/obsig-tfhe --run-dir runs/bench_r10                           # CPU baseline (defaults: G=25, Q=10, R=10, V=4)
../bin/obsig-tfhe --fpga $B --run-dir runs/bench_r10                 # FPGA path, run twice
rm -rf runs/verify_r4/validation
../bin/obsig-tfhe --fpga $B --verify-io -r 4 --run-dir runs/verify_r4   # decrypt-and-compare mode
```
Read `SERVER PROCESSING (Alg4) actual wall time`, the `Alg4.x` worker rows and
`FPGA_STATS` (requests, ciphertexts, total board cycles). The validation run
must print four `FINAL_INBOX_PASS` lines and `OSIG_HPU_CPU_VALIDATION_PASS`.
Key-image upload (`FPGA_KEYS_READY ... upload_s`) is outside the Alg4 timing.

### 4.4 Reference numbers (what a correct reproduction looks like)

| Measurement | depth 8 (200 MHz) | b16 (200 MHz) | b32 (200 MHz) |
| --- | --- | --- | --- |
| Single request, cycles per PBS | 1,337k (6.69 ms) | 1,323k (6.61 ms) | 1,313k (6.56 ms) |
| Request of 8, cycles per ciphertext | 167.5k | 166.9k | 165.7k |
| Request of 16, cycles per ciphertext | 167.0k | 114.0k | 113.7k |
| Request of 32, cycles per ciphertext | 166.4k | 112.8k | 113.5k |
| Round trip per ciphertext, request of 32 | 1.43 ms | 1.15 ms | 1.15 ms |
| OSig Alg4 wall, 10 recipients (CPU 52.71 s) | 22.2–22.5 s (2.35×) | 15.9–16.0 s (3.30×) | 15.7–15.8 s (3.35×) |
| OSig board cycles per ciphertext | 214.2k | 129.5k | 125.0k |
| `verify-io -r 4` | 4/4 pass | 4/4 pass | 4/4 pass |

Per-batch time follows `max(key stream ≈ 1.32M cycles, n × 113.5k cycles)`;
113.5k cycles per ciphertext is the NTT throughput (879 blind-rotation
iterations × 128 cycles for two N=2048 polynomials at 32 coefficients per
cycle). Details and the 100 MHz numbers: `data/docs/PERF_BATCH.md`.

## 5. Regenerating keys and test vectors

```bash
K=$R/host/bin/hpu_key_tool
$K keygen newkeys              # tfhe-rs ClientKey + CompressedServerKey -> bsk_pc*.bin, ksk_pc*.bin, host_private/
$K lut newkeys                 # lut/lut_gid*.bin (gid 0 None, 1 MsgOnly, 5 MultCarryMsgLsb, 7 BwAnd)
$K testvec newkeys newkeys/testvec
$K testvec-bwand newkeys newkeys/testvec_bwand
```
The conversion follows tfhe-rs 1.8.1 / tfhe-hpu-backend 0.7.0 with one
compensation specific to this RTL snapshot: the hardware orders the big-LWE
dimension 11-bit bit-reversed relative to the GLWE polynomial order, so KSK
rows are permuted (`rev11`) and ciphertext masks are bit-reversed on the way
in and out. BSK and LUT layouts are unchanged (`data/docs/memory_layout.md`).

## 6. Rebuilding the FPGA image and the server

The kernel is assembled from unmodified Zama HPU sub-modules
(`hpu_with_pe`, `pe_pbs` and their dependencies, ~360 files from the
`hpu_fpga` repository, July 2026 snapshot, BSD-3-Clause-Clear) plus the files
in `kernel/rtl/`. The repository is not redistributed here; set `HPU_FPGA`
to its `hw/` directory.

1. Batch configuration: the repository ships `PEP_BATCH_bpbs8_tpbs16` and
   `PEP_BATCH_bpbs16_tpbs32`; `kernel/rtl/pep_batch/PEP_BATCH_bpbs32_tpbs48`
   was generated with Zama's `gen_pep_batch_definition_pkg.py -g 4 -c 32 -H 48 -f`.
   Constraints: `GRAM_NB (4)` divides `BATCH_PBS_NB` and `TOTAL_PBS_NB`, and
   `TOTAL_PBS_NB > BATCH_PBS_NB`.
2. Generate a flow: `python3 kernel/scripts/gen_cfg_flow.py --cfg b16 --pep-batch $HPU_FPGA/module/pe_pbs/module/pep_common/PEP_BATCH --freq 200000000 --period 5.0`
   writes `cfg_b16/{clocks.xdc, import_ooc.tcl, import_sim.tcl, package_xo.tcl, link.cfg, build_kernel.sh}`.
   (The generated `cfg_b16/` and `cfg_b32/` are included; their absolute paths
   point at the original workspace and must be adapted.)
3. Optional checks: `import_ooc.tcl` (out-of-context synthesis, utilization),
   `import_sim.tcl` (XSim regression of `tb_hpu_mini` against the golden
   mockup data, prints `VERIFY_PASS` and `BATCH_PBS_NB=...`).
4. `build_kernel.sh`: `package_xo` with `kernel/kernel.xml` (the hand-written
   description with pointer arguments; without it `v++ --link` fails with
   `CFGEN 83-2292 ... invalid port m_axi_pem` because the ten AXI masters
   cannot be bound by `[connectivity] sp=`), then `v++ --link` (all masters to
   DDR, `freqHz=200000000:hpu_mini_1.ap_clk`) and `v++ --package`, giving
   `hpu_mini_<cfg>.xclbin` and `sd_card/BOOT.BIN`. Timing comes from the
   routed report under `link/_x/reports/link/imp/`; the three images close at
   200 MHz with WNS +0.177 / +0.082 / +0.136 ns.
5. Server: `board/build_board.sh` (sources the PetaLinux 2025.1 SDK, links
   `xrt_coreutil`).

## 7. Where each number in the top-level README comes from

| README item | Raw file(s) |
| --- | --- |
| Oct 26 single-PBS table, 100 MHz | `data/perf/100mhz_single/{msgonly_runs,bwand_runs}.txt`, `summary.json`, `perf_cpu.json` |
| Oct 27 batch table, 100 MHz / 200 MHz | `data/perf/100mhz_bpbs8/*.txt`, `data/perf/200mhz_bpbs8/*.txt` |
| Oct 27 OSig table | `data/logs/cpu_baseline.log`, `fpga_bench_r10_100mhz{,_run2}.log`, `fpga_bench_r10_200mhz{,_run2}.log` |
| Oct 28 b16 / b32 batch tables | `data/perf/200mhz_b16/*.txt`, `data/perf/200mhz_b32/*.txt` (`old_timeout10k/` = before the server fix) |
| Oct 28 OSig b16 / b32 rows | `data/logs/fpga_bench_r10_b16_run{1,2}.log`, `fpga_bench_r10_b32_run{1,2}.log`, `fpga_bench_r10_b32_timeout10k.log`, `fpga_verify_r4_{b16,b32}.log` |
| Resource and timing figures | Vivado reports in the build workspace (not included); values transcribed in `data/docs/DEPLOY.md` and `PERF_BATCH.md` |
