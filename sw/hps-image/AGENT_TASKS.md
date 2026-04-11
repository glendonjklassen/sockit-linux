# Agent Tasks

This file is meant to make parallel work easier.

Each task below is intentionally scoped so a separate agent or session can pick
it up without stepping on unrelated work.

## Task 1: Current Boot Inventory

Goal:
Refine the current boot inventory with any missing details and verify the role
of the tiny raw partition.

Deliverables:

- confirmation or correction of the current partition-role assumptions
- any additional evidence about `mmcblk0p3`
- concise notes in `notes/current-boot-layout.md`

Write scope:

- `sw/hps-image/notes/current-boot-layout.md`

## Task 2: Buildroot Plan

Goal:
Choose a Buildroot baseline and document how it should be integrated here.

Deliverables:

- selected Buildroot version
- rationale
- expected board directory layout
- initial package list

Write scope:

- `sw/hps-image/notes/buildroot-plan.md`
- `sw/hps-image/configs/`

## Task 3: Boot Chain Reuse Analysis

Goal:
Figure out which existing vendor boot components can be reused at first.

Deliverables:

- short compatibility note covering SPL/preloader, U-Boot, kernel, and DTB
- recommendation on what to replace later versus now

Write scope:

- `sw/hps-image/notes/boot-chain-reuse.md`

## Task 5: Rootfs Replacement Strategy

Goal:
Turn the current boot and rootfs findings into a concrete "replace rootfs first"
plan for the first custom image.

Deliverables:

- rootfs format recommendation
- package shortlist for first boot
- notes on what must stay compatible with the existing boot flow

Write scope:

- `sw/hps-image/notes/rootfs-observations.md`
- `sw/hps-image/notes/buildroot-plan.md`

## Task 4: First Image Workflow

Goal:
Create the first reproducible fetch/build script once the Buildroot direction is
selected.

Deliverables:

- script(s) in `scripts/`
- usage docs in `README.md`

Write scope:

- `sw/hps-image/scripts/`
- `sw/hps-image/README.md`

## Coordination Rules

- Avoid editing the same note file from multiple agents.
- Put fresh discoveries in a new note file if you are unsure.
- If a decision changes project direction, update `STATUS.md`.
