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
2. boot that owned Linux stack through the vendor-style preloader/U-Boot chain
3. generate the FAT boot payload and rootfs from repo-managed artifacts
4. keep the raw `0xa2` partition preserved from `SoCKit_SD_revD.img` until a
   future fully owned early-boot path is worth revisiting

That keeps the project focused on a dependable development image instead of
re-solving early boot before we need to.

## Current Workflow

The primary hybrid workflow now uses:

- `../scripts/build-full-stack.sh`
- `../scripts/assemble-full-stack-image.sh`
- `configs/sockit_cyclone5_full_stack_defconfig`
- `../board/sockit_cyclone5/genimage-full-stack.cfg`
- `../board/sockit_cyclone5/u-boot.txt.in`

The older `build-kernel-owned-image.sh` and
`assemble-kernel-owned-image.sh` scripts remain only as compatibility wrappers.

The current full-stack path generates:

- the FAT boot partition with `zImage`, DTB, `u-boot.scr`, and FPGA artifacts
- the Linux rootfs
- a hybrid `sdcard-full-stack.img` assembled around the preserved Terasic raw
  boot partition and U-Boot chain

Current nuance:

- the Terasic image already contains the raw preloader/U-Boot path that boots
  this board reliably
- the generated `u-boot.scr` now mirrors the vendor FPGA-load flow from
  `systemcd/`
- the full-stack image still owns the modern kernel, DTB, rootfs, and FPGA
  artifact generation

The earlier `barebox` implementation is still preserved as a documented
experimental path. It was useful enough to prove repo-owned Linux boot on the
board, but it is no longer the default path for boot-time FPGA loading.

See
[`notes/barebox-retrospective-2026-04-14.md`](/home/gjklassen/code/sockit-linux/sw/hps-image/full-stack/notes/barebox-retrospective-2026-04-14.md)
for the kept context and reasons for the pivot.

The corrected `barebox` implementation had previously been rebuilt and
boot-tested on the SoCKit. Serial confirmed:

- `barebox 2021.07.0`
- the SoCKit DTB load from `/boot/socfpga_cyclone5_sockit.dtb`
- `root=/dev/mmcblk0p3`
- `Welcome to Buildroot`
- `sockit login:`

See
[`notes/boot-validation-2026-04-12.md`](/home/gjklassen/code/sockit-ids/sw/hps-image/full-stack/notes/boot-validation-2026-04-12.md)
for the captured evidence and remaining follow-up.

## Current FPGA Boot Status

The repo-owned `barebox` boot path reached the FPGA-manager transaction and
loaded `.rbf` files from `/boot`, but the live April 13 hardware session showed
that this path still fails before configuration completes.

The most important A/B result is that both:

- the repo `sockit_ids.rbf`
- the Terasic vendor `soc_system_vendor.rbf`

time out from `barebox` with the same configuration-done failure.

That means the current blocker was not isolated to the repo bitstream itself.
The active direction is now a hybrid image that preserves the owned kernel,
DTB, and rootfs while switching boot-time FPGA loading back to a more
factory-style preloader/U-Boot flow.

See
[`notes/boot-time-fpga-debug-2026-04-13.md`](/home/gjklassen/code/sockit-ids/sw/hps-image/full-stack/notes/boot-time-fpga-debug-2026-04-13.md)
for the captured hardware evidence and rationale.

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
- notes about both:
  - the preserved `barebox` experiment
  - the current U-Boot-centered hybrid image path
