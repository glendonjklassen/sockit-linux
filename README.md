# sockit-ids
An IDS project for SoCKit for sandbox and learning purposes.

## Active HPS Image Work

The active software-stack effort in this repo is now the full-stack SoCKit HPS
image under [sw/hps-image/](/home/gjklassen/code/sockit-ids/sw/hps-image/README.md).

The primary build entry point is:

```bash
./sw/hps-image/scripts/build-full-stack.sh --sdk
```

That workflow is intended to generate a complete SD image from repo-managed
artifacts. The older rootfs-first path remains available only as a fallback
comparison against the preserved vendor boot chain.

## First Bring-Up

The first FPGA image in this repo is a simple VHDL learner exercise for the SoCKit board.

- Top level: [hw/rtl/sockit_ids_blink.vhd](./hw/rtl/sockit_ids_blink.vhd)
- Clock input: `CLOCK_50` on `PIN_AF14`
- LEDs: `LED[3:0]` on `PIN_AD7`, `PIN_AE11`, `PIN_AD10`, `PIN_AF10`
- Pushbuttons: `KEY[1:0]` on `PIN_AE12`, `PIN_AE9`
- Timing constraint: [hw/SoCKit-IDS.sdc](./hw/SoCKit-IDS.sdc) defines `CLOCK_50` as 50 MHz

From the repo root:

```bash
./hw/scripts/compile_hw.sh
./hw/scripts/program_hw.sh 1
```

If the board and cable are visible to Quartus:

- Press `KEY[1]` to increment the 4-bit event counter once per press
- Press `KEY[0]` to clear the counter
- `LED[3:0]` display the current count in binary

This is the first interactive baseline before we add IDS-specific logic.

## HPS to FPGA

The next step in the repo is a minimal HPS-to-FPGA demo using the lightweight bridge.

- FPGA top wrapper: [hw/rtl/sockit_ids_hps_demo.vhd](./hw/rtl/sockit_ids_hps_demo.vhd)
- Platform Designer system: [hw/ip/bridge_ledkey_probe.qsys](./hw/ip/bridge_ledkey_probe.qsys)
- Generated IP output: [hw/ip/bridge_ledkey_probe_gen/](./hw/ip/bridge_ledkey_probe_gen/)
- HPS userspace demo: [sw/hps/hps_fpga_ledkey_demo.c](./sw/hps/hps_fpga_ledkey_demo.c)

Register map on the lightweight bridge base `0xFF200000`:

- `0xFF200000`: LED output register, low 4 bits drive `LED[3:0]`
- `0xFF200010`: KEY input register, low 2 bits reflect `KEY[1:0]`

### File Map

These are the files worth reading first:

- [hw/ip/bridge_ledkey_probe.qsys](./hw/ip/bridge_ledkey_probe.qsys): Platform Designer system definition
- [hw/rtl/sockit_ids_hps_demo.vhd](./hw/rtl/sockit_ids_hps_demo.vhd): handwritten top-level wrapper for board pins
- [sw/hps/hps_fpga_ledkey_demo.c](./sw/hps/hps_fpga_ledkey_demo.c): tiny Linux userspace test program

These are generated and mostly tool noise:

- [hw/ip/bridge_ledkey_probe_gen/](./hw/ip/bridge_ledkey_probe_gen/)
- `hw/ip/*.sopcinfo`

### End-to-End Walkthrough

The full path is:

1. The HPS program maps the lightweight bridge base at `0xFF200000`.
2. The HPS program writes the LED register at offset `0x0000`.
3. Platform Designer routes that write to `led_pio`.
4. The generated system drives `leds_export`.
5. The VHDL top-level connects `leds_export` to the board `LED[3:0]`.

The button path works in reverse:

1. The board pushbuttons enter the VHDL top-level as `KEY[1:0]`.
2. The VHDL top-level connects them to `keys_export`.
3. Platform Designer exposes that through `key_pio` at offset `0x0010`.
4. The HPS program reads that register and prints the sampled value.

### Where To Click

- [sw/hps/hps_fpga_ledkey_demo.c](./sw/hps/hps_fpga_ledkey_demo.c)
  - `LW_BRIDGE_BASE`, `LED_OFFSET`, and `KEY_OFFSET` define the software-visible addresses
  - `mmap(...)` maps the bridge window
  - `*led_reg = value;` writes the FPGA LED register
  - `*key_reg` reads the FPGA KEY register
- [hw/ip/bridge_ledkey_probe.qsys](./hw/ip/bridge_ledkey_probe.qsys)
  - `bridge_0` is the HPS bridge block
  - `LWH2F_Enable` turns on the lightweight bridge
  - `led_pio` is mapped at base `0x0000`
  - `key_pio` is mapped at base `0x0010`
- [hw/rtl/sockit_ids_hps_demo.vhd](./hw/rtl/sockit_ids_hps_demo.vhd)
  - `keys_export => KEY` connects board pushbuttons into the generated system
  - `leds_export => LED` connects the generated LED output back to board LEDs

Generate the bridge IP and compile from the repo root:

```bash
./hw/scripts/generate_bridge_ledkey_ip.sh
./hw/scripts/compile_hw.sh
./hw/scripts/program_hw.sh "CV SoCKit [1-6]" 1
```

Then, on the HPS Linux side, build and run:

```bash
gcc -O2 -Wall -o hps_fpga_ledkey_demo sw/hps/hps_fpga_ledkey_demo.c
sudo ./hps_fpga_ledkey_demo
```

If the lightweight bridge is disabled by Linux, enable it first using your board's FPGA bridge controls and then rerun the demo.
