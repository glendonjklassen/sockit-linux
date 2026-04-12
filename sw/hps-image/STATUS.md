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
- HPS login: `root` with no password on both the known-good vendor image and
  the current Buildroot musl image
- Current kernel seen on console: Linux `3.12.0-00307-g507abb4-dirty`
- The conservative rootfs-first Buildroot image now boots successfully on the
  board while reusing the vendor boot chain
- The working Buildroot image brings up `eth0` via DHCP and has been observed
  at `192.168.2.240`
- Current rootfs-first image assembly depends on an external Terasic Rev. D
  reference image that is not stored in this repo
- A glibc-based Buildroot rootfs still panics under the vendor kernel during
  `/sbin/init`, so the conservative rootfs-first track now targets musl
- The separate kernel-owned track has produced a first assembled
  `sdcard-kernel-owned.img`
- That first kernel-owned image has now been boot-tested successfully on
  hardware: Linux `5.11.0`, serial login, rootfs mount, and DHCP all work
- The first kernel-owned boot used a provisional DE0-Nano-derived DTB, and the
  running model string reported `Terasic DE-0(Atlas)` instead of SoCKit
- The SoCFPGA kernel tree also contains `socfpga_cyclone5_sockit.dts`, and
  a fresh kernel-owned image has now been rebuilt with that DTS under
  `sw/hps-image/output-kernel-owned-sockit/`
- That rebuilt SoCKit-DTS image has now been boot-tested successfully on
  hardware: it reaches a root shell, mounts the Buildroot rootfs, starts
  `sshd`, and brings `eth0` up on DHCP at `192.168.2.245`

## Why We Are Starting This Workspace

The old SD image is good enough as a fallback but poor for active development.
Even a tiny HPS-to-FPGA bridge test ran into friction because the image lacks:

- package management
- a simple `devmem`-style tool
- a modern, maintainable software base
- an easy way to deploy host-built test binaries cleanly

## Immediate Next Steps

1. Log into the working musl rootfs-first image and verify the expected shell,
   filesystem, and deployment flow over the network.
2. Deploy and run a small host-built HPS/FPGA bridge test binary on that
   working image.
3. Capture and record the running SoCKit model string explicitly from the new
   kernel-owned image, since the serial console made post-boot command output
   noisy during the first proof boot.
4. Verify any remaining board-specific peripherals and then continue toward
   replacing the preserved raw boot partition.

## Parallel Workstream

- A separate kernel / DTB ownership track now exists under
  `sw/hps-image/full-stack/`.
- That track is for replacing the vendor `zImage` and `socfpga.dtb` while
  keeping the current rootfs-first path available as a fallback.
- Its first output image is
  `sw/hps-image/output-kernel-owned/images/sdcard-kernel-owned.img`.

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
- export a matching host SDK/toolchain reproducibly from the same workflow
- boot it on the SoCKit
- log in over serial
- reach the network
- deploy and run a small host-built HPS-side bridge test
- document rebuild and flash steps for future sessions
