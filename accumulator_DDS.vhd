--------------------------------------------------------------------------------
-- phase_accumulator
--------------------------------------------------------------------------------
-- adds m and wraps around
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accumulator is
	port(
    	clk: in STD_Logic;
        reset: in STD_Logic;
        clock_en: in STD_Logic;
    	m: in unsigned(15 downto 0); --from lookup - to add to accumulator
        address: out std_logic_vector(15 downto 0) --passing to rom, make it 12 bits
        );
end accumulator;

architecture behavioral of accumulator is
	signal accum: unsigned(15 downto 0):= (others =>'0');
    
    begin
    	process(clk) begin
          if(rising_edge(clk)) then
              if(reset = '1') then
                  accum <=  (others =>'0');
              elsif(clock_en = '1') then
                  accum <= accum+m; --adding the corresponding increment value at each sample clock rise
              else
                  accum <= accum;
              end if;

           end if;
      end process;
      address<= std_logic_vector(accum);
end behavioral;
            
	




























