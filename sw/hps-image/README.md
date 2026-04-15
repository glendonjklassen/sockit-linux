# HPS Image Workspace

This directory is the working area for a modernized SoCKit HPS Linux image.

The goal is a reproducible, documented development image that gives us:

- serial console access
- network access
- a usable package/tool story
- easy HPS-to-FPGA bridge testing from Linux
- a clean host-side cross-compilation workflow for HPS software

## What This Folder Is For

Keep the recipe in git, not the giant generated artifacts.

Things tracked here:

- configuration files
- scripts
- build instructions
- board notes

Things not in git:

- downloaded source trees
- generated root filesystems
- SD card images
- temporary build directories
- toolchain/sysroot output
- vendor-supplied Terasic image archives or extracted boot images

## Directory Layout

- [README.md](README.md): this file
- [STATUS.md](STATUS.md): current system state and next steps
- [notes/](notes/): board observations
- [configs/](configs/): checked-in config files
- [scripts/](scripts/): reproducible helper scripts
- [patches/](patches/): local patches if needed
- [full-stack/](full-stack/): configs and board support for the primary image

Ignored local directories:

- `buildroot-src/`, `dl/`, `output-full-stack/`, `work/`

## Primary Workflow

Fetch the pinned Buildroot release (2025.02.12) into the local workspace:

```bash
BUILDROOT_URL=https://buildroot.org/downloads/buildroot-2025.02.12.tar.xz \
  ./sw/hps-image/scripts/fetch-buildroot.sh
```

Then build everything in one shot:

```bash
./sw/hps-image/scripts/build-full-stack.sh --sdk
```

To inject an SSH key for passwordless root login on fresh images:

```bash
SOCKIT_AUTHORIZED_KEYS_FILE=$HOME/.ssh/id_ed25519.pub \
  ./sw/hps-image/scripts/build-full-stack.sh --sdk
```

The build produces:

- `output-full-stack/images/sdcard-barebox.img` — flash this to the SD card
- `output-full-stack/images/arm-buildroot-linux-musleabihf_sdk-buildroot.tar.gz` — host SDK

If you have changed the defconfig or any Linux-side boot payload settings,
add `--fresh-config` to reseed the output tree from the defconfig before
rebuilding.

### Manual Steps

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
```

After extracting the SDK tarball on the dev box, run `./relocate-sdk.sh` and
then `. ./environment-setup` before building HPS software.

## Fallback Workflow

If you need to compare against the preserved vendor boot chain:

```bash
./sw/hps-image/scripts/build-rootfs-first.sh --sdk
```

This still requires a local `SoCKit_SD_revD.img` from the Terasic Rev. D
distribution.

## External Inputs

The primary full-stack workflow generates all partitions from repo-managed
artifacts. The older rootfs-first fallback requires a local copy of
`systemcd/SoCKit_SD_revD.img`.
