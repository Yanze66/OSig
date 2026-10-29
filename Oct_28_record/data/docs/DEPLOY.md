# hpu_mini 上板部署与验收（A4 / 第二次上板闸门）

## 产物
- build_kernel/hpu_mini.xo            user-managed RTL 内核（顶层 hpu_mini_krnl → hpu_mini）
- build_kernel/hpu_mini_hw.xsa        v++ 链接结果（10 个 AXI 主口全部接平台 DDR，ap_clk 100 MHz）
- build_kernel/package/sd_card.img    SD 启动镜像（含 hpu_mini.xclbin、hpu_server、run_server.sh）
- build_kernel/hpu_server             板上服务（AArch64，XRT native API，xrt::ip 用户管理内核）
- host/target/release/hpu-client      Ubuntu 侧客户端（纯 std Rust）
- keys/                               bsk_pc0..3.bin、ksk_pc0..3.bin、lut/*.bin、testvec/*.bin（位反序约定已补偿）

## 协议（TCP 5002）
请求头 40 B（大端）：`HPQ1` id cmd len arg0 arg1 digest(FNV-1a)；回复头 40 B：`HPR1` id status len hw_cycles us digest。
cmd：1 PING，2 KEY_BSK(pc)，3 KEY_KSK(pc)，4 LUT(gid)，5 KEYS_COMMIT，6 PBS(gid)（16392 B 密文进出），7 RESET_CACHE，8 REGDUMP。
密钥上传后驻留板上 DDR；每次 PBS 走 LD r2 ← slot0 → PBS_F r4 ← r2 → ST slot1 ← r4，逐步轮询 ACK 计数。

## 板上步骤
1. 备用 SD 卡烧录 `build_kernel/package/sd_card.img`（整盘镜像），断电换卡启动，串口登录。
2. `ip -br addr` 记下板卡 IP。
3. 启动服务（自动从启动分区拷贝文件）：
   ```sh
   sh /run/media/mmcblk0p1/run_server.sh
   ```
   期望看到 `hpu_mini MAGIC ok ...` 和 `HPU_SERVER_READY port=5002`。MAGIC 不对说明 xclbin 没加载到预期内核。

## Ubuntu 步骤
```bash
export STEP2=~/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core
export BOARD=192.168.50.2:5002   # 换成实际 IP
$STEP2/host/target/release/hpu-client $BOARD ping                      # 寄存器读回，MAGIC=0x4850554d
$STEP2/host/target/release/hpu-client $BOARD load-keys $STEP2/keys     # 上传 ~100 MB 密钥 + LUT，提交
$STEP2/host/target/release/hpu-client $BOARD run-testvec $STEP2/keys/testvec $STEP2/build_kernel/hw_out
$STEP2/scripts/verify_hw_outputs.sh $STEP2/build_kernel/hw_out         # 解密比对 expected.json
# BwAnd（gid 7，相关性 AND）：16 个 (a,b) 组合，打包密文 = ct_a*4 + ct_b
$STEP2/host/target/release/hpu-client $BOARD run-testvec $STEP2/keys/testvec_bwand $STEP2/build_kernel/hw_out_bwand 7 bwand
$STEP2/scripts/verify_hw_outputs.sh $STEP2/build_kernel/hw_out_bwand $STEP2/keys/testvec_bwand bwand
```
验收：MsgOnly `HW_VERIFY pass=10 fail=0`，BwAnd `HW_VERIFY pass=16 fail=0`。每个用例打印硬件周期数（LAST_PBS_CYCLES，仿真约 565k，板上实测约 789k @100 MHz）和往返微秒。
网络：板上接口名是 `end0`（不是 eth0）。临时地址 `ip addr add 192.168.50.1/24 dev eno2`（Ubuntu）、`ip addr add 192.168.50.2/24 dev end0`（板子串口），重启后需重加。

## 故障定位
- status 3（硬件错误）：回复体是寄存器 dump，看 0x1C ERROR 和各 ACK 计数；LD 不 ack 多为 DDR 地址/NoC 映射问题。
- PBS 超时：BSK/KSK 地址寄存器或 KEY_CTRL avail 未置；先 `ping` 看 KEY_STATUS。
- 解密错但硬件无错：对照仿真 keys_flat 数据路径，密钥文件需用修复后的工具生成（manifest.json 日期 ≥ 10-26）。

## 2026-10-27 补充：密钥槽、批量命令、CMA、换时钟

协议新增：cmd 2/3 的 arg1 = 密钥槽号（0..15），cmd 5 KEYS_COMMIT(slot)，cmd 6 PBS 与 cmd 9 PBS_BATCH 的 arg0 = gid | slot<<16，
cmd 9 的 arg1 = 密文个数（≤32，密文按 16392 B 连续排在请求体里）。server 启动打印 `key_slots=16`。
切槽时 server 重写 BSK/KSK 地址寄存器并复位两个缓存（KEY_CTRL 置 bit8 与 bit10；bit9 不是 KSK 复位），轮询 KEY_STATUS 低两位。
OSig（step3）把第 i 个接收者放到槽 i；`hpu-client load-keys` 固定用槽 0，OSig 跑过之后要重新 load-keys 才能再测 step2 向量。

板上内存：10 个接收者的密钥约 1 GB，默认 CMA 不够。启动分区放 `uEnv.txt`（board/uEnv.txt）：
`bootargs=... cma=1536M`（命令行 CMA 必须落在低 2 GB 区域，2048M 和 @32G 都失败）。开机后 `grep -i cma /proc/meminfo` 应显示 CmaTotal 1572864 kB。

换时钟（或任何改 PL 的重链接）：VCK190 base 是 flat（非 DFX）平台，运行时 `load_xclbin` 只换元数据，PL 来自启动分区 BOOT.BIN 的 PDI。
所以必须同时换 BOOT.BIN 与 xclbin（同一次 package 产出，UUID 一致）：
```sh
cp /run/media/mmcblk0p1/BOOT.BIN /run/media/mmcblk0p1/BOOT_100.BIN
wget http://192.168.50.1:8000/BOOT_200.BIN -O /run/media/mmcblk0p1/BOOT.BIN && sync && reboot
```
重启后 server 加载 xclbin 时 drm 日志应为 "already downloaded"（UUID 匹配）；只换 xclbin 不换 BOOT.BIN 时会打印 "successfully loaded" 但 PL 仍是旧的。
核实方法：`hpu-client ping` 两次间隔 2 s，比较 0xB0/0xB4 的 CYCLE 计数差除以墙钟（200 MHz 镜像实测 200.25 MHz）。
200 MHz 产物：build_kernel_200/package/{hpu_mini_200.xclbin, sd_card/BOOT.BIN}，布线 WNS +0.177 ns。
HTTP 分发目录：build_kernel/deploy/（`python3 -m http.server 8000 --bind 192.168.50.1`），内含 hpu_server、uEnv.txt、BOOT_100.BIN、BOOT_200.BIN、hpu_mini_200.xclbin。

## 2026-10-28 补充：参数化批深镜像（gen_cfg_flow.py）

`scripts/gen_cfg_flow.py --cfg <名字> --pep-batch <PEP_BATCH 目录> [--freq 200000000] [--period 5.0]`
在 `scripts/cfg_<名字>/` 生成整套脚本：clocks.xdc、import_ooc.tcl（OOC 综合到 build_<名字>/）、import_sim.tcl（XSim 回归，`build_<名字>/sim`）、
package_xo.tcl、link.cfg、build_kernel.sh（package .xo → v++ link → v++ package，产物在 `build_kernel_<名字>/package/`）。
批深配置先在仓库 `hw/module/pe_pbs/module/pep_common/PEP_BATCH/` 找，找不到再用 `rtl/pep_batch/<名字>/`（用 Zama 的
`gen_pep_batch_definition_pkg.py -g 4 -c <batch> -H <total> -f` 生成，仓库不改）。约束：GRAM_NB=4 整除 BATCH 与 TOTAL，且 TOTAL > BATCH。

打包必须用手写的 `kernel/kernel.xml`（`package_xo -kernel_xml`，指针参数），否则 v++ link 报 `CFGEN 83-2292 ... invalid port m_axi_pem`，
`[connectivity] sp=` 绑不到 10 个 AXI master。OOC 的 timing 报告显示 "no user specified timing constraints" 是已知现象，看
`build_kernel_<名字>/link/_x/reports/link/imp/impl_1_route_report_timing_summary_0.rpt`。

已构建并放入 deploy/ 的镜像（都是 200 MHz）：

| 名字 | BATCH / TOTAL | BRAM | URAM | 布线 WNS | 文件 |
|---|---|---|---|---|---|
| 200 | 8 / 16 | 56% | 21% | +0.177 ns | BOOT_200.BIN, hpu_mini_200.xclbin |
| b16 | 16 / 32 | 58% | 21% | +0.082 ns | BOOT_b16.BIN, hpu_mini_b16.xclbin |
| b32 | 32 / 48 | 77% | 34% | +0.136 ns | BOOT_b32.BIN, hpu_mini_b32.xclbin |

板上换镜像（以 b16 为例）：
```sh
cp /run/media/mmcblk0p1/BOOT.BIN /run/media/mmcblk0p1/BOOT_200.BIN && wget http://192.168.50.1:8000/BOOT_b16.BIN -O /run/media/mmcblk0p1/BOOT.BIN && wget http://192.168.50.1:8000/hpu_mini_b16.xclbin -O ~/hpu/hpu_mini.xclbin && sync && reboot
```
服务端一条请求最多 32 个密文，bpbs32 下一条满请求正好一个硬件批次。

**server 2026-10-28 版（必须配 b32 用）**：默认 BPIP_TIMEOUT 从 10000 拍改为 1,000,000 拍。旧值 50 µs 比串行推 32 个 DOP_PUSH（每条约 2 µs）还短，
序列器会把 32 个截成 24 + 8 两批（表现为 n≥28 的 pbs_cycles 固定 4.03M）。新增 cmd 10 REG_WRITE（arg0 = 0x38 或 0x3C，arg1 = 值，回 regdump），
regdump/ping 现在也带 0x38/0x3C；客户端 `hpu-client <ip:port> reg-write 0x3c 1000000`。板上更新只需换二进制并重启 server，不用重启板子：
```sh
cd ~/hpu && cp hpu_server hpu_server.old && wget http://192.168.50.1:8000/hpu_server -O hpu_server && chmod +x hpu_server && ./hpu_server ./hpu_mini.xclbin 5002
```
`ping` 回显 `reg 0x3c = 0x000f4240` 即为新版。

批深结论（见 PERF_BATCH.md）：200 MHz 下批深 ≥ 12 已是 NTT 算力瓶颈，b16 与 b32 每密文同为 113.5k 拍；推荐部署 b16。
