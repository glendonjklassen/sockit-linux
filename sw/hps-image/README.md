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
- [full-stack/](/home/gjklassen/code/sockit-ids/sw/hps-image/full-stack): separate workstream for owning kernel and DTB too

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

In parallel, there is now a separate kernel / DTB ownership track under
[full-stack/](/home/gjklassen/code/sockit-ids/sw/hps-image/full-stack). That
workstream is where we can start replacing the vendor `zImage` and
`socfpga.dtb` without destabilizing the more conservative rootfs-first path.

## External Inputs

This repo intentionally does not include vendor image payloads.

The current rootfs-first SD-image workflow still reuses the known-good SoCKit
boot partitions from the Terasic Rev. D "CD-ROM" package. In practice that
means a fresh clone also needs a local copy of the Rev. D boot image, such as
`SoCKit_SD_revD.img`, obtained from Terasic's distribution outside this MIT
repo.

The repo recipe owns the Buildroot rootfs and SDK generation. It does not yet
fully own the boot image contents in the FAT boot partition or the tiny raw
boot partition.

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

Once Buildroot is fetched, the main one-shot workflow is:

```bash
./sw/hps-image/scripts/build-rootfs-first.sh --sdk
```

That command:

- syncs the output tree from the checked-in SoCKit defconfig
- builds the Buildroot root filesystem and host toolchain
- exports a relocatable SDK tarball for host-side cross-compilation
- assembles an SD image by reusing the known-good SoCKit boot partitions and
  replacing only the Linux root filesystem partition

The SD-image assembly step expects a locally available reference image from the
Terasic Rev. D "CD-ROM" package. By default the scripts look for:

```bash
$PWD/SoCKit_SD_revD.img
```

You can override that path with:

```bash
SOCKIT_REFERENCE_IMAGE=/path/to/SoCKit_SD_revD.img \
  ./sw/hps-image/scripts/build-rootfs-first.sh --sdk
```

If you want to run the steps separately:

```bash
./sw/hps-image/scripts/prepare-buildroot.sh --fresh
make -C sw/hps-image/buildroot-src \
  O=$PWD/sw/hps-image/output-rootfs-first \
  BR2_DL_DIR=$PWD/sw/hps-image/dl
./sw/hps-image/scripts/export-sdk.sh
./sw/hps-image/scripts/assemble-rootfs-first-image.sh
```

The exported SDK lands in `sw/hps-image/output-rootfs-first/images/`. After
extracting it on the dev box, run `./relocate-sdk.sh` and then
`. ./environment-setup` in the extracted SDK directory before building your own
HPS-side software.

There is also an offline SD-image inspection helper at
[scripts/inventory-sd-image.sh](/home/gjklassen/code/sockit-ids/sw/hps-image/scripts/inventory-sd-image.sh)
for documenting known-good images without needing a live board session.
