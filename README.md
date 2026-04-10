# sockit-ids
An IDS project for SoCKit for sandbox and learning purposes.

## First Bring-Up

The first FPGA image in this repo is a simple VHDL LED heartbeat for the SoCKit board.

- Top level: `hw/rtl/sockit_ids_blink.vhd`
- Clock input: `CLOCK_50` on `PIN_AF14`
- LEDs: `LED[3:0]` on `PIN_AD7`, `PIN_AE11`, `PIN_AD10`, `PIN_AF10`
- Timing constraint: `hw/SoCKit-IDS.sdc` defines `CLOCK_50` as 50 MHz

From the repo root:

```bash
quartus_sh --flow compile hw/SoCKit-IDS
quartus_pgm -m jtag -c 1 -o "p;hw/output_files/SoCKit-IDS.sof"
```

If the board and cable are visible to Quartus, the four user LEDs should blink at different rates.

This gives us a known-good hardware baseline before we add IDS-specific logic.
