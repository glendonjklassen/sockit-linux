library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
    --   bridge_*    -> HPS bridge status signals for board-side instrumentation
    component bridge_ledkey_probe is
        port (
            clk_clk                   : in  std_logic;
            keys_export               : in  std_logic_vector(1 downto 0);
            leds_export               : out std_logic_vector(3 downto 0);
            bridge_reset_n_export     : out std_logic;
            bridge_user_clk_export    : out std_logic;
            bridge_lw_activity_export : out std_logic;
            reset_reset_n             : in  std_logic
        );
    end component;

    signal bridge_reset_n     : std_logic;
    signal bridge_user_clk    : std_logic;
    signal bridge_lw_activity : std_logic;

    signal board_hb_counter   : unsigned(25 downto 0) := (others => '0');
    signal bridge_hb_counter  : unsigned(25 downto 0) := (others => '0');
    signal bridge_activity_ts : unsigned(24 downto 0) := (others => '0');
begin
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            board_hb_counter <= board_hb_counter + 1;
        end if;
    end process;

    process (bridge_user_clk, bridge_reset_n)
    begin
        if bridge_reset_n = '0' then
            bridge_hb_counter  <= (others => '0');
            bridge_activity_ts <= (others => '0');
        elsif rising_edge(bridge_user_clk) then
            bridge_hb_counter <= bridge_hb_counter + 1;

            if bridge_lw_activity = '1' then
                bridge_activity_ts <= (others => '1');
            elsif bridge_activity_ts /= (bridge_activity_ts'range => '0') then
                bridge_activity_ts <= bridge_activity_ts - 1;
            end if;
        end if;
    end process;

    -- This is the whole board-facing wrapper:
    --   board clock -> generated HPS/FPGA bridge system
    --   board keys  -> KEY register visible to HPS software
    --   board leds  -> heartbeat and bridge-health indicators
    hps_bridge_demo : bridge_ledkey_probe
        port map (
            clk_clk                   => CLOCK_50,
            keys_export               => KEY,
            leds_export               => open,
            bridge_reset_n_export     => bridge_reset_n,
            bridge_user_clk_export    => bridge_user_clk,
            bridge_lw_activity_export => bridge_lw_activity,
            reset_reset_n             => '1'
        );

    -- LED map:
    --   LED[0] = FPGA heartbeat from the board oscillator
    --   LED[1] = HPS bridge user-clock heartbeat
    --   LED[2] = lightweight bridge reset released
    --   LED[3] = recent lightweight bridge transaction seen
    LED(0) <= std_logic(board_hb_counter(board_hb_counter'high));
    LED(1) <= std_logic(bridge_hb_counter(bridge_hb_counter'high));
    LED(2) <= bridge_reset_n;
    LED(3) <= '1' when bridge_activity_ts /= (bridge_activity_ts'range => '0') else '0';
end architecture rtl;
