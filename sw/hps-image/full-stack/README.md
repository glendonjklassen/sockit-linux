# Full-Stack Ownership Track

This directory is a separate workstream for taking ownership of more of the
SoCKit software stack than the current rootfs-first path.

The rootfs-first path under `sw/hps-image/` keeps the vendor kernel, DTB, and
early boot pieces as long as possible. That is useful for low-risk bring-up,
but it leaves us tied to an old runtime.

This track exists so we can work toward:

- our own `zImage`
- our own `socfpga.dtb`
- a generated FAT boot partition, not a copied vendor one
- eventually, if needed, ownership of the tiny raw boot partition too

## Current Goal

The near-term target is not "replace everything at once." It is:

1. keep the existing SPL / U-Boot path for now
2. build our own kernel and DTB
3. place those artifacts in the FAT boot partition
4. boot them with the existing U-Boot behavior
5. keep the raw `0xa2` partition untouched until we know we must replace it

That would let us own the runtime stack without immediately turning this into a
full early-boot bring-up project.

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
- candidate Buildroot config fragments for the kernel-owned path
- future SoCKit-specific board files for generated boot partitions
- future scripts for building and assembling a kernel-owned SD image
