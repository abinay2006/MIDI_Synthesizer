--------------------------------------------------------------------------------
-- clk_divider
--------------------------------------------------------------------------------
-- Produces fs_en: a single-clock-cycle pulse, once every clocks to sample.
--
--       divider = f_clock/Fs
--

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity sample_divider is
	generic (divider_tc : integer  := 521);
    
    port (
      clk   : in  std_logic;         --  clock (25 MHz)
      reset : in  std_logic;        
      clock_en : out std_logic         -- tell if on for the accumulator
    );
end sample_divider;

architecture behavioral of sample_divider is
  signal count : unsigned(11 downto 0) := (others => '0');
  signal tc: std_logic:= '0';
begin
  process(clk)
    begin
      if rising_edge(clk) then
        if(reset = '1') then
        	count <= (others => '0');
            clock_en <= '0';
        elsif count = to_unsigned(divider_tc, 12) -1 then
            count <= (others => '0');
            clock_en <= '1';              -- one-cycle pulse on rollover
        else
          count   <= count + 1;
          clock_en <= '0';
        end if;
      end if;
      
    end process;
end behavioral;