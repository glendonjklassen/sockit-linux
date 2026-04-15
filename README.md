# sockit-linux

A reproducible FPGA + Linux development environment for the
[Terasic SoCKit](https://www.terasic.com.tw/cgi-bin/page/archive.pl?No=816)
(Intel/Altera Cyclone V SoC). Everything needed to build, flash, and interact
with the board lives in this repo: the Quartus FPGA project, a Buildroot Linux
image, and a host-side cross-compilation SDK.

The goal is a single `git clone` to working hardware: compile the FPGA design,
build an SD card image, flash it, and immediately have serial console, SSH, DHCP
networking, and a live HPS-to-FPGA bridge you can poke from Linux userspace.

## Repository Layout

| Path | What it does |
|------|-------------|
| `hw/` | Quartus project and RTL -- FPGA design with a lightweight HPS-to-FPGA bridge demo |
| `sw/hps/` | HPS userspace programs (bridge test, LED/KEY demo) |
| `sw/hps-image/` | Buildroot configs, board support, and scripts that produce the SD card image and host SDK |

## Quick Start

### 1. Build the SD image

```bash
SOCKIT_AUTHORIZED_KEYS_FILE=$HOME/.ssh/id_ed25519.pub \
  ./sw/hps-image/scripts/build-full-stack.sh --sdk
```

This produces `sw/hps-image/output-full-stack/images/sdcard-barebox.img`.
Flash it to an SD card with `dd` or your tool of choice.

The `SOCKIT_AUTHORIZED_KEYS_FILE` variable injects your SSH public key so you
can `ssh root@<board-ip>` without a password. Omit it if you only need serial
console access.

### 2. Set the board switches

The barebox boot environment loads a compressed FPGA bitstream via the SoCFPGA
FPGA manager. The MSEL DIP switches (SW10) must be set for this mode:

```
SW10:  1    2    3    4    5    6
      UP  DOWN   UP  DOWN   UP   UP
```

### 3. Boot

Insert the SD card and power on. The boot chain is:

1. **barebox xload** -- initialises SDRAM, loads barebox from the FAT partition
2. **barebox** -- loads the FPGA bitstream (`sockit.rbf`), then hands off to Linux
3. **Linux 5.11** -- Buildroot musl rootfs, serial console on `ttyS0` at 115200, DHCP on `eth0`

Default login is `root` with no password (serial and SSH).

### 4. Compile the FPGA design (optional)

Only needed if you modify the RTL. Requires Quartus.

```bash
./hw/scripts/compile_hw.sh
```

## FPGA Design

The top level is `hw/rtl/sockit_hps_demo.vhd` -- a wrapper around a Platform
Designer system that exposes LED and KEY registers on the lightweight
HPS-to-FPGA bridge, plus board-level status indicators.

Register map (lightweight bridge base `0xFF200000`):

| Offset | Register | Description |
|--------|----------|-------------|
| `+0x00` | LED PIO | Low 4 bits: `LED[3:0]` (active in the Avalon fabric; physical LEDs are driven by bridge-health logic) |
| `+0x10` | KEY PIO | Low 2 bits: `KEY[1:0]` pushbutton state (active low) |

Physical LED indicators on the board:

| LED | Meaning |
|-----|---------|
| LED[0] | FPGA heartbeat (board 50 MHz oscillator) |
| LED[1] | HPS bridge user-clock heartbeat |
| LED[2] | Lightweight bridge reset released |
| LED[3] | Recent lightweight bridge transaction detected |

## HPS Bridge Demo

Cross-compile on the host using the exported SDK, then deploy over SSH:

```bash
# source the SDK environment-setup script first
arm-buildroot-linux-musleabihf-gcc -O2 -Wall \
  -o hps_fpga_ledkey_demo sw/hps/hps_fpga_ledkey_demo.c
scp hps_fpga_ledkey_demo root@<board-ip>:~
ssh root@<board-ip> ./hps_fpga_ledkey_demo
```

Or test the bridge directly from the board:

```bash
ssh root@<board-ip>
devmem 0xFF200010 32   # read KEY register
devmem 0xFF200000 32 0x05   # write LED register
```

## More Details

- [sw/hps-image/README.md](sw/hps-image/README.md) -- build workflow and manual steps
- [sw/hps-image/STATUS.md](sw/hps-image/STATUS.md) -- current validation state and board requirements
- [sw/hps-image/full-stack/README.md](sw/hps-image/full-stack/README.md) -- full-stack image internals and DTS notes
