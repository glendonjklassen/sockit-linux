# Current System Notes

These notes capture what we have already observed from the existing, known-good
SD image and board setup.

## Hardware / Host

- Repo root: `/home/gjklassen/code/sockit-ids`
- UART device on the host: `/dev/ttyUSB0`
- Stable UART alias seen on host:
  `/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AH01ZFQF-if00-port0`
- JTAG cable seen by Quartus: `CV SoCKit [1-6]`

## FPGA Project State

- Quartus project compiles successfully with the checked-in scripts.
- Active top level is `sockit_ids_hps_demo`.
- The design uses a minimal lightweight HPS-to-FPGA bridge demo.

## HPS Boot State

- A known-good SD image boots successfully.
- Serial output confirms U-Boot SPL, U-Boot, and Linux boot on `ttyS0,115200`.
- Linux reaches a login prompt.
- Login works as `root` with no password on that image.

## Old Image Limitations

- no `gcc`
- no obvious package manager
- no `devmem` utility found
- BusyBox includes at least `wget`, `tftp`, and `nc`
- `/dev/mem` exists and is root-only

## Why This Matters

The board is healthy enough for continued HPS/FPGA work, but the existing image
is too old and too bare for efficient iteration. That is the motivation for the
new image workspace in this directory.
