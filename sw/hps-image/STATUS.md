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
- The repo now also has a Buildroot-managed full-stack SD-image workflow that
  generates the raw `0xa2` partition locally instead of copying it from
  `SoCKit_SD_revD.img`
- That new locally generated early-boot path has now produced a first complete
  owned image at `sw/hps-image/output-full-stack/images/sdcard-full-stack.img`
- The first repo-owned full-stack boot attempt failed before any serial output
- Local barebox inspection showed the checked-in full-stack config was building
  `socfpga-xload-2`, which omits `CONFIG_MACH_SOCFPGA_TERASIC_SOCKIT` and
  emits a SoCDK xload image
- The full-stack workflow was corrected to target
  `socfpga-xload_defconfig` and `barebox-socfpga-sockit-xload.img`
- That corrected full-stack image has now booted successfully on hardware:
  serial shows `barebox 2021.07.0`, the SoCKit DTB load,
  `root=/dev/mmcblk0p3`, `Welcome to Buildroot`, and `sockit login:`
- The one remaining validation gap is a clean single-console login session to
  confirm DHCP/ssh state on that corrected image without overlapping UART
  monitors
- Later FPGA-loading tests showed that the `barebox` path fails for both the
  repo and vendor `.rbf` images during the FPGA-manager transaction, so the
  project is now pivoting the primary path back to a vendor-style
  preloader/U-Boot handoff while preserving the owned Linux artifacts

## Why We Are Starting This Workspace

The old SD image is good enough as a fallback but poor for active development.
Even a tiny HPS-to-FPGA bridge test ran into friction because the image lacks:

- package management
- a simple `devmem`-style tool
- a modern, maintainable software base
- an easy way to deploy host-built test binaries cleanly

## Immediate Next Steps

1. Treat the U-Boot-centered hybrid full-stack image as the primary development
   baseline: preserve the vendor raw boot partition and U-Boot chain while
   keeping the owned kernel, DTB, rootfs, and FPGA artifacts.
2. Boot-test that hybrid image and capture serial evidence for FPGA load,
   Linux boot, `/proc/cmdline`, DHCP, and `sshd`.
3. Validate the host-SDK and HPS-to-FPGA demo workflow on that hybrid image.
4. Keep the `barebox` path as a documented experimental branch rather than the
   default boot path unless a board-specific fix makes its FPGA load reliable.

## Parallel Workstream

- The kernel / DTB ownership track under `sw/hps-image/full-stack/` is now a
  proven boot path, not just an exploratory branch.
- That track should become the main route for image modernization while the
  current rootfs-first path remains available as a fallback.
- Its current gap is no longer kernel bring-up; it is final on-device workflow
  validation after the pivot back to the vendor-style U-Boot FPGA-load path.

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

## Newly Captured Full-Stack Boot Facts

- The corrected full-stack image boots via `barebox 2021.07.0` rather than the
  vendor 2013 U-Boot path.
- barebox loads `/boot/socfpga_cyclone5_sockit.dtb` from the generated FAT boot
  partition.
- barebox passes `console=ttyS0,115200 root=/dev/mmcblk0p3 rw rootwait`.
- Linux mounts the Buildroot root filesystem from `/dev/mmcblk0p3`.
- The corrected image reaches `Welcome to Buildroot` and `sockit login:` on the
  SoCKit serial console.
- An overlapped serial-monitor session also captured `Linux sockit 5.11.0`,
  which is consistent with the owned kernel path, but a clean login transcript
  is still worth capturing next.
- A clean serial login has now confirmed:
  `Linux sockit 5.11.0`, `root=/dev/mmcblk0p3`, model `Terasic SoCkit`,
  live DHCP on `eth0`, and an active `sshd` listener.
- Stock OpenSSH policy still blocks passwordless root SSH over the network
  until an authorized key is installed, so the image flow now needs a simple
  key-provisioning path for development use.
- A later April 13 hardware session narrowed the remaining problem:
  `barebox` can boot the owned Linux stack, but its FPGA-manager load path
  times out for both the repo and vendor `.rbf` images.
- That result makes the current primary direction a hybrid image that preserves
  the vendor raw boot partition and U-Boot chain while keeping the owned
  kernel, DTB, rootfs, and FPGA artifact generation.
- A later U-Boot-side retest also confirmed that:
  - the board must be in the Terasic-documented compressed-`.rbf` MSEL mode
    (`FPGAMGRREGS_STAT = 0x50`)
  - but even in that corrected MSEL state, manual `fpga load` still fails for
    both the byte-identical vendor `soc_system.rbf` and the repo-generated
    `sockit_ids.rbf`
- The latest corrected-MSEL boot also produced visible blinking LEDs on the
  board, so the next check should verify from Linux whether the FPGA image is
  actually alive despite U-Boot returning `-4`

## Definition Of Done For Option A

We consider the first milestone done when we can:

- build the image reproducibly from this repo workflow
- export a matching host SDK/toolchain reproducibly from the same workflow
- boot it on the SoCKit
- log in over serial
- reach the network
- deploy and run a small host-built HPS-side bridge test
- document rebuild and flash steps for future sessions
