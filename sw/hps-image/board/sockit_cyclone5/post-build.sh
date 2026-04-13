#!/usr/bin/env bash
set -euo pipefail

target_dir="${TARGET_DIR:-${1:-}}"
authorized_keys_file="${SOCKIT_AUTHORIZED_KEYS_FILE:-}"

if [[ -z "$target_dir" ]]; then
    echo "post-build.sh: missing TARGET_DIR" >&2
    exit 1
fi

if [[ -z "$authorized_keys_file" ]]; then
    exit 0
fi

if [[ ! -f "$authorized_keys_file" ]]; then
    echo "post-build.sh: missing SOCKIT_AUTHORIZED_KEYS_FILE: $authorized_keys_file" >&2
    exit 1
fi

install -d -m 700 "$target_dir/root/.ssh"
install -m 600 "$authorized_keys_file" "$target_dir/root/.ssh/authorized_keys"

echo "Installed root authorized_keys from: $authorized_keys_file"
