#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="${BASE_DIR:-}"
binaries_dir="${BINARIES_DIR:-}"
rbf_name="${SOCKIT_FPGA_RBF_NAME:-sockit_ids.rbf}"
vendor_rbf_name="${SOCKIT_VENDOR_RBF_NAME:-soc_system_vendor.rbf}"
dtb_name="${SOCKIT_DTB_NAME:-socfpga.dtb}"
dtb_source_name="${SOCKIT_DTB_SOURCE_NAME:-socfpga_cyclone5_sockit.dtb}"
boot_script_source="${SOCKIT_UBOOT_SCRIPT_SOURCE:-$script_dir/u-boot.txt.in}"
boot_script_name="${SOCKIT_UBOOT_SCRIPT_NAME:-boot.script}"
uboot_script_name="${SOCKIT_UBOOT_SCRIPT_IMAGE_NAME:-u-boot.scr}"
kernel_name="${SOCKIT_KERNEL_IMAGE_NAME:-zImage}"

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
dtb_source_path="$binaries_dir/$dtb_source_name"
dtb_path="$binaries_dir/$dtb_name"
boot_script_path="$binaries_dir/$boot_script_name"
uboot_script_path="$binaries_dir/$uboot_script_name"

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

if [[ ! -f "$boot_script_source" ]]; then
    echo "post-image.sh: missing U-Boot script template: $boot_script_source" >&2
    exit 1
fi

if [[ ! -f "$dtb_source_path" ]]; then
    echo "post-image.sh: missing DTB: $dtb_source_path" >&2
    exit 1
fi

mkimage_tool=""
if [[ -n "${HOST_DIR:-}" && -x "${HOST_DIR}/bin/mkimage" ]]; then
    mkimage_tool="${HOST_DIR}/bin/mkimage"
elif command -v mkimage >/dev/null 2>&1; then
    mkimage_tool="$(command -v mkimage)"
fi

if [[ -z "$mkimage_tool" ]]; then
    echo "post-image.sh: mkimage not found; enable host U-Boot tools or install mkimage" >&2
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

echo "Copying SoCKit DTB to vendor-compatible boot filename:"
echo "  SRC -> $dtb_source_path"
echo "  DST -> $dtb_path"
cp "$dtb_source_path" "$dtb_path"

echo "Generating vendor-style U-Boot script source:"
echo "  SRC -> $boot_script_source"
echo "  DST -> $boot_script_path"
sed \
    -e "s|@RBF_NAME@|$rbf_name|g" \
    -e "s|@DTB_NAME@|$dtb_name|g" \
    -e "s|@KERNEL_IMAGE@|$kernel_name|g" \
    "$boot_script_source" >"$boot_script_path"

echo "Packing U-Boot boot script image:"
echo "  SRC -> $boot_script_path"
echo "  DST -> $uboot_script_path"
"$mkimage_tool" -A arm -O linux -T script -C none -a 0 -e 0 \
    -n "sockit-bootscript" -d "$boot_script_path" "$uboot_script_path"

exec "$genimage_script" "$@"
