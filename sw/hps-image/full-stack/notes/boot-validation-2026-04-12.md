# Full-Stack Boot Validation - 2026-04-12

This note records the first successful hardware boot of the corrected
Buildroot-managed full-stack SoCKit image.

## What Changed

The original full-stack boot attempt failed before any serial output. Local
inspection showed the image was built with the wrong auxiliary barebox defconfig:

- wrong: `socfpga-xload-2`
- correct: `socfpga-xload`

That mistake produced a SoCDK xload image instead of the SoCKit-specific first
stage bootloader.

The corrected full-stack workflow now builds:

- `barebox-socfpga-sockit-xload.img`
- `barebox-socfpga-sockit.img`
- `socfpga_cyclone5_sockit.dtb`
- `sdcard-full-stack.img`

## Serial Evidence

The clean reboot after rebuilding the image showed:

- `barebox 2021.07.0 #1 Sun Apr 12 21:58:57 CDT 2026`
- `Loading devicetree from '/boot/socfpga_cyclone5_sockit.dtb'`
- `commandline: console=ttyS0,115200  root=/dev/mmcblk0p3 rw rootwait`
- `Welcome to Buildroot`
- `sockit login:`

An earlier overlapping serial session also captured:

- `Linux sockit 5.11.0 #1 SMP Sun Apr 12 21:00:37 CDT 2026 armv7l GNU/Linux`

That is enough to conclude the SoCKit is now booting the repo-owned full-stack
path rather than the old vendor U-Boot / kernel-owned flow.

## Remaining Follow-Up

The serial log from this session was noisy because more than one monitor was
attached over the course of bring-up. The next clean validation step should be
a single-console login session that records:

- `uname -a`
- `cat /proc/cmdline`
- `ip addr`
- evidence that `sshd` is running
- the host-side IP address observed for the board, if DHCP succeeds
