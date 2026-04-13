# Kernel / DTB Ownership Plan

Status: active separate-track plan

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

## What We Know Now

- the SoCFPGA kernel tree we are already using contains a native SoCKit DTS:
  `socfpga_cyclone5_sockit.dts`
- our first kernel-owned image booted successfully even with the provisional
  DE0-Nano-derived DTB
- the current rebuild in this track now targets the native SoCKit DTS instead
  of the DE0-Nano placeholder
- that rebuilt SoCKit-DTS image now boots successfully to a shell on hardware
  with the owned kernel/rootfs path
- the raw `0xa2` partition in the Terasic reference image contains ARM boot
  code and embedded `U-Boot SPL` / `U-Boot` strings, so it is very likely the
  early-boot payload we still inherit
- the local Buildroot tree includes a nearby Cyclone V reference board,
  `terasic_de10nano_cyclone5`, that already generates a raw `0xa2` partition,
  FAT boot partition, Linux rootfs partition, and complete `sdcard.img`
- that nearby reference uses Buildroot-managed `barebox` plus an auxiliary
  `socfpga-xload-2` image rather than preserving a vendor image sector-for-
  sector

## Early-Boot Ownership Direction

The next meaningful ownership step is no longer "get our kernel to boot." That
part is done.

The remaining gap is:

1. stop preserving partition 3 from `SoCKit_SD_revD.img`
2. generate the raw boot payload ourselves
3. emit a complete SD image from repo-managed inputs only

The strongest current lead is to adapt the nearby Buildroot Cyclone V pattern
instead of inventing a one-off SoCFPGA boot flow from scratch.

That means the first investigation should be:

- whether the SoCKit can boot cleanly from a Buildroot-generated
  `barebox` + `socfpga-xload-2` path
- what SoCKit-specific environment, DT, or storage assumptions differ from the
  DE10-Nano reference
- whether we want full ownership through `barebox`, or to keep pursuing a
  U-Boot-compatible raw partition once we understand the vendor flow better

## Most Likely Technical Work Items

- choose a kernel baseline that still supports Cyclone V SoCFPGA cleanly
- switch the workflow to the native `socfpga_cyclone5_sockit.dts`
- verify whether any SoCKit-specific fixes are still needed on top of that DTS
- verify UART, MMC, Ethernet, and HPS bridge nodes in the DTB
- wire kernel + DTB artifacts into a generated FAT image
- prototype a generated raw partition using the Buildroot Cyclone V
  `barebox` / xload reference flow
- create a SoCKit-specific `genimage` layout for the full-stack path
- remove the external Terasic reference-image dependency once the generated
  early-boot path is stable
- then verify serial, MMC, Ethernet, ssh, and HPS bridge access on the fully
  self-hosted image

## Main Unknowns

- whether the vendor U-Boot expects any kernel-image quirks from the 2014 flow
- whether bridge-related nodes need board-specific DT changes beyond a nearby
  Cyclone V reference board
- what exact format and contents the raw `0xa2` partition expects when we
  finally replace it
- whether SoCKit early boot is best owned by adapting the Buildroot
  `barebox`-based Cyclone V flow or by recreating a U-Boot/SPL layout closer to
  the vendor image

## Working Assumption

The DE10-Nano Buildroot support was a good technical reference for first
bring-up, but it is no longer the intended DT direction.

The current assumption is:

- use the same modern SoCFPGA kernel baseline
- use the kernel tree's native `socfpga_cyclone5_sockit.dts`
- preserve the raw `0xa2` partition until the SoCKit-DTS image is stable
- only then start replacing the early-boot partition
