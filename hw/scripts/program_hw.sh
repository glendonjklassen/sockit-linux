#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
sof_file="$repo_root/hw/output_files/SoCKit.sof"
cable="${1:-1}"
instance="${2:-}"

if [[ ! -f "$sof_file" ]]; then
    echo "Missing bitstream: $sof_file" >&2
    echo "Run hw/scripts/compile_hw.sh first." >&2
    exit 1
fi

if [[ -n "$instance" ]]; then
    quartus_pgm -m jtag -c "$cable" -o "p;$sof_file@$instance"
else
    quartus_pgm -m jtag -c "$cable" -o "p;$sof_file"
fi
