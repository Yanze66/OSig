#!/usr/bin/env bash
# v++ link of the existing hpu_mini.xo at 200 MHz into build_kernel_200/ (does not touch build_kernel/)
set -eo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source /tools/Xilinx/2025.1/Vitis/settings64.sh
PLATFORM=/tools/Xilinx/2025.1/Vitis/base_platforms/xilinx_vck190_base_202510_1/xilinx_vck190_base_202510_1.xpfm
mkdir -p "$ROOT/build_kernel_200/link" && cd "$ROOT/build_kernel_200/link"
v++ --link --target hw --platform "$PLATFORM" --config "$ROOT/scripts/link_200.cfg" --save-temps \
  "$ROOT/build_kernel_200/hpu_mini_200.xo" -o "$ROOT/build_kernel_200/hpu_mini_hw_200.xsa" 2>&1 | tee "$ROOT/build_kernel_200/link.log"
echo "LINK200_DONE"
