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
known-good SD image. The next workstream is not FPGA debugging; it is HPS image
modernization and reproducibility.

## Constraints

- Do not destroy or overwrite the known-good fallback SD image without making a
  backup first.
- Prefer incremental replacement over replacing the whole SoCFPGA boot chain in
  one move.
- Keep generated artifacts out of git.
- Record every discovered board-specific assumption in `notes/`.

## Good Next Actions

- dump the current partition table and file layout from the known-good SD card
- choose and pin a Buildroot version
- define the minimum package set for the new image
- script the image build so it is restartable
- identify which current boot components can remain untouched for the first
  custom-image attempt

## If You Need To Rebuild Context

Useful facts already established:

- UART works on `/dev/ttyUSB0`
- JTAG cable is `CV SoCKit [1-6]`
- the current vendor image boots reliably
- the current vendor image is too minimal for comfortable development

## Update Discipline

When making progress in this subtree:

- update `STATUS.md` if milestones or decisions change
- add raw findings to `notes/`
- keep `AGENT_TASKS.md` aligned with the actual remaining work
