#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
hps_image_dir="$repo_root/sw/hps-image"
work_dir="$hps_image_dir/work"
src_dir="$hps_image_dir/buildroot-src"

buildroot_url="${BUILDROOT_URL:-}"

mkdir -p "$work_dir"

if [[ -z "$buildroot_url" ]]; then
    cat <<'MSG'
Set BUILDROOT_URL to a pinned Buildroot source tarball or git archive URL before
running this script.

Example:
  BUILDROOT_URL=https://buildroot.org/downloads/buildroot-YYYY.MM.tar.xz \
    ./sw/hps-image/scripts/fetch-buildroot.sh

This script is intentionally conservative:
- it does not guess a version
- it keeps fetched source out of git
- it creates a stable local workspace for repeatable builds
MSG
    exit 1
fi

archive_name="$(basename "$buildroot_url")"
archive_path="$work_dir/$archive_name"

if [[ ! -f "$archive_path" ]]; then
    echo "Fetching $buildroot_url"
    curl -L "$buildroot_url" -o "$archive_path"
else
    echo "Reusing existing archive $archive_path"
fi

rm -rf "$src_dir"
mkdir -p "$src_dir"
tar -xf "$archive_path" -C "$src_dir" --strip-components=1

echo "Buildroot source prepared in $src_dir"
