#!/usr/bin/env bash
# 1) package hpu_mini as a user-managed RTL kernel (.xo), 2) v++ link into the VCK190 base platform
set -eo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$ROOT/build_kernel/link"
cd "$ROOT/build_kernel"
if [ ! -f "$ROOT/build_kernel/hpu_mini.xo" ] || [ "${FORCE_XO:-0}" = 1 ]; then
  /tools/Xilinx/2025.1/Vivado/bin/vivado -mode batch -nojournal -log package_xo.log -source "$ROOT/scripts/package_xo.tcl"
  grep -q XO_READY package_xo.log
fi
source /tools/Xilinx/2025.1/Vitis/settings64.sh
PLATFORM=/tools/Xilinx/2025.1/Vitis/base_platforms/xilinx_vck190_base_202510_1/xilinx_vck190_base_202510_1.xpfm
cd "$ROOT/build_kernel/link"
v++ --link --target hw --platform "$PLATFORM" --config "$ROOT/scripts/link.cfg" --save-temps \
  "$ROOT/build_kernel/hpu_mini.xo" -o "$ROOT/build_kernel/hpu_mini_hw.xsa" 2>&1 | tee "$ROOT/build_kernel/link.log"
echo "LINK_DONE"
