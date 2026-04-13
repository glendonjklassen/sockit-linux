# HPS Image Workspace

This directory is the working area for a modernized SoCKit HPS Linux image.

The goal is not to replace the entire SoCFPGA boot stack in one jump. The
first milestone is a reproducible, documented development image that gives us:

- serial console access
- network access
- a usable package/tool story
- easy HPS-to-FPGA bridge testing from Linux
- a clean host-side cross-compilation workflow for HPS software

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
- vendor-supplied Terasic image archives or extracted boot images

## Current Strategy

We now have two SoCKit image paths in this repo:

1. the primary full-stack workflow that owns early boot, kernel, DTB, and
   rootfs through Buildroot-managed artifacts
2. the conservative rootfs-first fallback that still reuses the vendor boot
   chain and reference SD image

Buildroot is no longer just the likely fit here; it is the active base for the
repo-managed SoCKit image.

## Directory Layout

- [README.md](/home/gjklassen/code/sockit-ids/sw/hps-image/README.md): high-level purpose and usage
- [STATUS.md](/home/gjklassen/code/sockit-ids/sw/hps-image/STATUS.md): current findings and next actions
- [RESUME.md](/home/gjklassen/code/sockit-ids/sw/hps-image/RESUME.md): handoff notes for future sessions/agents
- [AGENT_TASKS.md](/home/gjklassen/code/sockit-ids/sw/hps-image/AGENT_TASKS.md): suggested parallel work split
- [notes/](/home/gjklassen/code/sockit-ids/sw/hps-image/notes): collected board and boot observations
- [configs/](/home/gjklassen/code/sockit-ids/sw/hps-image/configs): checked-in config files
- [scripts/](/home/gjklassen/code/sockit-ids/sw/hps-image/scripts): reproducible helper scripts
- [patches/](/home/gjklassen/code/sockit-ids/sw/hps-image/patches): local patches if needed later
- [full-stack/](/home/gjklassen/code/sockit-ids/sw/hps-image/full-stack): notes and compatibility wrappers for the primary owned-image path

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

- a simple register access utility such as `devmem` or `devmem2`
- `ssh`
- enough shell and network tools to inspect the board comfortably
- the ability to run the lightweight bridge LED/KEY demo cleanly
- a Buildroot-generated SDK/toolchain on the host for compiling HPS software

## Current Workflow

The intended workflow is:

1. Build and own the HPS Linux image in this repo.
2. Cross-compile custom HPS software on the development host.
3. Copy binaries to the board over `ssh` or `scp`.
4. Keep native target compilation off the critical path.

That matches Buildroot much better than trying to make the SoCKit a
self-hosted development machine.

The default development target is now the full-stack owned-image workflow. The
older rootfs-first path remains useful as a fallback when we need a comparison
against the preserved vendor boot chain.

That full-stack path has now been boot-validated on hardware after correcting
the SoCKit first-stage `barebox` target. The current next step is no longer
"make it boot," it is "use the booted image as the development baseline."

## External Inputs

This repo intentionally does not include vendor image payloads.

The primary full-stack workflow is designed to build a complete SD image from
repo-managed artifacts only. The older rootfs-first fallback still reuses the
known-good SoCKit boot partitions from the Terasic Rev. D "CD-ROM" package, so
that fallback path still needs a local copy of `SoCKit_SD_revD.img` obtained
outside this MIT repo.

## Primary Workflow

Fetch the pinned Buildroot release into the local ignored workspace:

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

Once Buildroot is fetched, the main one-shot workflow is:

```bash
./sw/hps-image/scripts/build-full-stack.sh --sdk
```

If you want immediate SSH access to fresh images without doing serial-side key
setup first, provide a public key at build time:

```bash
SOCKIT_AUTHORIZED_KEYS_FILE=$HOME/.ssh/id_ed25519.pub \
  ./sw/hps-image/scripts/build-full-stack.sh --fresh-config --sdk
```

That command:

- syncs the output tree from the checked-in full-stack defconfig
- syncs the checked-in SoCKit board support files into that output tree
- builds the Buildroot root filesystem, kernel, DTB, and early-boot payload
- exports a relocatable musl-based SDK tarball for host-side cross-compilation
- validates the generated SD image and records a manifest for it

The default output tree for this path is:

```bash
sw/hps-image/output-full-stack/
```

If you want to run the steps separately:

```bash
./sw/hps-image/scripts/prepare-buildroot.sh \
  --fresh \
  --defconfig $PWD/sw/hps-image/full-stack/configs/sockit_cyclone5_full_stack_defconfig \
  --output-dir $PWD/sw/hps-image/output-full-stack
make -C sw/hps-image/buildroot-src \
  O=$PWD/sw/hps-image/output-full-stack \
  BR2_DL_DIR=$PWD/sw/hps-image/dl
make -C sw/hps-image/buildroot-src \
  O=$PWD/sw/hps-image/output-full-stack \
  BR2_DL_DIR=$PWD/sw/hps-image/dl sdk
./sw/hps-image/scripts/assemble-full-stack-image.sh \
  --buildroot-output $PWD/sw/hps-image/output-full-stack
```

The exported SDK lands in `sw/hps-image/output-full-stack/images/`. After
extracting it on the dev box, run `./relocate-sdk.sh` and then
`. ./environment-setup` in the extracted SDK directory before building your own
HPS-side software.

If you have changed the checked-in full-stack defconfig or bootloader settings,
rerun the helper with `--fresh-config` so the `barebox` package build
directories are reset before rebuilding.

## Fallback Workflow

If we need to compare against the preserved vendor boot chain, the older
rootfs-first workflow is still available:

```bash
./sw/hps-image/scripts/build-rootfs-first.sh --sdk
```

That fallback still depends on a local `SoCKit_SD_revD.img` from the Terasic
Rev. D distribution.

There is also an offline SD-image inspection helper at
[scripts/inventory-sd-image.sh](/home/gjklassen/code/sockit-ids/sw/hps-image/scripts/inventory-sd-image.sh)
for documenting known-good images without needing a live board session.
