# Status

## Current Image

The primary build produces `sdcard-barebox.img` via:

```bash
./sw/hps-image/scripts/build-full-stack.sh --sdk
```

The image is a fully repo-owned stack: barebox xload, barebox main image with
custom environment, Linux 5.11 (SoCKit DTS), Buildroot musl rootfs, and the
repo FPGA bitstream (`sockit.rbf`) all generated from this repo.

## Validated (2026-04-15)

Full board validation on the barebox-owned image:

- `sdcard-barebox.img` boots to a root login on the SoCKit serial console
- barebox `firmwareload` loads the FPGA bitstream successfully
- FPGA Manager Status register (`0xFF706000`) reads `0x0054`: MSEL correct,
  mode = User Mode (FPGA configured)
- Kernel reports `Linux sockit 5.11.0`, model `Terasic SoCkit`, 2 CPUs (SMP)
- Zero dmesg errors or warnings on clean boot
- Lightweight HPS-to-FPGA bridge enabled (sysfs state: `enabled`)
- Bridge register read/write verified:
  - LED PIO at `0xFF200000`: write `0x0F`, readback `0x0F`
  - KEY PIO at `0xFF200010`: reads `0x03` (both buttons unpressed)
  - LED[3] activity indicator confirmed blinking on bridge transactions
- `eth0` comes up via DHCP (1 Gbps link)
- Internet reachable (ping 8.8.8.8, ~25 ms)
- `sshd` is active, key-based root login works
- Host cross-compilation via the exported Buildroot SDK works
- SSH deploy and run of `hps_fpga_ledkey_demo` works against the live bridge
- Rootfs: ext4, 487 MB, 5% used
- RAM: 1 GB total, 15 MB used at idle

## Board Requirements

### UART / JTAG

- Serial console: `/dev/ttyUSB0` at 115200 baud (stable alias:
  `/dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AH01ZFQF-if00-port0`)
- JTAG cable: `CV SoCKit [1-6]`

### MSEL Switches (required for FPGA load)

The barebox `firmwareload` path uses the SoCFPGA FPGA manager with a compressed
raw `.rbf`. The board must be strapped for this mode:

```
SW10:  1    2    3    4    5    6
      UP  DOWN   UP  DOWN   UP   UP
```

`FPGAMGRREGS_STAT` at `0xff706000` reads `0x0050` before FPGA configuration
(mode = 0) and `0x0054` after successful configuration (mode = 4, User Mode).
The MSEL bits [7:3] are `01010` in both cases.

### Login

- Username: `root`, no password (serial and SSH)
- SSH requires a key. Inject one at build time:
  ```bash
  SOCKIT_AUTHORIZED_KEYS_FILE=~/.ssh/id_ed25519.pub \
    ./sw/hps-image/scripts/build-full-stack.sh --sdk
  ```

## Next Steps

1. Rename FPGA bitstream from `sockit_ids.rbf` to `sockit.rbf` in the boot
   environment to match the repo rename, and rebuild/revalidate.
2. Explore adding userspace tools for runtime FPGA reconfiguration.
3. Expand the bridge demo with more interesting peripherals in the FPGA fabric.
