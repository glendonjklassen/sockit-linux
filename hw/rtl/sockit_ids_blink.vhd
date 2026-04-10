library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sockit_ids_blink is
    port (
        CLOCK_50 : in  std_logic;
        LED      : out std_logic_vector(3 downto 0)
    );
end entity sockit_ids_blink;

architecture rtl of sockit_ids_blink is
    signal counter : unsigned(25 downto 0) := (others => '0');
begin
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            counter <= counter + 1;
        end if;
    end process;

    LED(0) <= std_logic(counter(25));
    LED(1) <= std_logic(counter(24));
    LED(2) <= std_logic(counter(23));
    LED(3) <= std_logic(counter(22));
end architecture rtl;
