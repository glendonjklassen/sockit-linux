# HPS Image Workspace

This directory is the working area for a modernized SoCKit HPS Linux image.

The goal is not to replace the entire SoCFPGA boot stack in one jump. The
first milestone is a reproducible, documented development image that gives us:

- serial console access
- network access
- a usable package/tool story
- easy HPS-to-FPGA bridge testing from Linux

## What This Folder Is For

Keep the recipe in git, not the giant generated artifacts.

Things we want to track here:

- configuration files
- scripts
- build instructions
- board notes
- boot-layout notes
- handoff docs for later sessions or parallel agents
- patches for Buildroot, U-Boot, kernel, or device tree if we need them

Things we do not want in git:

- downloaded source trees
- generated root filesystems
- SD card images
- temporary build directories
- toolchain/sysroot output

## Current Strategy

We are intentionally starting with the least-risk path:

1. Preserve the known-good vendor SD image as a fallback.
2. Inventory the current boot layout and running software.
3. Build a fresh development-oriented image in a reproducible way.
4. Reuse as much of the currently working boot flow as possible at first.
5. Replace more of the stack later only if it buys us something.

The default assumption is that Buildroot is the best fit for the first custom
image, but that decision is not locked in yet.

## Directory Layout

- [README.md](/home/gjklassen/code/sockit-ids/sw/hps-image/README.md): high-level purpose and usage
- [STATUS.md](/home/gjklassen/code/sockit-ids/sw/hps-image/STATUS.md): current findings and next actions
- [RESUME.md](/home/gjklassen/code/sockit-ids/sw/hps-image/RESUME.md): handoff notes for future sessions/agents
- [AGENT_TASKS.md](/home/gjklassen/code/sockit-ids/sw/hps-image/AGENT_TASKS.md): suggested parallel work split
- [notes/](/home/gjklassen/code/sockit-ids/sw/hps-image/notes): collected board and boot observations
- [configs/](/home/gjklassen/code/sockit-ids/sw/hps-image/configs): checked-in config files
- [scripts/](/home/gjklassen/code/sockit-ids/sw/hps-image/scripts): reproducible helper scripts
- [patches/](/home/gjklassen/code/sockit-ids/sw/hps-image/patches): local patches if needed later

Ignored local directories used by builds:

- `sw/hps-image/build/`
- `sw/hps-image/output/`
- `sw/hps-image/dl/`
- `sw/hps-image/work/`
- `sw/hps-image/buildroot-src/`

## Resume Workflow

When resuming work, read these files in order:

1. [STATUS.md](/home/gjklassen/code/sockit-ids/sw/hps-image/STATUS.md)
2. [RESUME.md](/home/gjklassen/code/sockit-ids/sw/hps-image/RESUME.md)
3. the specific note file linked from `STATUS.md`

That should be enough for another session or another agent to continue without
rebuilding all the context from scratch.

## Near-Term Goal

Produce a first HPS development image that can boot on the SoCKit and includes:

- `gcc`
- `make`
- a simple register access utility such as `devmem` or `devmem2`
- `ssh`
- the ability to run the lightweight bridge LED/KEY demo cleanly

## First Concrete Work Items

The current next step is to pin a Buildroot release and fetch it into the local
ignored workspace.

There is an intentionally conservative helper script at
[scripts/fetch-buildroot.sh](/home/gjklassen/code/sockit-ids/sw/hps-image/scripts/fetch-buildroot.sh).

Usage:

```bash
BUILDROOT_URL=https://buildroot.org/downloads/buildroot-2025.02.12.tar.xz \
  ./sw/hps-image/scripts/fetch-buildroot.sh
```

It does not guess a version on its own. The currently recommended pin is
documented in
[notes/buildroot-plan.md](/home/gjklassen/code/sockit-ids/sw/hps-image/notes/buildroot-plan.md).

There is also an offline SD-image inspection helper at
[scripts/inventory-sd-image.sh](/home/gjklassen/code/sockit-ids/sw/hps-image/scripts/inventory-sd-image.sh)
for documenting known-good images without needing a live board session.
