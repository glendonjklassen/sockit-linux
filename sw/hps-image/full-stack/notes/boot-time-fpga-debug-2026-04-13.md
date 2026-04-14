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
