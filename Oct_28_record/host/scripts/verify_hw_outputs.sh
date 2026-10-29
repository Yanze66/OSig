#!/usr/bin/env bash
# Decrypt every hw_out_case<N>.hex produced by `hpu-client run-testvec[-batch]` and compare with expected.json.
# usage: verify_hw_outputs.sh <out_dir> [testvec_dir=<record>/keys/testvec] [case_prefix=msgonly]
# Paths are relative to this Oct_28_record folder: keys/ (with host_private/client_key.bin) and host/bin/hpu_key_tool.
# Override with KEYS_DIR / HPU_KEY_TOOL.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
OUT=${1:?usage: verify_hw_outputs.sh <out_dir> [testvec_dir] [case_prefix]}
TV=${2:-$ROOT/keys/testvec}
PREFIX=${3:-msgonly}
KEYS=${KEYS_DIR:-$ROOT/keys}
TOOL=${HPU_KEY_TOOL:-$ROOT/host/bin/hpu_key_tool}
pass=0; fail=0
for f in "$OUT"/hw_out_case*.hex; do
  n=$(basename "$f" .hex); n=${n#hw_out_case}
  exp=$(python3 -c "import json;d=json.load(open('$TV/expected.json'));print([e['expected_plain'] for e in d if e['case']=='${PREFIX}_$n'][0])")
  if "$TOOL" verify "$KEYS" "$f" "$exp" | grep -q VERIFY_PASS; then
    echo "case $n: PASS (expected $exp)"; pass=$((pass+1))
  else
    echo "case $n: FAIL (expected $exp)"; fail=$((fail+1))
  fi
done
echo "HW_VERIFY pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
