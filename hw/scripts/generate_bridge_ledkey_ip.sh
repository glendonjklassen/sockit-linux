#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
qsys_file="$repo_root/hw/ip/bridge_ledkey_probe.qsys"
out_dir="$repo_root/hw/ip/bridge_ledkey_probe_gen"

rm -rf "$out_dir"
qsys-generate "$qsys_file" \
  --synthesis=VERILOG \
  --output-directory="$out_dir" \
  --part=5CSXFC6D6F31C6
