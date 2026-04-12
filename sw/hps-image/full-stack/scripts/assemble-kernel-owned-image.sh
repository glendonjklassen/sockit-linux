#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
hps_dir="$repo_root/sw/hps-image"
full_stack_dir="$hps_dir/full-stack"
buildroot_output="${BUILDROOT_OUTPUT_DIR:-$hps_dir/output-kernel-owned}"
reference_image="${SOCKIT_REFERENCE_IMAGE:-$repo_root/SoCKit_SD_revD.img}"
output_image=""
dtb_image=""
sector_size=512

usage() {
    cat <<EOF
Usage: $(basename "$0") [--buildroot-output PATH] [--reference-image PATH] [--output-image PATH] [--dtb-image PATH]

Assemble a SoCKit SD image by preserving the known-good raw boot partition from
the Terasic reference image, replacing the FAT boot partition with a generated
zImage + DTB payload, and replacing the Linux root filesystem partition with
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
        --dtb-image)
            dtb_image="$2"
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
host_bin_dir="$buildroot_output/host/bin"
host_sbin_dir="$buildroot_output/host/sbin"
kernel_image="$images_dir/zImage"
rootfs_image="$images_dir/rootfs.ext2"
mkfs_vfat="$host_sbin_dir/mkfs.vfat"
mcopy="$host_bin_dir/mcopy"

if [[ -z "$output_image" ]]; then
    output_image="$images_dir/sdcard-kernel-owned.img"
fi

if [[ ! -f "$reference_image" ]]; then
    echo "Missing reference image: $reference_image" >&2
    exit 1
fi

if [[ ! -f "$kernel_image" ]]; then
    echo "Missing kernel image: $kernel_image" >&2
    echo "Run the Buildroot make step first." >&2
    exit 1
fi

if [[ ! -f "$rootfs_image" ]]; then
    echo "Missing Buildroot rootfs image: $rootfs_image" >&2
    echo "Run the Buildroot make step first." >&2
    exit 1
fi

if [[ ! -x "$mkfs_vfat" || ! -x "$mcopy" ]]; then
    echo "Missing Buildroot host FAT tools in $host_bin_dir or $host_sbin_dir" >&2
    echo "Enable host dosfstools and mtools, then rebuild." >&2
    exit 1
fi

if [[ -z "$dtb_image" ]]; then
    mapfile -t dtb_candidates < <(find "$images_dir" -maxdepth 1 -type f -name '*.dtb' | sort)
    if (( ${#dtb_candidates[@]} == 0 )); then
        echo "No DTB found in $images_dir" >&2
        exit 1
    fi
    if (( ${#dtb_candidates[@]} > 1 )); then
        echo "Multiple DTBs found in $images_dir; pass --dtb-image explicitly." >&2
        printf '  %s\n' "${dtb_candidates[@]}" >&2
        exit 1
    fi
    dtb_image="${dtb_candidates[0]}"
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

boot_bytes=$((p1_size * sector_size))
tmpdir="$(mktemp -d /tmp/sockit-kernel-owned.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT
boot_vfat="$tmpdir/boot.vfat"

truncate -s "$boot_bytes" "$boot_vfat"
"$mkfs_vfat" -n SOCKITBOOT "$boot_vfat" >/dev/null
MTOOLS_SKIP_CHECK=1 "$mcopy" -i "$boot_vfat" "$kernel_image" ::zImage
MTOOLS_SKIP_CHECK=1 "$mcopy" -i "$boot_vfat" "$dtb_image" ::socfpga.dtb

boot_payload_bytes="$(stat -c %s "$boot_vfat")"
boot_payload_sectors=$((boot_payload_bytes / sector_size))

cp --reflink=auto "$reference_image" "$output_image"

dd if="$boot_vfat" of="$output_image" bs="$sector_size" seek="$p1_start" conv=notrunc status=none
dd if="$rootfs_image" of="$output_image" bs="$sector_size" seek="$p2_start" conv=notrunc status=none

remaining_boot_sectors=$((p1_size - boot_payload_sectors))
if (( remaining_boot_sectors > 0 )); then
    dd if=/dev/zero of="$output_image" bs="$sector_size" \
        seek="$((p1_start + boot_payload_sectors))" count="$remaining_boot_sectors" \
        conv=notrunc status=none
fi

remaining_rootfs_sectors=$((p2_size - rootfs_sectors))
if (( remaining_rootfs_sectors > 0 )); then
    dd if=/dev/zero of="$output_image" bs="$sector_size" \
        seek="$((p2_start + rootfs_sectors))" count="$remaining_rootfs_sectors" \
        conv=notrunc status=none
fi

manifest_path="${output_image%.img}.manifest.txt"
cat >"$manifest_path" <<EOF
reference_image=$reference_image
output_image=$output_image
kernel_image=$kernel_image
dtb_image=$dtb_image
boot_payload_image=$boot_vfat
rootfs_image=$rootfs_image
partition_3_start_sectors=$p3_start
partition_3_size_sectors=$p3_size
partition_2_start_sectors=$p2_start
partition_2_size_sectors=$p2_size
partition_1_start_sectors=$p1_start
partition_1_size_sectors=$p1_size
rootfs_size_bytes=$rootfs_bytes
rootfs_size_sectors=$rootfs_sectors
boot_payload_size_bytes=$boot_payload_bytes
boot_payload_size_sectors=$boot_payload_sectors
EOF

cat <<MSG
Assembled SoCKit kernel-owned SD image:
  $output_image

Preserved raw boot partition from:
  $reference_image

Generated FAT boot payload with:
  kernel -> zImage
  dtb    -> socfpga.dtb

Manifest:
  $manifest_path

Track note:
  This workflow still uses a provisional SoCFPGA DTB source until we replace
  the DE0-Nano reference DTS with a SoCKit-specific one.
MSG
