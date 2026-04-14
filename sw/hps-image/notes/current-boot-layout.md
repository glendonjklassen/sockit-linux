# Current Boot Layout

Status: initial capture complete

This note records what the known-good SD card is doing today.

## Observed Partition Table

From `busybox fdisk -u -l /dev/mmcblk0` on the running board:

- `/dev/mmcblk0p1`
  - type: `0x0b` FAT32
  - sectors: `2121728` to `3799447`
  - size: `838860` blocks
- `/dev/mmcblk0p2`
  - type: `0x83` Linux
  - sectors: `14336` to `2111487`
  - size: `1048576` blocks
- `/dev/mmcblk0p3`
  - type: `0xa2` unknown
  - sectors: `2048` to `4095`
  - size: `1024` blocks

The partition table is not in disk order.

## Matching Disk Image

A local image file is available at:

- `/home/gjklassen/code/sockit-ids/SoCKit_SD_revD.img`

Host-side inspection with `fdisk` and `parted` shows that this image matches
the live board layout closely:

- partition 1: FAT32, starts at sector `2121728`, size `1677720` sectors
- partition 2: Linux/ext3, starts at sector `14336`, size `2097152` sectors
- partition 3: type `0xa2`, starts at sector `2048`, size `2048` sectors

That makes the image a useful offline reference for future analysis.

Notes:

- a read-only loop mount was attempted on the host and failed because loop
  device setup was unavailable in this environment
- the image is still useful for partition-table and raw-offset inspection

## Root Filesystem

The running kernel command line is:

`console=ttyS0,115200 root=/dev/mmcblk0p2 rw rootwait`

Observed mounts confirm:

- `/dev/mmcblk0p2` is mounted as `/`
- filesystem type is `ext3`

## Boot Partition

`/dev/mmcblk0p1` can be mounted read-only as a FAT filesystem and contains:

- `zImage`
- `socfpga.dtb`

No `u-boot.scr` was present on this partition when inspected.

This matches the boot log captured on the serial console.

## What U-Boot Appears To Do

From the captured boot log:

- try `u-boot.scr`
- if absent, continue normal boot
- read `zImage`
- read `socfpga.dtb`
- boot the kernel with `root=/dev/mmcblk0p2`

This means the current image uses a very simple boot flow and does not require
a boot script file on the FAT partition.

## Rootfs `/boot` Versus Boot Partition

The root filesystem also has a `/boot` directory containing:

- `vmlinux-3.9.0`
- `zImage-3.9.0`
- `zImage -> zImage-3.9.0`

That directory is on the ext3 rootfs and is not the same thing as the FAT boot
partition currently used by U-Boot.

## Partition 3

`/dev/mmcblk0p3` is a tiny raw partition of type `0xa2`.

The first bytes look like ARM boot code rather than a filesystem. At this point
the best working assumption is:

- it is bootloader-related, likely vendor boot metadata or a raw preloader/SPL
  area

That is an inference, not a confirmed identification yet.

## Takeaway For Option A

The least-risk migration path is likely:

1. preserve the current early-boot pieces initially
2. keep the FAT boot partition model
3. swap in our own kernel/DTB/rootfs in controlled steps

This should be revisited after we decide whether Buildroot is the chosen base.
