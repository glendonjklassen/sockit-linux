#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
qsys_file="$repo_root/hw/ip/bridge_ledkey_probe.qsys"
out_dir="$repo_root/hw/ip/bridge_ledkey_probe_gen"
fixed_bridge_wrapper="$repo_root/hw/ip/bridge_ledkey_probe_bridge_0_fixed.v"
generated_bridge_wrapper="$out_dir/synthesis/submodules/bridge_ledkey_probe_bridge_0.v"
generated_system_wrapper="$out_dir/synthesis/bridge_ledkey_probe.v"

rm -rf "$out_dir"
qsys-generate "$qsys_file" \
  --synthesis=VERILOG \
  --output-directory="$out_dir" \
  --part=5CSXFC6D6F31C6

# Quartus 25.1 emits a recursive self-instantiation in the generated
# hps_bridge_avalon wrapper for this minimal bridge-only design. Replace the
# broken file with a checked-in wrapper so the flow stays reproducible.
cp "$fixed_bridge_wrapper" "$generated_bridge_wrapper"

# The generated top-level wrapper clocks the bridge fabric from the external
# 50 MHz board clock. In practice the lightweight HPS-to-FPGA path needs to
# run from an HPS-generated user clock so the bridge, interconnect, and PIOs
# share a coherent fabric clock domain.
perl -0pi -e 's/(output wire \[3:0\] leds_export,\s*\/\/\s*leds\.export\n)/$1\t\toutput wire       bridge_reset_n_export,   \/\/ bridge_reset_n.export\n\t\toutput wire       bridge_user_clk_export,  \/\/ bridge_user_clk.export\n\t\toutput wire       bridge_lw_activity_export, \/\/ bridge_lw_activity.export\n/s' \
  "$generated_system_wrapper"
perl -0pi -e 's/(wire\s+bridge_0_h2f_reset_reset;[^\n]*\n)/$1\twire         bridge_0_h2f_user0_clk;                 \/\/ bridge_0:h2f_user0_clk_export -> \\[key_pio, led_pio, mm_interconnect_0, rst_controllers\\]\n/s' \
  "$generated_system_wrapper"
perl -0pi -e 's/(wire\s+bridge_0_h2f_user0_clk;[^\n]*\n)/$1\twire         bridge_0_h2f_lw_activity;              \/\/ bridge_0:h2f_lw_activity_export -> bridge_lw_activity.export\n/s' \
  "$generated_system_wrapper"
perl -0pi -e 's/(\.h2f_rst_n\s+\(bridge_0_h2f_reset_reset\),\s*\/\/\s*h2f_reset\.reset_n\s*\n)/$1\t\t\.h2f_user0_clk_export \(bridge_0_h2f_user0_clk\),        \/\/ h2f_user0_clock_export.clk\n/s' \
  "$generated_system_wrapper"
perl -0pi -e 's/(\.h2f_user0_clk_export\s+\(bridge_0_h2f_user0_clk\),\s*\/\/\s*h2f_user0_clock_export\.clk\s*\n)/$1\t\t\.h2f_lw_activity_export \(bridge_0_h2f_lw_activity\),  \/\/ h2f_lw_activity_export.export\n/s' \
  "$generated_system_wrapper"
perl -0pi -e 's/(\.h2f_axi_clk\s+)\(clk_clk\)/$1(bridge_0_h2f_user0_clk)/g; s/(\.h2f_lw_axi_clk\s+)\(clk_clk\)/$1(bridge_0_h2f_user0_clk)/g; s/(\.f2h_axi_clk\s+)\(clk_clk\)/$1(bridge_0_h2f_user0_clk)/g; s/(\.f2h_sdram0_clk\s+)\(clk_clk\)/$1(bridge_0_h2f_user0_clk)/g; s/(\.clk_0_clk_clk\s+)\(clk_clk\)/$1(bridge_0_h2f_user0_clk)/g; s/(\.clk\s+)\(clk_clk\)/$1(bridge_0_h2f_user0_clk)/g' \
  "$generated_system_wrapper"
perl -0pi -e 's/\n\t(bridge_ledkey_probe_key_pio key_pio \()/\n\tassign bridge_reset_n_export = bridge_0_h2f_reset_reset;\n\tassign bridge_user_clk_export = bridge_0_h2f_user0_clk;\n\tassign bridge_lw_activity_export = bridge_0_h2f_lw_activity;\n\n\t$1/s' \
  "$generated_system_wrapper"
