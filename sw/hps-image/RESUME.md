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
successfully. The repo has now been updated so the full-stack path is the main
project, including a Buildroot-managed attempt at generating the raw `0xa2`
partition locally instead of copying it from `SoCKit_SD_revD.img`.
That workflow has now produced a first owned image at
`sw/hps-image/output-full-stack/images/sdcard-full-stack.img`.
The next workstream is to hardware-boot-test that locally generated full-stack
image, not to revisit FPGA debugging.

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

- build the primary owned-image workflow with
  `sw/hps-image/scripts/build-full-stack.sh --sdk`
- boot-test that generated SD image on hardware
- verify serial login, DHCP, `sshd`, and rootfs mount on the generated image
- deploy and run a host-built HPS/FPGA bridge test binary on that image
- keep the older rootfs-first path available only as a fallback comparison

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
- the SoCKit-DTS kernel-owned rebuild also booted successfully
- the repo now contains a generated early-boot full-stack path, but that new
  path has not yet been hardware boot-tested

## Update Discipline

When making progress in this subtree:

- update `STATUS.md` if milestones or decisions change
- add raw findings to `notes/`
- keep `AGENT_TASKS.md` aligned with the actual remaining work
