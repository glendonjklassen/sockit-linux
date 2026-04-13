#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
hps_dir="$repo_root/sw/hps-image"
buildroot_output="${BUILDROOT_OUTPUT_DIR:-$hps_dir/output-full-stack}"
output_image=""
sector_size=512

usage() {
    cat <<EOF
Usage: $(basename "$0") [--buildroot-output PATH] [--output-image PATH]

Validate and record the Buildroot-generated SoCKit full-stack SD image.
This workflow expects Buildroot to already have generated:
  - the raw 0xa2 early-boot payload
  - the FAT boot partition
  - the Linux rootfs
  - a complete SD image
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --buildroot-output)
            buildroot_output="$2"
            shift 2
            ;;
        --output-image)
            output_image="$2"
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

images_dir="$buildroot_output/images"
kernel_image="$images_dir/zImage"
boot_vfat="$images_dir/boot.vfat"
rootfs_image="$images_dir/rootfs.ext2"
barebox_image="$images_dir/barebox-socfpga-sockit.img"
barebox_xload_image="$images_dir/barebox-socfpga-socdk-xload.img"
barebox_env="$images_dir/barebox-env"
dtb_image="$images_dir/socfpga_cyclone5_sockit.dtb"
generated_image="$images_dir/sdcard-full-stack.img"

if [[ -z "$output_image" ]]; then
    output_image="$generated_image"
fi

required_files=(
    "$kernel_image"
    "$boot_vfat"
    "$rootfs_image"
    "$barebox_image"
    "$barebox_xload_image"
    "$barebox_env"
    "$dtb_image"
    "$generated_image"
)

for path in "${required_files[@]}"; do
    if [[ ! -f "$path" ]]; then
        echo "Missing expected full-stack artifact: $path" >&2
        echo "Run the Buildroot make step first." >&2
        exit 1
    fi
done

if [[ "$output_image" != "$generated_image" ]]; then
    mkdir -p "$(dirname "$output_image")"
    cp --reflink=auto "$generated_image" "$output_image"
fi

parted_output="$(parted -ms "$output_image" unit s print)"

get_partition_field() {
    local partition="$1"
    local field_index="$2"
    local value

    value="$(printf '%s\n' "$parted_output" | awk -F: -v partition="$partition" '$1 == partition { print $field }' field="$field_index")"

    if [[ -z "$value" ]]; then
        echo "Could not find partition $partition in $output_image" >&2
        exit 1
    fi

    printf '%s\n' "${value%s}"
}

p1_start="$(get_partition_field 1 2)"
p1_size="$(get_partition_field 1 4)"
p2_start="$(get_partition_field 2 2)"
p2_size="$(get_partition_field 2 4)"
p3_start="$(get_partition_field 3 2)"
p3_size="$(get_partition_field 3 4)"

image_bytes="$(stat -c %s "$output_image")"
kernel_bytes="$(stat -c %s "$kernel_image")"
dtb_bytes="$(stat -c %s "$dtb_image")"
rootfs_bytes="$(stat -c %s "$rootfs_image")"
boot_vfat_bytes="$(stat -c %s "$boot_vfat")"
barebox_bytes="$(stat -c %s "$barebox_image")"
barebox_xload_bytes="$(stat -c %s "$barebox_xload_image")"
barebox_env_bytes="$(stat -c %s "$barebox_env")"

manifest_path="${output_image%.img}.manifest.txt"
cat >"$manifest_path" <<EOF
output_image=$output_image
generated_image=$generated_image
kernel_image=$kernel_image
dtb_image=$dtb_image
rootfs_image=$rootfs_image
boot_vfat_image=$boot_vfat
barebox_image=$barebox_image
barebox_xload_image=$barebox_xload_image
barebox_env_image=$barebox_env
output_image_size_bytes=$image_bytes
output_image_size_sectors=$((image_bytes / sector_size))
partition_1_start_sectors=$p1_start
partition_1_size_sectors=$p1_size
partition_2_start_sectors=$p2_start
partition_2_size_sectors=$p2_size
partition_3_start_sectors=$p3_start
partition_3_size_sectors=$p3_size
kernel_size_bytes=$kernel_bytes
dtb_size_bytes=$dtb_bytes
rootfs_size_bytes=$rootfs_bytes
boot_vfat_size_bytes=$boot_vfat_bytes
barebox_size_bytes=$barebox_bytes
barebox_xload_size_bytes=$barebox_xload_bytes
barebox_env_size_bytes=$barebox_env_bytes
EOF

cat <<MSG
Validated SoCKit full-stack SD image:
  $output_image

Generated artifacts:
  raw boot payload -> $barebox_xload_image
  boot partition   -> $boot_vfat
  kernel           -> $kernel_image
  dtb              -> $dtb_image
  rootfs           -> $rootfs_image

Manifest:
  $manifest_path

This image no longer depends on SoCKit_SD_revD.img.
MSG
