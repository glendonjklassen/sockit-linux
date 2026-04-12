# Resume Guide

This file is for fast handoff.

## Read Me First

- Start with [STATUS.md](/home/gjklassen/code/sockit-ids/sw/hps-image/STATUS.md).
- Then read [notes/current-system.md](/home/gjklassen/code/sockit-ids/sw/hps-image/notes/current-system.md).
- Then read [notes/current-boot-layout.md](/home/gjklassen/code/sockit-ids/sw/hps-image/notes/current-boot-layout.md).
- Then read [notes/rootfs-observations.md](/home/gjklassen/code/sockit-ids/sw/hps-image/notes/rootfs-observations.md).
- Then choose one item from [AGENT_TASKS.md](/home/gjklassen/code/sockit-ids/sw/hps-image/AGENT_TASKS.md).

## What We Were Doing

We validated the FPGA side and recovered a working HPS boot by returning to a
known-good SD image. From there we built and booted a Buildroot musl-based
rootfs-first image successfully, and in parallel assembled a first
kernel-owned SD image. That kernel-owned image has also now booted
successfully, but it is still carrying a provisional DE0-Nano-derived DTB.
The next workstream is not FPGA debugging; it is HPS image modernization and
reproducibility.

## Constraints

- Do not destroy or overwrite the known-good fallback SD image without making a
  backup first.
- Prefer incremental replacement over replacing the whole SoCFPGA boot chain in
  one move.
- Keep generated artifacts out of git.
- Do not add Terasic-distributed boot images or "CD-ROM" contents to this MIT
  repo; document them as external prerequisites instead.
- Record every discovered board-specific assumption in `notes/`.

## Good Next Actions

- use the working musl rootfs-first image as the day-to-day development image
- deploy and run a host-built HPS/FPGA bridge test binary on that image
- replace the provisional DE0-Nano DTB in `sw/hps-image/full-stack/` with a
  SoCKit-specific DTS or DTS adaptation
- rebuild and re-boot-test the kernel-owned image after the DTS update
- keep generated artifacts out of git while preserving the checked-in workflow

## If You Need To Rebuild Context

Useful facts already established:

- UART works on `/dev/ttyUSB0`
- JTAG cable is `CV SoCKit [1-6]`
- the current vendor image boots reliably
- the current vendor image is too minimal for comfortable development
- the Buildroot musl rootfs-first image now boots to a `root` shell
- that working Buildroot image obtained DHCP on `eth0`
- the first kernel-owned image now boots Linux 5.11 to a `root` shell
- that kernel-owned image also obtained DHCP on `eth0`
- the remaining known correctness gap is the provisional DT model /
  board-description mismatch

## Update Discipline

When making progress in this subtree:

- update `STATUS.md` if milestones or decisions change
- add raw findings to `notes/`
- keep `AGENT_TASKS.md` aligned with the actual remaining work
