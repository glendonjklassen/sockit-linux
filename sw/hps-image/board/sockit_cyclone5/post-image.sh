#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="${BASE_DIR:-}"
binaries_dir="${BINARIES_DIR:-}"
rbf_name="${SOCKIT_FPGA_RBF_NAME:-sockit_ids.rbf}"
vendor_rbf_name="${SOCKIT_VENDOR_RBF_NAME:-soc_system_vendor.rbf}"

if [[ -n "$base_dir" ]]; then
    repo_root="$(cd "$base_dir/../../.." && pwd)"
    genimage_script="$(cd "$base_dir/.." && pwd)/buildroot-src/support/scripts/genimage.sh"
else
    repo_root="$(cd "$script_dir/../../../.." && pwd)"
    genimage_script="$script_dir/../../buildroot-src/support/scripts/genimage.sh"
fi

sof_path="${SOCKIT_FPGA_SOF:-$repo_root/hw/output_files/SoCKit-IDS.sof}"
rbf_path="$binaries_dir/$rbf_name"
vendor_rbf_source="${SOCKIT_VENDOR_RBF_SOURCE:-$repo_root/systemcd/Demonstrations/Linux_BSP/Console_FB/GHRD/soc_system.rbf}"
vendor_rbf_path="$binaries_dir/$vendor_rbf_name"

if [[ -z "$binaries_dir" ]]; then
    echo "post-image.sh: missing BINARIES_DIR" >&2
    exit 1
fi

if [[ ! -f "$sof_path" ]]; then
    echo "post-image.sh: missing FPGA source bitstream: $sof_path" >&2
    exit 1
fi

if ! command -v quartus_cpf >/dev/null 2>&1; then
    echo "post-image.sh: quartus_cpf not found in PATH" >&2
    exit 1
fi

if [[ ! -x "$genimage_script" ]]; then
    echo "post-image.sh: missing genimage helper: $genimage_script" >&2
    exit 1
fi

echo "Converting FPGA image for boot partition:"
echo "  SOF -> $sof_path"
echo "  RBF -> $rbf_path"

# Match the vendor SoCKit/SystemCD flow: generate a compressed raw binary
# bitstream for FPGA-manager based configuration at boot.
quartus_cpf -c -o bitstream_compression=on "$sof_path" "$rbf_path"

if [[ -f "$vendor_rbf_source" ]]; then
    echo "Copying vendor reference FPGA image for side-by-side bootloader tests:"
    echo "  SRC -> $vendor_rbf_source"
    echo "  DST -> $vendor_rbf_path"
    cp "$vendor_rbf_source" "$vendor_rbf_path"
fi

exec "$genimage_script" "$@"
