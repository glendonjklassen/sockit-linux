# SoCKit Cyclone V Board Notes

This directory is for SoCKit-specific Buildroot integration files.

The full-stack image path is now the primary workflow:

- Buildroot owns the raw `0xa2` boot payload
- Buildroot owns the FAT boot partition
- Buildroot owns the Linux root filesystem
- the older rootfs-first path remains here only as a fallback

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

## Files In This Folder

- `genimage-full-stack.cfg`: the primary repo-owned SD image layout
- `barebox-env/`: SoCKit-specific `barebox` environment for the full-stack path
- `dts/`: repo-owned SoCKit DTS overrides for the full-stack kernel build
- `genimage-rootfs-first.cfg`: conservative fallback layout used only by the
  reference-image-based rootfs-first path

`prepare-buildroot.sh` copies this directory into the active Buildroot output
tree so the checked-in defconfigs can reference the board files without
modifying the fetched Buildroot source tree.

## Optional SSH Key Injection

The full-stack path now includes a board-specific post-build hook:

- `post-build.sh`

If you export `SOCKIT_AUTHORIZED_KEYS_FILE=/path/to/your.pub` before running
the full-stack build, that public key is installed into:

- `/root/.ssh/authorized_keys`

This keeps the default OpenSSH policy of key-based root login without requiring
manual serial-side key setup on every fresh image.

## Lightweight Bridge Note

The repo-owned SoCKit DTS under `dts/` explicitly enables the lightweight
HPS-to-FPGA bridge. The upstream SoCFPGA DTS leaves that bridge disabled, and
touching `0xFF200000` from Linux with the bridge still disabled can wedge the
board.
