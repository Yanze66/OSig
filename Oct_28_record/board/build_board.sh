#!/usr/bin/env bash
set -e
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
unset LD_LIBRARY_PATH
source /opt/petalinux/2025.1/environment-setup-cortexa72-cortexa53-amd-linux
mkdir -p "$ROOT/build_kernel"
$CXX -std=c++17 -O2 -Wall -Wextra -Werror -I"$SDKTARGETSYSROOT/usr/include/xrt" \
 "$ROOT/board/server.cpp" -lxrt_coreutil -luuid -pthread -o "$ROOT/build_kernel/hpu_server"
file "$ROOT/build_kernel/hpu_server"
