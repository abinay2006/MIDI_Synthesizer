library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity input_conditioner_tb is
end input_conditioner_tb;

architecture behavioral of input_conditioner_tb is
--=============================================================================
--Component Declaration
--===========================================================================
Component input_conditioner IS
	PORT ( 	
    	clk: in std_logic; -- 100 MHz fast clock
        input: in std_logic; --serially
        output: out std_logic --serially
       );
end Component;

    -- Signals
    signal clk    : std_logic := '0';
    signal input  : std_logic := '0';
    signal output : std_logic := '0';

    -- Clock period for 100 MHz clock
    constant CLK_PERIOD : time := 10 ns;


    -- to send all 10 bits at a time for a byte in Rx in a loop instead of individual steps;
    --start '0', 8 data bits LSB-first, stop '1'
    -- asked Claude for this part of the code 
    procedure send_byte (constant b : in std_logic_vector(7 downto 0); 
                        signal   s : out std_logic) is  
    
        begin
        s <= '0'; wait for CLK_PERIOD;             -- start bit
        for i in 0 to 7 loop
            s <= b(i); wait for CLK_PERIOD;        -- data bits, LSB first
        end loop;
        s <= '1'; wait for CLK_PERIOD;             -- stop bit
    end procedure;


begin

    uut: input_conditioner
        port map (
            clk    => clk,
            input  => input,
            output => output
        );

    -- Clock generation
    clkgen_proc: process
    begin
    
        clk <= '0';
        wait for clk_period / 2;
        
        clk <= '1';
        wait for clk_period / 2;
    
    end process clkgen_proc;

    stimulus_process : process
    begin

 -- 1)
        send_byte(x"90", input); --byte 1 on (1001)
        send_byte(x"18", input); -- byte 2 - note: C2
        send_byte(x"10", input); -- velocity

        input <= '1';        -- back to idle
        
        wait for 2*clk_period;
        -- 2) NOTE ON, C3 
        send_byte(x"90", input);
        send_byte(x"24", input);
        send_byte(x"20", input);
        input <= '1'; 
        wait for 2*clk_period;
        
          -- 3) NOTE ON, F2 
        send_byte(x"90", input);
        send_byte(x"1D", input);
        send_byte(x"20", input);
        input <= '1'; 
        wait for 2*clk_period;
        
         -- 4) NOTE ON, G# 
        send_byte(x"90", input);
        send_byte(x"2c", input);
        send_byte(x"20", input);
        input <= '1'; 
        wait for 2*clk_period;
        
        -- 5) NOTE ON, C4 
        send_byte(x"90", input);
        send_byte(x"30", input);
        send_byte(x"20", input);
        input <= '1'; 
        wait for 2*clk_period;
        
        
        -- 6) NOTE OFF, C3
        send_byte(x"80", input);
        send_byte(x"24", input);
        send_byte(x"20", input);
        input <= '1'; 
        wait for 2*clk_period;
        
        -- 6) NOTE ON, G#
        send_byte(x"90", input);
        send_byte(x"2c", input);
        send_byte(x"20", input);
        input <= '1'; 
        wait for 2*clk_period;
        

      
        wait;

    end process;

end behavioral;