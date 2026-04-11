# Kernel / DTB Ownership Plan

Status: initial separate-track plan

This note covers the path for owning `zImage` and `socfpga.dtb` while still
reusing the current SPL / U-Boot path initially.

## Why This Track Exists

The rootfs-first experiment showed the cost of keeping the old vendor kernel:

- the board still boots Linux `3.12.0`
- a modern Buildroot userspace can trip over that kernel boundary
- even when compatibility shims help, we are still anchored to a very old
  runtime

That makes kernel / DTB ownership the next logical step toward a maintainable
SoCKit image.

## Target End State For This Track

Short-to-medium-term success looks like:

1. Buildroot builds our own SoCFPGA kernel.
2. Buildroot or a helper script produces a SoCKit-appropriate DTB.
3. We generate a FAT boot partition containing our `zImage` and `socfpga.dtb`.
4. The existing U-Boot loads those files without needing a more complex boot
   script.
5. The board reaches a modern userspace with working serial, MMC, Ethernet,
   and HPS-to-FPGA bridge access.

## Lowest-Risk Replacement Order

Recommended order:

1. keep `mmcblk0p3`
2. keep existing SPL / U-Boot behavior
3. replace kernel and DTB together
4. keep rootfs generation in Buildroot
5. revisit the raw boot partition only after kernel / DTB ownership is stable

## Most Likely Technical Work Items

- choose a kernel baseline that still supports Cyclone V SoCFPGA cleanly
- identify whether a SoCKit DTS already exists upstream or in vendor trees
- create or adapt a SoCKit DTS if one does not already exist
- verify UART, MMC, Ethernet, and HPS bridge nodes in the DTB
- wire kernel + DTB artifacts into a generated FAT image
- verify U-Boot can still boot them with the current simple flow

## Main Unknowns

- whether an upstream or vendor SoCKit DTS already exists and is usable
- whether the vendor U-Boot expects any kernel-image quirks from the 2014 flow
- whether bridge-related nodes need board-specific DT changes beyond a nearby
  Cyclone V reference board

## Working Assumption

The best starting point is still the Buildroot DE10-Nano Cyclone V support:

- it already demonstrates a modern SoCFPGA kernel build path
- it already emits `zImage` and a DTB
- it uses a similar SD-image structure

We should treat it as a technical reference, not as a drop-in SoCKit config.
