# hpu_mini DDR 内存布局规格（step2）

配置：N=2048, GLWE_K=1, LWE_K=879, PBS 23/1, KS 2/8 (KS32, MOD_KSK_W=21),
GF64 NTT (R=2, PSI=16, rdx cut [5,5,1]), BSK/KSK CUT=16 SLOT=8, KSLB x2y32z3,
AXI 256-bit, PC: pem1_glwe1_bsk4_ksk4, PEP_BATCH bpbs8_tpbs16, REGF reg64_coef32_seq4。
所有地址为字节地址，数据为小端 u64。

## 权威来源
- 字节级地址公式：RTL + 各 testbench（子代理分析报告，见 git 外部记录）。
- 主机侧生成：tfhe 1.8.1 `src/core_crypto/hpu/entities/*`（官方转换代码）+
  tfhe-hpu-backend 0.7.0 `src/entities/*`（按 PC 分块容器）。
  工具 `tools/hpu_key_tool` 直接调用官方转换，不重实现。

## 速查表
| 对象 | 地址 | 说明 |
|---|---|---|
| BSK（PC q=0..3）| `bsk_addr[q] + k*0x4000 + j*0x2000 + (2t+l)*0x40 + f_local*8` | k=br_loop(0..878), j=GLWE 列(0..1), t=stg_iter(0..63), l=GGSW 行(0..1), f_local=0..7；系数为 GF64 NTT 域 u64，多项式序=bsk_order([5,5,1])+bitrev（官方 shuffle_gf64）。每 PC 13.73 MiB |
| KSK（PC q=0..3）| `ksk_addr[q] + ((((c*2+x)*64+l)*3+lg)*8+yl)*8` | c=ks_loop(0..439), x=0..1（列=2c+x, 879 为 body 列）, l=bline(0..63), lg=0..2, yl=0..7（行=l*32+8q+yl 自然序）；u64=3×21-bit digit（z 槽位 [21z+20:21z]，level 按 tfhe-rs 存储序，第 9 槽=0）。每 PC 10.31 MiB |
| GLWE LUT | `glwe_addr + gid*0x4000 + 8*j` | 只存 body；**多项式为 radix-2 11 级位反序**（官方 create_hpu_lookuptable 已处理，tb 的"自然序"指已反序内容的流序）。gid: None=0, MsgOnly=1, BwAnd=7（hpu_asm 目录） |
| 密文 BLWE | `ct_addr + cid*0x5000`；mask a[i]@`8i`(0..0x3FFF)，body@`0x4000` | 步距 20480 B（页对齐）；0x4008-0x4FFF 填 0；系数 msb2lsb 在 ct_width=64 时为恒等 |

## 已确认（对照 tfhe 官方代码）
1. BSK 置换方向：`hpu_bsk[流位置] = poly[gf64_order[c_idx]]`，gf64_order=bsk_order(cut)+idx_rev（gather）。
2. KSK digit 顺序：按 tfhe-rs ksk 存储序直取（z=0..7），取值为 MSB 对齐系数 `>>(32-21)`（KS32 为 u32 容器）。
3. KSK 行维（BLWE 输入系数）：自然序。
4. PC 切分：KSK 线性索引按 `lby/ksk_pc=8` 为块轮转 PC；BSK 同理按前端系数 f。
   工具直接落盘 per-PC 容器（`into_container()`），无需自算。

## hpu_mini 控制寄存器（AXI-Lite，见 rtl/hpu_mini.sv）
0x00 MAGIC "HPUM" | 0x04 VERSION | 0x0C STATUS | 0x10 ISSUED | 0x14 ACK_TOTAL |
0x18 DOP_PUSH(WO) | 0x1C ERROR(W1C) | 0x20/24 CT_ADDR | 0x30/34 GLWE_ADDR |
0x38 BPIP_CTRL | 0x3C BPIP_TIMEOUT | 0x40-5C BSK_ADDR[4] | 0x60-7C KSK_ADDR[4] |
0x80 KEY_CTRL(avail/reset 脉冲) | 0x84 KEY_STATUS | 0x90-9C 各 PE ACK 计数 |
0xA0 本地 ACK | 0xA8 上次 PBS 周期数 | 0xB0/B4 自由计数器

## DOp 编码（hpu_common_instruction_pkg）
- LD: {6'b10_0000, cid[16], mode[2], pad, rid[7]}
- ST: {6'b10_0001, cid[16], mode[2], pad, rid[7]}
- PBS(带 flush): {2'b11, flush=1, pad, log_lut_nb[2], gid[12], src_rid[7], dst_rid[7]}
- 执行序（单次 rectification）：LD r0,cid → PBS_F r1,r0,gid=1 → ST r1,cid' → 轮询 ACK 计数

## 调试记录（A3，10-26）
- X 污染根因：单体 pe_pbs 的 ks_boram_data 信号仍为 12 位（LWE_COEF_W），KS 新接口输出 21 位
  （MOD_KSK_W）body。已在补丁副本中修复（pe_pbs.sv + entry_assembly 的口宽）。
- DEF_INIT_RAM 宏：官方仿真流程定义它把行为 RAM 初始化为固定图案，仿真必加（run_xsim.tcl 已加）。
- 官方对拍通路已打通：sw/bin/tfhe-rs/v2.9 的 hpu_mockup + hpu_bench --io-dump，
  配置由 gen_hpu_config.py / gen_hpu_mockup_config.py 以我们的 psi16/bsk4_ksk4/bpbs8_tpbs16 参数生成，
  产出 mockup_run/ucode/{key,glwe,blwe,dop}。零噪声密钥，对拍确定性。
- 勘误：先前用 keyswitch_lwe_ciphertext_with_scalar_change 做的"CPU KS 参考"与 HW KS
  语义可能不同（分解域不同），其不匹配不构成 KSK 布局错误的证据。
- KSK 结构特征（官方 vs 本工具,各 9600 u64）：bit63 恒 0、lg=2 的 z2 槽恒 0、其余槽非零——完全一致。

## 根因（10-26）：大 LWE 维的序约定
- 黄金对拍（官方 mockup+bench 数据驱动 hpu_mini）位真匹配 → RTL/装配/控制面全部正确。
- 零噪声密钥神谕（scripts/ksk_oracle.py、hpu_key_tool bsk-oracle/bsk-diagnose）：
  * KSK 布局/digit 权重 2^(5+2d)：官方与本工具一致。
  * LUT：官方与本工具逐字相同。
  * BSK：本工具的 BSK 在 tfhe 1.8.1 的 GF64 逆重排下自洽；官方 BSK 仅当 GLWE 密钥系数取
    **11 位位反序**（s_poly[y] = s_big_ksk[rev11(y)]）时自洽。
- 结论：本 RTL 快照（及 v2.9 mockup）约定硬件侧 BLWE 的系数序 = GLWE 多项式序的位反序；
  tfhe 1.8.1 的 HPU 代码（"FPGA outputs natural order"）对应更新一代 RTL。
- 修法（hpu_key_tool）：KSK 输入维度块按 rev11 重排（HW 行 y ← tfhe 行 rev11(y)）；
  密文送入前 mask[y] ← cpu_mask[rev11(y)]，读回后反向；BSK、LUT 不变。
- 平凡输入（mask=0, body=5·2^59）测试：输出 mask 全 0、body = 1·2^59，解码 1 = MsgOnly(5)。
