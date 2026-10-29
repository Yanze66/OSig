#!/usr/bin/env bash
# hpu_mini b32 (PEP_BATCH_bpbs32_tpbs48, 200 MHz): package .xo -> v++ link -> v++ package
set -eo pipefail
ROOT=/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core
KB=/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/build_kernel_b32
mkdir -p "$KB/link" "$KB/package"
cd "$KB"
if [ ! -f "$KB/hpu_mini.xo" ] || [ "${FORCE_XO:-0}" = 1 ]; then
  /tools/Xilinx/2025.1/Vivado/bin/vivado -mode batch -nojournal -log "$KB/package_xo.log" -source "/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/scripts/cfg_b32/package_xo.tcl"
  grep -q XO_READY "$KB/package_xo.log"
fi
source /tools/Xilinx/2025.1/Vitis/settings64.sh
PLATFORM=/tools/Xilinx/2025.1/Vitis/base_platforms/xilinx_vck190_base_202510_1/xilinx_vck190_base_202510_1.xpfm
cd "$KB/link"
v++ --link --target hw --platform "$PLATFORM" --config "/home/yzwu/.codex/visualizations/2026/09/25/01a0da75-f764-71d3-9aa4-62eb17f163fd/vck190_tcp_adder/osig_hpu/step2_pbs_core/scripts/cfg_b32/link.cfg" --save-temps \
  "$KB/hpu_mini.xo" -o "$KB/hpu_mini_hw.xsa" 2>&1 | tee "$KB/link.log"
echo "LINK_DONE"
COMMON_IMAGE=${COMMON_IMAGE:-/home/yzwu/Downloads/xilinx-versal-common-v2025.1_05221048/xilinx-versal-common-v2025.1}
cd "$KB/package"
v++ --package --target hw --platform "$PLATFORM" \
 --package.rootfs "$COMMON_IMAGE/rootfs.ext4" --package.kernel_image "$COMMON_IMAGE/Image" \
 --package.boot_mode sd --package.image_format ext4 \
 --package.sd_file "$ROOT/build_kernel/hpu_server" --package.sd_file "$ROOT/board/run_server.sh" \
 "$KB/hpu_mini_hw.xsa" -o hpu_mini_b32.xclbin 2>&1 | tee "$KB/package.log"
ls -la "$KB/package/hpu_mini_b32.xclbin" "$KB/package/sd_card/BOOT.BIN"
echo "PACKAGE_DONE"
