# Full-Stack Ownership Track

This directory contains the Buildroot configs and board support files for the
primary SoCKit image: a fully repo-owned stack using barebox, a 5.11 kernel
with the upstream SoCKit DTS, and a Buildroot musl rootfs.

## Build

```bash
./sw/hps-image/scripts/build-full-stack.sh --sdk
```

Output: `sw/hps-image/output-full-stack/images/sdcard-barebox.img`

## What Gets Built

- `barebox-socfpga-sockit-xload.img` — first-stage loader (raw `0xa2` partition)
- `barebox-socfpga-sockit.img` — main barebox binary (on FAT partition)
- `barebox-env` — compiled environment with FPGA load script
- `zImage` and `socfpga_cyclone5_sockit.dtb` — kernel and SoCKit DTB
- `sockit.rbf` — compressed FPGA bitstream (converted from SOF by `quartus_cpf`)
- `sdcard-barebox.img` — complete SD image (xload + FAT boot + ext2 rootfs)

## Board Strap Requirement

The barebox `firmwareload` path requires the board strapped for compressed `.rbf`
configuration mode:

```
SW10:  1    2    3    4    5    6
      UP  DOWN   UP  DOWN   UP   UP
```

`FPGAMGRREGS_STAT` at `0xff706000` must read `0x00000050` (MSEL = 8).
Verify at the bootloader prompt: `md.w 0xff706000 1`

Any other strap value causes the FPGA manager to time out.

## Key Files

- `configs/sockit_cyclone5_full_stack_defconfig` — Buildroot defconfig
- `../board/sockit_cyclone5/genimage-barebox.cfg` — SD image partition layout
- `../board/sockit_cyclone5/barebox-env/` — barebox boot environment
- `../board/sockit_cyclone5/post-image.sh` — converts SOF to RBF, runs genimage
- `../board/sockit_cyclone5/dts/` — repo-owned SoCKit DTS

## DTS Note

The defconfig targets the upstream SoCKit DTS
(`socfpga_cyclone5_sockit.dts`), with a repo-owned overlay under
`board/sockit_cyclone5/dts/` that explicitly enables the lightweight
HPS-to-FPGA bridge. The upstream DTS leaves that bridge disabled; accessing
`0xFF200000` from Linux with the bridge still disabled can wedge the board.

## Fallback Reference

The Buildroot tree includes `configs/terasic_de10nano_cyclone5_defconfig` as a
closely related Cyclone V reference. It is not used directly but is a useful
guide for SoCFPGA partition conventions and kernel integration patterns.
