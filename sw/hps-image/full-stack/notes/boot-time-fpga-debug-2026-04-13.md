# Boot-Time FPGA Debug - 2026-04-13

This note records the live hardware debugging results from the April 13, 2026
SoCKit session focused on boot-time FPGA configuration.

## Summary

The current `barebox`-based FPGA load path is not working on hardware, and the
failure is not specific to the repo bitstream.

The most important A/B result is:

- repo image `sockit_ids.rbf` fails from `barebox`
- Terasic vendor image `soc_system_vendor.rbf` also fails from `barebox`

In both cases the SoCFPGA FPGA manager times out waiting for configuration
done, and the FPGA never reaches programmed state.

That shifts the main hypothesis away from "bad repo bitstream" and toward
"wrong bootloader/programming path for this board" or a remaining board-side
boot-time configuration quirk.

## What Was Tested

The full-stack SD image was updated so the FAT boot partition contains:

- `sockit_ids.rbf`
- `soc_system_vendor.rbf`
- `zImage`
- `socfpga_cyclone5_sockit.dtb`

The `barebox` boot script was also updated so the failure moved past shell
issues and into the actual FPGA-manager transaction.

At the `barebox` prompt the following checks were performed:

- `ls /boot`
- `firmwareload -t socfpga-fpga /boot/sockit_ids.rbf`
- `firmwareload -t socfpga-fpga /boot/soc_system_vendor.rbf`
- `devinfo fpga`
- `md 0xff706000`

## Direct Hardware Results

With the updated SD image, `barebox` now consistently reaches:

- `Loading FPGA image /boot/sockit_ids.rbf`

and then fails with:

- `fpga: poll for config done failed with: Connection timed out`

Manual `barebox` tests showed the same behavior for both images:

- `/boot/sockit_ids.rbf`
- `/boot/soc_system_vendor.rbf`

`devinfo fpga` stayed at:

- `programmed: 0`

This means the FPGA never reached user mode through the `barebox`
`firmwareload` path.

## MSEL / Switch Findings

The board switch bank was rechecked during live testing.

Two different MSEL settings were tried:

- the originally reported `00001`
- all zeros, `00000`

Changing the switch state did affect the FPGA manager status register, so the
board is reacting to the strap change:

- earlier failing state: `0x0000007a`
- all-zero test: `0x000000fa`

However, even with the all-zero setting, the vendor `RBF` still failed with
the same configuration-done timeout.

That means MSEL is relevant, but it is not the whole explanation for the
current failure.

## Related Board Erratum

The repo now contains:

- `How_to_Fix_microSD_Card_Boot_NG.pdf`

That Terasic note documents a hardware issue where some boards do not boot from
microSD unless the onboard UART-to-USB is attached to a host, with a hardware
rework at `C195` as the recommended fix.

This matters for unattended SD-card boot reliability, but it does not explain
the present FPGA-manager timeout after the board has already reached
`barebox`.

Treat it as a separate board erratum, not as the root cause of the current
`firmwareload` failure.

## Follow-Up U-Boot / MSEL Validation

A later U-Boot-side debug session tightened the diagnosis further.

The Terasic `systemcd` Makefiles include an important note beside the `.rbf`
generation rule:

- the compressed raw `.rbf` flow corresponds to MSEL value `8`
- `FPGAMGRREGS_STAT` should read `0x50`
- the SoCKit switch pattern should be `up,down,up,down,up,up`

With the board initially left in the earlier switch setting, the FPGA manager
status register at U-Boot was:

- `0x0000007a`

After changing the board switches to the documented Terasic pattern and power
cycling, the same register read became:

- `0x00000050`

That confirms the board-side MSEL mode was previously wrong for the compressed
`.rbf` path, and that the later retest used the vendor-documented configuration
mode.

However, even in that corrected MSEL state, manual U-Boot tests still failed
for both images:

- `soc_system_vendor.rbf`
- `sockit_ids.rbf`

The exact manual sequence was:

- `fatload mmc 0:1 ${fpgadata} ...`
- `fpga load 0 ${fpgadata} ${filesize}`

and both returned:

- `altera_load: Failed with error code -4`

Additional observations:

- the copied `soc_system_vendor.rbf` on the generated SD image is byte-for-byte
  identical to `systemcd/Demonstrations/Linux_BSP/Console_FB/GHRD/soc_system.rbf`
- running `bridge_enable_handoff` before `fpga load` did not change the result
- after the failed load, `FPGAMGRREGS_STAT` moved from `0x50` to `0x52`, so the
  FPGA manager is reacting to the command rather than ignoring it
- during the later corrected-MSEL boot, the user also reported visible blinking
  LEDs on the board

That LED observation is important but not yet fully explained. It could mean:

- the FPGA image is actually configuring despite the `-4` return code, with the
  error reported late or for a secondary step
- the FPGA retained a previously programmed image across a reset path that did
  not fully clear configuration

That should be validated from Linux or by a deliberate cold-boot / known-state
test before treating the `fpga load` error as a false negative.

This means the current blocker is now even narrower:

- not the repo `.rbf`
- not the generated `u-boot.scr`
- not the MSEL switch setting alone

The remaining hypotheses are more likely to involve either:

- a missing board-specific precondition in this U-Boot / preloader build
- a mismatch between the generic factory SD preloader/U-Boot payload and the
  exact GHRD flow described in `systemcd/Demonstrations/Linux_BSP/*/GHRD`
- a remaining SoCKit hardware-side condition outside the obvious MSEL mode

## Reference Bootloader Clues From `systemcd/`

Inspection of `systemcd/` changed the working direction significantly.

The factory SD image and the SystemCD build files show a U-Boot-based flow,
not a `barebox firmwareload` flow:

- the factory image contains `U-Boot SPL 2013.01.01`
- the factory image contains `U-Boot 2013.01.01 for socfpga`
- the extracted environment expects:
  - `bootimage=zImage`
  - `fdtimage=socfpga.dtb`
  - `scriptfile=u-boot.scr`
- the optional boot script path is:
  - `callscript=if fatload mmc 0:1 $fpgadata $scriptfile; then source $fpgadata; ...`

The SystemCD Makefiles build a boot script that does:

- load an `.rbf` from the FAT partition
- `fpga load 0 ...`
- run `bridge_enable_handoff`
- boot Linux

The factory image layout also differs from the current repo-owned image:

- raw `0xa2` boot partition at 1 MiB
- Linux rootfs partition as DOS partition 2
- FAT boot partition as DOS partition 1

That strongly suggests the vendor-supported boot-time FPGA configuration path
depends on the preloader/U-Boot chain rather than the current `barebox`
`firmwareload` path.

## Current Direction

The next engineering step is to pivot from the current `barebox` boot-time FPGA
load attempt to a hybrid image that preserves the newer Linux stack while using
the reference-style early boot chain.

The intended hybrid shape is:

- keep the repo-owned kernel, DTB, and rootfs
- keep the repo-owned FPGA artifact generation
- replace the early boot path with a factory-style raw boot partition
- boot through U-Boot using a `u-boot.scr` that loads the FPGA image and then
  hands off to Linux

In other words:

- modern Linux stays
- the early bootloader path becomes more vendor-like

## Practical Implication

Do not spend more time trying random `barebox` shell variations around
`firmwareload`.

The important debug value from this session is already established:

- the `barebox` path fails for both repo and vendor `.rbf` images
- JTAG live programming still works
- Linux with the repo kernel and DTB is still a good baseline once the FPGA is
  configured

The remaining work should focus on reproducing the vendor preloader/U-Boot
behavior while preserving the owned Linux artifacts.
