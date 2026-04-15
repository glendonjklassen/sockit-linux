# SoCKit Cyclone V Board Notes

This directory is for SoCKit-specific Buildroot integration files.

The full-stack image path is now the primary workflow:

- Buildroot owns the FAT boot partition
- Buildroot owns the Linux root filesystem
- the Terasic raw `0xa2` boot partition and U-Boot chain are preserved for now
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
- `u-boot.txt.in`: template for the generated vendor-style `u-boot.scr`
- `barebox-env/`: retained as a documented experimental path, not the default
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

## Boot-Time FPGA Image

The repo-owned full-stack path now treats the FPGA image as a boot artifact,
not as a separate manual JTAG step:

- `post-image.sh` converts `hw/output_files/SoCKit.sof` into
  `sockit.rbf`
- `genimage-full-stack.cfg` places that `sockit.rbf` on the FAT boot
  partition
- `post-image.sh` generates a `u-boot.scr` that loads the `.rbf`, runs
  `bridge_enable_handoff`, and then boots Linux through the preserved vendor
  U-Boot chain

This mirrors the vendor SystemCD pattern, where the boot script loads an
`.rbf` from the FAT partition before handing off to the kernel.

Current hardware status:

- the preserved `barebox` path reached the FPGA-manager load attempt
- the repo `.rbf` and the vendor `.rbf` both failed there on hardware
- the active direction is to keep the owned Linux artifacts while pivoting the
  boot-time FPGA load back to the vendor-style preloader/U-Boot flow

See
[`../../full-stack/notes/boot-time-fpga-debug-2026-04-13.md`](../../full-stack/notes/boot-time-fpga-debug-2026-04-13.md)
for the detailed bring-up record.

See
[`../../full-stack/notes/barebox-retrospective-2026-04-14.md`](../../full-stack/notes/barebox-retrospective-2026-04-14.md)
for the summary of what the `barebox` work proved and why it is still worth
keeping in the repo.
