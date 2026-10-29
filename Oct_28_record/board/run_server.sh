#!/bin/sh
# On the VCK190: copy xclbin + server from the boot partition and start the service on TCP 5002
set -e
SRC=$(dirname "$(find /run/media /media /mnt -name hpu_mini.xclbin 2>/dev/null | head -1)")
mkdir -p ~/hpu && cp "$SRC/hpu_mini.xclbin" "$SRC/hpu_server" ~/hpu/ && chmod +x ~/hpu/hpu_server
cd ~/hpu && exec ./hpu_server ./hpu_mini.xclbin 5002
