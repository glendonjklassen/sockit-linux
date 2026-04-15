library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sockit_blink is
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(1 downto 0);
        LED      : out std_logic_vector(3 downto 0)
    );
end entity sockit_blink;

architecture rtl of sockit_blink is
    signal event_count    : unsigned(3 downto 0) := (others => '0');
    signal key1_sync      : std_logic := '1';
    signal key1_previous  : std_logic := '1';
begin
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            key1_previous <= key1_sync;
            key1_sync <= KEY(1);

            if KEY(0) = '0' then
                event_count <= (others => '0');
            elsif (key1_previous = '1') and (key1_sync = '0') then
                event_count <= event_count + 1;
            end if;
        end if;
    end process;

    LED <= std_logic_vector(event_count);
end architecture rtl;
