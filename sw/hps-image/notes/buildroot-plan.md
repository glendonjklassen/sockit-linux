# Buildroot Plan

Status: initial recommendation

## Why Buildroot Is The Default First Choice

For this project, Buildroot is attractive because it gives us:

- a reproducible root filesystem build
- an easy way to add developer-friendly packages
- a much smaller operational footprint than a full Yocto bring-up
- a clean path to iterate toward a custom image without replacing every boot
  component on day one

That makes it a good fit for "Option A": modernize enough to develop
comfortably, while keeping risk low.

## Recommended Version Pin

Recommended first pin:

- `Buildroot 2025.02.12`

Reasoning:

- it is on the current LTS line
- LTS support is a better fit than chasing the newest quarterly release while
  we are still learning the board
- the goal right now is stable forward progress, not maximum freshness

This choice should be revisited only if we hit a concrete blocker that the LTS
line cannot handle.

## First Working Assumption

The least-risk first image should reuse as much of the current working boot path
as possible.

Based on the current boot inventory, the board appears to boot like this:

1. early boot / bootloader-related code from the SD card layout already in use
2. U-Boot loads `zImage` from the FAT boot partition
3. U-Boot loads `socfpga.dtb` from the FAT boot partition
4. Linux mounts `/dev/mmcblk0p2` as the ext3 root filesystem

So the first custom-image strategy should likely be:

- keep the FAT boot partition model
- keep the ext filesystem rootfs model
- replace kernel/DTB/rootfs in controlled steps
- avoid touching the tiny raw partition until we know we must

## What The First Custom Image Needs

The first development-oriented image should prioritize usefulness over purity.

Minimum package goals:

- `gcc`
- `g++` if Buildroot package choices make it cheap to include
- `make`
- `binutils`
- `gdbserver` or equivalent debugging support
- `openssh`
- `busybox`
- `devmem` or `devmem2` equivalent
- basic networking tools
- `scp`/`sftp` path for moving test binaries
- enough shell utilities to inspect memory maps, mounts, and boot files

Nice-to-have packages:

- `strace`
- `less`
- `nano` or `vim-tiny`
- `rsync`
- `python3` if image size remains acceptable

## Kernel / DTB Strategy

Preferred order of attack:

1. first try reusing the current working kernel and DTB expectations
2. if that is awkward, build and replace only the kernel/DTB while keeping the
   rest of the boot chain intact
3. replace earlier boot stages only if they become a blocker

This reduces the number of moving parts during the first successful boot.

## Repository Integration

Recommended local workspace model:

- fetched Buildroot source tree lives outside git in `sw/hps-image/buildroot-src/`
- generated downloads live in `sw/hps-image/dl/`
- generated build output lives in `sw/hps-image/output/`
- checked-in config fragments and board notes live under `sw/hps-image/configs/`
  and `sw/hps-image/notes/`

## First Script We Will Want

A helper that:

1. fetches a pinned Buildroot release tarball or clone
2. unpacks it into `sw/hps-image/buildroot-src/`
3. points Buildroot at local `dl/` and `output/` directories
4. applies the repo's checked-in config

## Remaining Open Questions

- whether the SoCKit is happiest with ext3 versus ext4 for the first pass
- whether we should reuse the existing kernel initially or replace it
- whether `mmcblk0p3` contains anything we must preserve when cloning SD cards
