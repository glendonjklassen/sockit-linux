#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
hps_dir="$repo_root/sw/hps-image"
full_stack_dir="$hps_dir/full-stack"
src_dir="$hps_dir/buildroot-src"
dl_dir="$hps_dir/dl"
defconfig="$full_stack_dir/configs/sockit_cyclone5_kernel_owned_defconfig"
out_dir="${BUILDROOT_OUTPUT_DIR:-$hps_dir/output-kernel-owned}"
reference_image="${SOCKIT_REFERENCE_IMAGE:-$repo_root/SoCKit_SD_revD.img}"
jobs="${JOBS:-$(nproc)}"
build_sdk=0
prepare_args=(--defconfig "$defconfig")

usage() {
    cat <<EOF
Usage: $(basename "$0") [--fresh-config] [--output-dir PATH] [--reference-image PATH] [--sdk] [-j JOBS]

Build the SoCKit kernel-owned image workflow end to end:
  1. sync the Buildroot output tree from the full-stack defconfig
  2. build the Buildroot root filesystem, kernel, DTB, and host toolchain
  3. assemble an SD image that preserves the known-good raw boot partition
  4. optionally export a host-side SDK for cross-compiling HPS software
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fresh-config)
            prepare_args+=(--fresh)
            shift
            ;;
        --output-dir)
            out_dir="$2"
            shift 2
            ;;
        --reference-image)
            reference_image="$2"
            shift 2
            ;;
        --sdk)
            build_sdk=1
            shift
            ;;
        -j|--jobs)
            jobs="$2"
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

bash "$hps_dir/scripts/prepare-buildroot.sh" \
    "${prepare_args[@]}" \
    --output-dir "$out_dir"

GIT_CONFIG_GLOBAL=/dev/null \
GIT_CONFIG_NOSYSTEM=1 \
make -C "$src_dir" O="$out_dir" BR2_DL_DIR="$dl_dir" -j"$jobs"

if [[ "$build_sdk" -eq 1 ]]; then
    GIT_CONFIG_GLOBAL=/dev/null \
    GIT_CONFIG_NOSYSTEM=1 \
    make -C "$src_dir" O="$out_dir" BR2_DL_DIR="$dl_dir" sdk
fi

bash "$full_stack_dir/scripts/assemble-kernel-owned-image.sh" \
    --buildroot-output "$out_dir" \
    --reference-image "$reference_image"
