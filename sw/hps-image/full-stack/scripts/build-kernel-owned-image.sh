#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
hps_dir="$repo_root/sw/hps-image"

cat >&2 <<'MSG'
build-kernel-owned-image.sh is now a compatibility wrapper.
The primary owned-image workflow lives at:
  sw/hps-image/scripts/build-full-stack.sh
MSG

exec bash "$hps_dir/scripts/build-full-stack.sh" "$@"
