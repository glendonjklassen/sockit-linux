#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/SoCKit_SD_revD.img" >&2
    exit 1
fi

img="$1"
tmp_rootfs="/tmp/$(basename "$img").p2.ext3"

python - "$img" <<'PY'
import os
import subprocess
import sys

img = sys.argv[1]
subprocess.run(["file", img], check=True)
subprocess.run(["fdisk", "-l", img], check=True)
subprocess.run(["parted", "-s", img, "unit", "s", "print"], check=True)
PY

echo
echo "Extracting partition 2 to $tmp_rootfs for debugfs inspection..."
dd if="$img" of="$tmp_rootfs" bs=512 skip=14336 count=2097152 status=progress

echo
echo "--- rootfs / ---"
debugfs -R "ls -l /" "$tmp_rootfs" || true

echo
echo "--- rootfs /boot ---"
debugfs -R "ls -l /boot" "$tmp_rootfs" || true

echo
echo "--- /etc/fstab ---"
debugfs -R "cat /etc/fstab" "$tmp_rootfs" || true

echo
echo "--- /etc/inittab ---"
debugfs -R "cat /etc/inittab" "$tmp_rootfs" || true

echo
echo "--- /etc/network/interfaces ---"
debugfs -R "cat /etc/network/interfaces" "$tmp_rootfs" || true

echo
echo "Temporary extracted rootfs left at $tmp_rootfs"
