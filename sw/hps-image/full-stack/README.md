# Full-Stack Ownership Track

This directory is a separate workstream for taking ownership of more of the
SoCKit software stack than the current rootfs-first path.

The rootfs-first path under `sw/hps-image/` keeps the vendor kernel, DTB, and
early boot pieces as long as possible. That is useful for low-risk bring-up,
but it leaves us tied to an old runtime, which is why that conservative path
currently uses a musl userspace for compatibility.

This track exists so we can work toward:

- our own `zImage`
- our own `socfpga.dtb`
- a generated FAT boot partition, not a copied vendor one
- eventually, if needed, ownership of the tiny raw boot partition too

## Current Goal

The near-term target is not "replace everything at once." It is:

1. keep using the already working owned kernel + DTB + rootfs image as the
   baseline
2. replace the preserved raw `0xa2` partition with a generated early-boot
   payload
3. generate the full SD image from repo-managed artifacts rather than copying
   sectors from `SoCKit_SD_revD.img`
4. keep the current rootfs-first workflow as a fallback until the self-hosted
   full-stack image is equally reliable

That keeps the project focused on the remaining ownership gap instead of
re-solving kernel bring-up that is already working.

## Current Workflow

The primary repo-owned workflow now uses:

- `../scripts/build-full-stack.sh`
- `../scripts/assemble-full-stack-image.sh`
- `configs/sockit_cyclone5_full_stack_defconfig`
- `../board/sockit_cyclone5/genimage-full-stack.cfg`
- `../board/sockit_cyclone5/barebox-env/`

The older `build-kernel-owned-image.sh` and
`assemble-kernel-owned-image.sh` scripts remain only as compatibility wrappers.

The new full-stack path is intended to generate:

- the raw `0xa2` early-boot payload
- the FAT boot partition with `zImage`, DTB, and `barebox` artifacts
- the Linux rootfs
- a complete `sdcard-full-stack.img`

Current nuance:

- the upstream `barebox` AUX/xload build we are using emits the SoCFPGA SoCDK
  xload artifact name, `barebox-socfpga-socdk-xload.img`
- the SoCKit full-stack layout currently uses that generated xload image for
  partition 1 while keeping the SoCKit-specific main `barebox` image and DTB

That implementation is now checked in, but it still needs hardware boot
validation on the SoCKit.

A nearby Buildroot reference still matters here because it showed the first
plausible ownership model for Cyclone V early boot:

- `configs/terasic_de10nano_cyclone5_defconfig`
- `board/terasic/de10nano_cyclone5/genimage.cfg`

That reference does not match SoCKit directly, but it is important because it
already produces:

- a raw `0xa2` boot partition payload
- a FAT boot partition
- a Linux rootfs partition
- a one-shot `sdcard.img`

## Current DTS Assumption

The first successful boot of this track used the upstream SoCFPGA DE0-Nano DTS
as a provisional stand-in, which is why the running model string reported
`Terasic DE-0(Atlas)`.

The kernel tree we are using already contains a SoCKit-specific DTS:

- `socfpga_cyclone5_sockit`

The checked-in full-stack defconfig now targets that SoCKit DTS. Historical
rebuild output under `sw/hps-image/output-kernel-owned-sockit/` also uses the
native SoCKit DTB. Keep the older DE0-Nano-based image only as a bring-up
fallback.

That SoCKit-DTS image has now also been boot-tested successfully on hardware:
it reaches the Buildroot shell, mounts the owned root filesystem, starts
networking and `sshd`, and is suitable as the new working ownership baseline.

## Why This Is Separate

Keeping this in a separate folder makes the intent clear:

- `sw/hps-image/` is still the conservative rootfs-first path
- `sw/hps-image/full-stack/` is the newer-kernel / newer-DTB ownership path

That separation makes it easier to compare approaches and keep one fallback
track working while we push the other forward.

## Expected Inputs

We already know:

- the board boots `zImage` and `socfpga.dtb` from the FAT partition
- U-Boot does not require a `u-boot.scr` today
- the old vendor kernel is Linux `3.12.0`
- a nearby Buildroot reference exists for Cyclone V SoCFPGA:
  `configs/terasic_de10nano_cyclone5_defconfig`

## What Belongs Here

- notes about kernel / DTB ownership
- candidate Buildroot config fragments for the owned-image path
- SoCKit-specific board files for generated boot partitions
- scripts and wrappers for building and validating the full-stack SD image
- notes about the remaining hardware validation gap for the generated
  early-boot path
