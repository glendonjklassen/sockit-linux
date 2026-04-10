library ieee;
use ieee.std_logic_1164.all;

entity sockit_ids_hps_demo is
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(1 downto 0);
        LED      : out std_logic_vector(3 downto 0)
    );
end entity sockit_ids_hps_demo;

architecture rtl of sockit_ids_hps_demo is
    -- The generated Platform Designer system exposes simple external ports:
    --   keys_export -> sampled pushbuttons
    --   leds_export -> LED drive register written by the HPS
    component bridge_ledkey_probe is
        port (
            clk_clk       : in  std_logic;
            keys_export   : in  std_logic_vector(1 downto 0);
            leds_export   : out std_logic_vector(3 downto 0);
            reset_reset_n : in  std_logic
        );
    end component;
begin
    -- This is the whole board-facing wrapper:
    --   board clock -> generated HPS/FPGA bridge system
    --   board keys  -> KEY register visible to HPS software
    --   board leds  -> LED register written by HPS software
    hps_bridge_demo : bridge_ledkey_probe
        port map (
            clk_clk       => CLOCK_50,
            keys_export   => KEY,
            leds_export   => LED,
            reset_reset_n => '1'
        );
end architecture rtl;
