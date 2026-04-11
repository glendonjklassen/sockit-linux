#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
qsys_file="$repo_root/hw/ip/bridge_ledkey_probe.qsys"
out_dir="$repo_root/hw/ip/bridge_ledkey_probe_gen"
fixed_bridge_wrapper="$repo_root/hw/ip/bridge_ledkey_probe_bridge_0_fixed.v"
generated_bridge_wrapper="$out_dir/synthesis/submodules/bridge_ledkey_probe_bridge_0.v"

rm -rf "$out_dir"
qsys-generate "$qsys_file" \
  --synthesis=VERILOG \
  --output-directory="$out_dir" \
  --part=5CSXFC6D6F31C6

# Quartus 25.1 emits a recursive self-instantiation in the generated
# hps_bridge_avalon wrapper for this minimal bridge-only design. Replace the
# broken file with a checked-in wrapper so the flow stays reproducible.
cp "$fixed_bridge_wrapper" "$generated_bridge_wrapper"
