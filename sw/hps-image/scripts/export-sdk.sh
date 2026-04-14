#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
hps_dir="$repo_root/sw/hps-image"
src_dir="$hps_dir/buildroot-src"
dl_dir="$hps_dir/dl"
out_dir="${BUILDROOT_OUTPUT_DIR:-$hps_dir/output-rootfs-first}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [--output-dir PATH]

Export the Buildroot-generated cross-toolchain as a relocatable SDK tarball.
The SDK is built from the current Buildroot output tree and written into
<output-dir>/images/.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            out_dir="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ ! -d "$src_dir" ]]; then
    echo "Missing Buildroot source in $src_dir" >&2
    echo "Run sw/hps-image/scripts/fetch-buildroot.sh first." >&2
    exit 1
fi

if [[ ! -f "$out_dir/.config" ]]; then
    echo "Missing Buildroot output config in $out_dir" >&2
    echo "Run sw/hps-image/scripts/prepare-buildroot.sh first." >&2
    exit 1
fi

make -C "$src_dir" O="$out_dir" BR2_DL_DIR="$dl_dir" sdk

cat <<MSG
SDK export complete.

Generated artifacts are in:
  $out_dir/images

After extracting the SDK tarball on your dev box, run:
  ./relocate-sdk.sh
  . ./environment-setup
MSG
