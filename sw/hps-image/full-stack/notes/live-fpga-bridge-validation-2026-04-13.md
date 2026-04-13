# Live FPGA Bridge Validation - 2026-04-13

This note records the hardware bring-up and bridge-access results from the
live SoCKit session on April 13, 2026.

## Summary

The lightweight HPS-to-FPGA bridge itself is not fundamentally broken.

Two different FPGA images were tested while Linux stayed running:

- the Terasic SoCKit Console GHRD
- the repo-built `SoCKit-IDS.sof`

In both cases, the bridge was reachable from Linux after the FPGA was loaded
live over JTAG.

That shifts the main failure mode away from "bad bridge fabric" and toward
"FPGA not configured with the expected image during the normal SD-card boot
path."

## What Was Confirmed

The repo-owned full-stack SD image boots Linux successfully:

- `barebox 2021.07.0`
- Linux `5.11.0`
- `Welcome to Buildroot`
- `sockit login:`

The repo DTS bridge enable change is required and active:

- `/sys/class/fpga_bridge/br0/state` reported `enabled`
- `/sbin/devmem 0xFFD0501C 32` reported `0x00000005`

The board remained network-reachable during the successful live tests.

## Vendor GHRD Live Test

The Terasic reference design was programmed live over JTAG using:

- `systemcd/Demonstrations/Linux_BSP/Console/GHRD/soc_system.sof`

Known GHRD lightweight-bridge register map from `soc_system.qsys`:

- LED PIO: `0xFF210040`
- DIP switch PIO: `0xFF210080`
- Button PIO: `0xFF2100C0`

Live Linux-side result:

- `/sbin/devmem 0xFF2100C0 32` returned `0x0000000F`

This is the first direct proof that a lightweight-bridge transaction succeeds
on this board under the current Linux image when a known-good FPGA image is
loaded live.

## Repo Bitstream Live Test

The repo-built FPGA design was then programmed live over JTAG using:

- `hw/output_files/SoCKit-IDS.sof`

Live Linux-side result:

- `/sbin/devmem 0xFF200010 32` returned `0x00000003`

This shows that the repo design is also bridge-accessible when loaded into the
FPGA after Linux has already booted.

## Important Interpretation

Earlier bridge-access failures happened after power cycles where the board
booted from the repo-owned SD image, but no matching FPGA bitstream was being
loaded as part of that boot flow.

That explains the misleading behavior:

- Linux booted
- the bridge driver registered and reported `enabled`
- touching the lightweight bridge looked broken or hung

The live A/B test shows the more likely root cause is that the FPGA fabric is
not being configured automatically during normal boot, or is not being
configured with the intended repo bitstream.

## Current Working Diagnosis

The next engineering step should be to make the repo-owned boot flow load a
checked-in FPGA image automatically, most likely through the SoCFPGA FPGA
manager path rather than relying on a manual JTAG `.sof` load.

Useful ingredients already present in the environment:

- `quartus_cpf` is installed and available for `.sof` to `.rbf` conversion
- Linux exposes the FPGA manager and bridge sysfs interfaces
- the repo full-stack image already owns the SD card boot and rootfs contents

## Related Files

- `sw/hps-image/board/sockit_cyclone5/dts/socfpga_cyclone5_sockit.dts`
- `hw/ip/bridge_ledkey_probe_bridge_0_fixed.v`
- `hw/scripts/generate_bridge_ledkey_ip.sh`
- `hw/rtl/sockit_ids_hps_demo.vhd`
- `systemcd/Demonstrations/Linux_BSP/Console/GHRD/soc_system.qsys`
