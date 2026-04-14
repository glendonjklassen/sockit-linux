# Barebox Retrospective - 2026-04-14

This note records what the repo-owned `barebox` work achieved, what failed on
hardware, and how to preserve that work while the main image path pivots back
to a Terasic-style preloader/U-Boot handoff.

## Short Version

The `barebox` work was not wasted.

It delivered three useful outcomes:

- it proved the SoCKit can boot a repo-owned kernel, DTB, and Buildroot rootfs
  from a repo-generated SD image
- it identified the correct SoCKit first-stage target,
  `socfpga-xload_defconfig`, instead of the wrong SoCDK xload image
- it narrowed the remaining boot-time FPGA problem to the `barebox`
  FPGA-manager load path rather than to the repo bitstream itself

What failed was narrower than "barebox does not work":

- `barebox` Linux boot worked
- `barebox` boot-time FPGA configuration did not

That distinction matters for future work.

## What Was Proven

The April 12 hardware session already showed that the corrected `barebox`
early-boot path can:

- reach `barebox 2021.07.0`
- load the SoCKit DTB
- pass a valid Linux command line
- boot Linux 5.11
- mount the Buildroot root filesystem
- reach a serial login prompt

That means the repo-owned image was not fundamentally blocked on SoCKit SPL /
SD-card bring-up once the correct xload target was selected.

## What Failed

The April 13 FPGA-loading session showed that `barebox` fails at a specific
later step:

- loading an `.rbf` via `firmwareload -t socfpga-fpga`

The important A/B result was:

- the repo `sockit_ids.rbf` failed
- the Terasic vendor `soc_system_vendor.rbf` also failed

Both timed out waiting for configuration-done.

That makes the current failure much more likely to be one of:

- a board-specific requirement in the SoCFPGA FPGA-manager path under
  `barebox`
- a missing precondition normally established by the vendor preloader/U-Boot
  flow before `fpga load`
- a remaining SoCKit-specific boot-time handoff quirk around bridges, manager
  state, or strap interpretation

## Why Pivot To U-Boot Now

The SystemCD material and vendor image strings show that the factory-supported
boot-time FPGA flow is U-Boot based:

- load `.rbf` from the FAT partition
- `fpga load 0 ...`
- `run bridge_enable_handoff`
- load kernel and DTB
- boot Linux

That is a closer match to the path known to work on actual SoCKit hardware.

Since the project goal right now is a dependable HPS/FPGA development image,
the lowest-risk move is:

- keep the repo-owned kernel, DTB, rootfs, and FPGA artifact generation
- preserve the vendor raw boot partition and U-Boot chain
- generate a `u-boot.scr` that mirrors the vendor FPGA-load sequence

## How The Barebox Work Is Still Useful

Even after this pivot, the `barebox` work remains valuable in four ways:

1. It is the best documented proof that the SoCKit can boot a fully owned
   Linux stack from repo-built artifacts.
2. It remains a candidate path for eventual full early-boot ownership if the
   FPGA-manager mismatch can be explained and corrected later.
3. It provides a pre-Linux shell that may still be useful for low-level SD,
   DTB, and memory/register debugging.
4. It already captured the correct SoCKit xload choice, which prevents us from
   repeating the earlier SoCDK-target mistake.

## Recommended Project Stance

For now:

- keep `barebox-env/` and the associated notes in the repo
- treat the `barebox` flow as a documented experimental path, not the default
- make the vendor-style U-Boot handoff the primary workflow for boot-time FPGA
  loading

Only return to `barebox` as the primary path if one of these happens:

- we discover the exact missing SoCKit-specific FPGA-manager prerequisite
- we decide full early-boot ownership is worth more than near-term development
  velocity
- we no longer need boot-time FPGA configuration there and only need `barebox`
  to hand off to Linux
