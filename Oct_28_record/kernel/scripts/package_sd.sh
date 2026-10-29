#!/usr/bin/env bash
# Build the SD card image: VCK190 base platform + hpu_mini xclbin + hpu_server + deploy helper
set -eo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source /tools/Xilinx/2025.1/Vitis/settings64.sh
PLATFORM=/tools/Xilinx/2025.1/Vitis/base_platforms/xilinx_vck190_base_202510_1/xilinx_vck190_base_202510_1.xpfm
COMMON_IMAGE=${COMMON_IMAGE:-/home/yzwu/Downloads/xilinx-versal-common-v2025.1_05221048/xilinx-versal-common-v2025.1}
for f in "$COMMON_IMAGE/Image" "$COMMON_IMAGE/rootfs.ext4" "$ROOT/build_kernel/hpu_server" "$ROOT/build_kernel/hpu_mini_hw.xsa"; do
  test -f "$f" || { echo "Missing: $f" >&2; exit 1; }
done
mkdir -p "$ROOT/build_kernel/package"
cd "$ROOT/build_kernel/package"
v++ --package --target hw --platform "$PLATFORM" \
 --package.rootfs "$COMMON_IMAGE/rootfs.ext4" --package.kernel_image "$COMMON_IMAGE/Image" \
 --package.boot_mode sd --package.image_format ext4 \
 --package.sd_file "$ROOT/build_kernel/hpu_server" --package.sd_file "$ROOT/board/run_server.sh" \
 "$ROOT/build_kernel/hpu_mini_hw.xsa" -o hpu_mini.xclbin 2>&1 | tee "$ROOT/build_kernel/package.log"
ls -la "$ROOT/build_kernel/package/sd_card.img" "$ROOT/build_kernel/package/hpu_mini.xclbin"
echo "PACKAGE_DONE"
