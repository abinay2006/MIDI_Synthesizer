-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 

ENTITY input_conditioner IS
	PORT ( 	
    	clk: in std_logic; -- 25 MHz clock
        input: in std_logic; --serially
        output: out std_logic --serially
       );
end input_conditioner;
--Go through two registers
Architecture behavioral of input_conditioner is
    signal reg1 : std_logic := '0';
    signal reg2 : std_logic := '0';
    
    begin
    
    process(clk) begin
    	if(rising_edge(clk)) then
        	reg1 <= input;
            reg2 <= reg1;
        end if;
        
    end process;
    output <= reg2;
    
end behavioral;