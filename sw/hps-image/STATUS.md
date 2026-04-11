# Status

## Scope

Create a reproducible HPS image workspace for the SoCKit board and document the
 current known state so future work can resume cleanly.

## What Has Already Been Verified

- The Quartus project builds successfully.
- The active FPGA top level is `sockit_ids_hps_demo`.
- The FPGA bitstream was programmed successfully over JTAG.
- The HPS serial console is available on host device `/dev/ttyUSB0`.
- A known-good SD image boots to a Linux login prompt.
- The current HPS image is old and minimal.
- The current HPS image does not expose a normal package manager.
- The current HPS image does have basic networking and BusyBox utilities.
- The current HPS image does not have `gcc`.

## Current Board Facts

- Board: SoCKit / Cyclone V SoC Development Kit
- Host JTAG cable: `CV SoCKit [1-6]`
- Host serial device: `/dev/ttyUSB0`
- HPS login: `root` with no password on the known-good image
- Current kernel seen on console: Linux `3.12.0-00307-g507abb4-dirty`
- Current userspace appears vendor/demo oriented and dated

## Why We Are Starting This Workspace

The old SD image is good enough as a fallback but poor for active development.
Even a tiny HPS-to-FPGA bridge test ran into friction because the image lacks:

- package management
- a compiler
- a simple `devmem`-style tool
- a modern, maintainable software base

## Immediate Next Steps

1. Decide whether to start with Buildroot or another lightweight image path.
2. Create a reproducible fetch/build script for the selected approach.
3. Capture the minimum package set required for HPS/FPGA iteration.
4. Decide which current boot components to reuse for the first custom image.

## Newly Captured Boot Facts

- `/dev/mmcblk0p1` is a FAT32 boot partition.
- `/dev/mmcblk0p1` contains `zImage` and `socfpga.dtb`.
- U-Boot does not require a `u-boot.scr` on the current image.
- Linux boots with `console=ttyS0,115200 root=/dev/mmcblk0p2 rw rootwait`.
- `/dev/mmcblk0p2` is the ext3 root filesystem.
- `/dev/mmcblk0p3` is a small raw partition of type `0xa2`; its contents look
  like ARM boot code and are likely bootloader-related.
- The current rootfs is a conventional SysV-style Linux image with `inittab`,
  `/etc/init.d`, and runlevel directories such as `/etc/rcS.d` and
  `/etc/rc5.d`.
- Networking is configured conventionally via `/etc/network/interfaces`.
- The current image starts `sshd` and other services through standard init
  scripts rather than a vendor-only init framework.

## Definition Of Done For Option A

We consider the first milestone done when we can:

- build the image reproducibly from this repo workflow
- boot it on the SoCKit
- log in over serial
- reach the network
- compile or run a small HPS-side bridge test
- document rebuild and flash steps for future sessions
