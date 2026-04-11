#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
hps_dir="$repo_root/sw/hps-image"
buildroot_output="${BUILDROOT_OUTPUT_DIR:-$hps_dir/output-rootfs-first}"
reference_image="${SOCKIT_REFERENCE_IMAGE:-$repo_root/SoCKit_SD_revD.img}"
images_dir=""
output_image=""
sector_size=512

usage() {
    cat <<EOF
Usage: $(basename "$0") [--buildroot-output PATH] [--reference-image PATH] [--output-image PATH]

Assemble a SoCKit SD image by reusing the known-good boot partitions from the
reference SD image and replacing only the Linux root filesystem partition with
the Buildroot-generated rootfs.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --buildroot-output)
            buildroot_output="$2"
            shift 2
            ;;
        --reference-image)
            reference_image="$2"
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
rootfs_image="$images_dir/rootfs.ext2"

if [[ -z "$output_image" ]]; then
    output_image="$images_dir/sdcard-rootfs-first.img"
fi

if [[ ! -f "$reference_image" ]]; then
    echo "Missing reference image: $reference_image" >&2
    exit 1
fi

if [[ ! -f "$rootfs_image" ]]; then
    echo "Missing Buildroot rootfs image: $rootfs_image" >&2
    echo "Run the Buildroot make step first." >&2
    exit 1
fi

mkdir -p "$(dirname "$output_image")"

parted_output="$(parted -ms "$reference_image" unit s print)"

get_partition_field() {
    local partition="$1"
    local field_index="$2"
    local value

    value="$(printf '%s\n' "$parted_output" | awk -F: -v partition="$partition" '$1 == partition { print $field }' field="$field_index")"

    if [[ -z "$value" ]]; then
        echo "Could not find partition $partition in $reference_image" >&2
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

rootfs_bytes="$(stat -c %s "$rootfs_image")"
if (( rootfs_bytes % sector_size != 0 )); then
    echo "Rootfs image size is not aligned to $sector_size-byte sectors: $rootfs_bytes" >&2
    exit 1
fi

rootfs_sectors=$((rootfs_bytes / sector_size))

if (( rootfs_sectors > p2_size )); then
    echo "Rootfs image is larger than partition 2 in the reference image." >&2
    echo "  rootfs sectors: $rootfs_sectors" >&2
    echo "  partition 2 sectors: $p2_size" >&2
    exit 1
fi

cp --reflink=auto "$reference_image" "$output_image"

dd if="$rootfs_image" of="$output_image" bs="$sector_size" seek="$p2_start" conv=notrunc status=none

remaining_sectors=$((p2_size - rootfs_sectors))
if (( remaining_sectors > 0 )); then
    dd if=/dev/zero of="$output_image" bs="$sector_size" seek="$((p2_start + rootfs_sectors))" count="$remaining_sectors" conv=notrunc status=none
fi

manifest_path="${output_image%.img}.manifest.txt"
cat >"$manifest_path" <<EOF
reference_image=$reference_image
output_image=$output_image
rootfs_image=$rootfs_image
partition_3_start_sectors=$p3_start
partition_3_size_sectors=$p3_size
partition_2_start_sectors=$p2_start
partition_2_size_sectors=$p2_size
partition_1_start_sectors=$p1_start
partition_1_size_sectors=$p1_size
rootfs_size_bytes=$rootfs_bytes
rootfs_size_sectors=$rootfs_sectors
EOF

cat <<MSG
Assembled SoCKit SD image:
  $output_image

Reference boot chain preserved from:
  $reference_image

Buildroot rootfs written into partition 2:
  $rootfs_image

Manifest:
  $manifest_path
MSG
