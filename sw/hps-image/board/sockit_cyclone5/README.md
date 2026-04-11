# SoCKit Cyclone V Board Notes

This directory is for SoCKit-specific Buildroot integration files.

The current plan is intentionally incremental:

- first, build a modern development-oriented root filesystem
- preserve the known-good boot flow where possible
- only replace kernel / DTB / early boot pieces when there is a clear need

## Reference Point

Buildroot 2025.02.12 already contains a related reference board:

- `configs/terasic_de10nano_cyclone5_defconfig`
- `board/terasic/de10nano_cyclone5/`

That board is not identical to the SoCKit, but it is a valuable Cyclone V SoC
example for:

- kernel choices
- SoCFPGA image layout
- partitioning conventions
- Buildroot integration patterns

## Current SoCKit Boot Picture

From the known-good image:

- `mmcblk0p3`: small raw `0xa2` bootloader-related partition
- `mmcblk0p1`: FAT boot partition with `zImage` and `socfpga.dtb`
- `mmcblk0p2`: ext3 root filesystem

That is close enough to the DE10-Nano example to justify reusing its structure
as a learning reference, while still keeping SoCKit-specific files here.
