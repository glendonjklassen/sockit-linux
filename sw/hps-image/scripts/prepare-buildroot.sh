#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
hps_dir="$repo_root/sw/hps-image"
board_dir="$hps_dir/board"
src_dir="$hps_dir/buildroot-src"
dl_dir="$hps_dir/dl"
defconfig="$hps_dir/configs/sockit_cyclone5_rootfs_first_defconfig"
out_dir="${BUILDROOT_OUTPUT_DIR:-$hps_dir/output-rootfs-first}"
fresh_config=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [--fresh] [--output-dir PATH]

Prepare a local Buildroot output tree for a SoCKit image workflow.

Options:
  --fresh            re-seed the output tree from the checked-in defconfig
  --defconfig PATH   override the checked-in defconfig to seed from
  --output-dir PATH  override the Buildroot O= directory
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fresh)
            fresh_config=1
            shift
            ;;
        --defconfig)
            defconfig="$2"
            shift 2
            ;;
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

if [[ ! -f "$defconfig" ]]; then
    echo "Missing defconfig: $defconfig" >&2
    exit 1
fi

mkdir -p "$out_dir" "$dl_dir"

if [[ -d "$board_dir" ]]; then
    mkdir -p "$out_dir/board"
    cp -a "$board_dir/." "$out_dir/board/"
fi

make_args=(
    -C "$src_dir"
    O="$out_dir"
    BR2_DL_DIR="$dl_dir"
)

if [[ "$fresh_config" -eq 1 || ! -f "$out_dir/.config" ]]; then
    make "${make_args[@]}" BR2_DEFCONFIG="$defconfig" defconfig
    sync_mode="seeded from checked-in defconfig"
else
    make "${make_args[@]}" olddefconfig
    sync_mode="refreshed existing output tree"
fi

cat <<MSG
Buildroot source is ready:
  $src_dir

Output tree:
  $out_dir

Board support files:
  $out_dir/board

Config sync:
  $sync_mode

Defconfig:
  $defconfig

Next steps:
  1. Build the selected image workflow:
       make -C $src_dir O=$out_dir BR2_DL_DIR=$dl_dir
  2. If your defconfig does not already emit a final SD image, run the
     matching assembly helper for that workflow.

If you want to discard the current output .config and start from the repo
defconfig again, rerun this script with --fresh.
MSG
