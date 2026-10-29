#!/usr/bin/env bash
# Wait for the link chain, then package the SD image and summarize.
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# -x: match the whole command line, so a shell whose command text merely contains this
# script's name (e.g. the heredoc that created it) does not keep us waiting forever.
while pgrep -x -f "bash scripts/build_kernel.sh" >/dev/null || pgrep -f "v\+\+ .*-l.*hpu_mini" >/dev/null; do sleep 60; done
if grep -q LINK_DONE "$ROOT/build_kernel/driver.log" && [ -f "$ROOT/build_kernel/hpu_mini_hw.xsa" ]; then
  bash "$ROOT/scripts/package_sd.sh" > "$ROOT/build_kernel/package_driver.log" 2>&1 || echo "PACKAGE_FAILED"
fi
python3 -I "$ROOT/scripts/build_status.py"
echo "AFTER_LINK_DONE"
