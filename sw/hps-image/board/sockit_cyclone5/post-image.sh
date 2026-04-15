#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="${BASE_DIR:-}"
binaries_dir="${BINARIES_DIR:-}"
rbf_name="${SOCKIT_FPGA_RBF_NAME:-sockit.rbf}"
dtb_name="${SOCKIT_DTB_NAME:-socfpga.dtb}"
dtb_source_name="${SOCKIT_DTB_SOURCE_NAME:-socfpga_cyclone5_sockit.dtb}"

if [[ -n "$base_dir" ]]; then
    repo_root="$(cd "$base_dir/../../.." && pwd)"
    genimage_script="$(cd "$base_dir/.." && pwd)/buildroot-src/support/scripts/genimage.sh"
else
    repo_root="$(cd "$script_dir/../../../.." && pwd)"
    genimage_script="$script_dir/../../buildroot-src/support/scripts/genimage.sh"
fi

sof_path="${SOCKIT_FPGA_SOF:-$repo_root/hw/output_files/SoCKit.sof}"
rbf_path="$binaries_dir/$rbf_name"
dtb_source_path="$binaries_dir/$dtb_source_name"
dtb_path="$binaries_dir/$dtb_name"

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

if [[ ! -f "$dtb_source_path" ]]; then
    echo "post-image.sh: missing DTB: $dtb_source_path" >&2
    exit 1
fi

echo "Converting FPGA image for boot partition:"
echo "  SOF -> $sof_path"
echo "  RBF -> $rbf_path"

# Match the vendor SoCKit/SystemCD flow: generate a compressed raw binary
# bitstream for FPGA-manager based configuration at boot.
quartus_cpf -c -o bitstream_compression=on "$sof_path" "$rbf_path"

echo "Copying SoCKit DTB to vendor-compatible boot filename:"
echo "  SRC -> $dtb_source_path"
echo "  DST -> $dtb_path"
cp "$dtb_source_path" "$dtb_path"

exec "$genimage_script" "$@"
