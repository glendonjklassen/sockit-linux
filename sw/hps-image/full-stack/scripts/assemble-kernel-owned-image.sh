#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
hps_dir="$repo_root/sw/hps-image"

cat >&2 <<'MSG'
assemble-kernel-owned-image.sh is now a compatibility wrapper.
The primary owned-image workflow lives at:
  sw/hps-image/scripts/assemble-full-stack-image.sh
MSG

exec bash "$hps_dir/scripts/assemble-full-stack-image.sh" "$@"
