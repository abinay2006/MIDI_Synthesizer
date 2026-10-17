-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;

-- entity declaration
entity SCI_FSM_tb is
end entity;

--=============================================================================
--Architecture
--=============================================================================
architecture testbench of SCI_Receiver_tb is

--=============================================================================
--Component Declaration
--===========================================================================
component SCI_Receiver is
PORT ( 	clk : in   STD_LOGIC;
		Rx	: 	in 	STD_LOGIC;
        Reset : in STD_LOGIC;
        byte1_out : out STD_LOGIC_VECTOR(7 downto 0);
        byte2_out : out STD_LOGIC_VECTOR(7 downto 0);
        byte3_out : out STD_LOGIC_VECTOR(7 downto 0);
        noteOn_out: out STD_LOGIC
        );
end component;


--=============================================================================
--Signals
--=============================================================================
		signal clk : std_logic := '0';
        signal Rx : std_logic := '1';
        signal reset: std_logic := '0';
        signal byte1_out, byte2_out, byte3_out : STD_LOGIC_VECTOR(7 downto 0):= (others => '0');
    	signal noteOn_out :  std_logic := '0';
        
        constant clk_period : time := 40 ns;
        constant BITS: integer:= 3200; --max;
        constant baud_time : time:= 32 us;
        
        
    
    -- to send all 10 bits at a time for a byte in Rx in a loop instead of individual steps;
    --start '0', 8 data bits LSB-first, stop '1'
    -- asked Claude for this part of the code 
    procedure send_byte (constant b : in std_logic_vector(7 downto 0); 
                        signal   s : out std_logic) is  
    
        begin
        s <= '0'; wait for baud_time;             -- start bit
        for i in 0 to 7 loop
            s <= b(i); wait for baud_time;        -- data bits, LSB first
        end loop;
        s <= '1'; wait for baud_time;             -- stop bit
    end procedure;

begin

uut: SCI_Receiver
	port map(
 		clk => clk,
		Rx => Rx,
        reset => reset,
        byte1_out => byte1_out,
        byte2_out  => byte2_out,
        byte3_out  => byte3_out,
        noteOn_out  => noteOn_out
        );
--=============================================================================
--clk_100MHz generation 
--=============================================================================
clkgen_proc: process
begin

	clk <= '0';
    wait for clk_period / 2;
    
   	clk <= '1';
    wait for clk_period / 2;

end process clkgen_proc;

--stimulus
--=============================================================================
    stim_proc: process begin
        -- start in reset, Rx high so idle
        reset <= '1';
        Rx    <= '1';
        wait for 4*clk_period;
        reset <= '0';
        wait for 4*clk_period;
       
        -- 1)
        send_byte(x"90", Rx); --byte 1 on (1001)
        send_byte(x"18", Rx); -- byte 2 - note: C2
        send_byte(x"10", Rx); -- velocity

        Rx <= '1';        -- back to idle
        
        wait for 2*baud_time;
        -- 2) NOTE ON, C3 
        send_byte(x"90", Rx);
        send_byte(x"24", Rx);
        send_byte(x"20", Rx);
        Rx <= '1'; 
        wait for 2*baud_time;
        
          -- 3) NOTE ON, F2 
        send_byte(x"90", Rx);
        send_byte(x"1D", Rx);
        send_byte(x"20", Rx);
        Rx <= '1'; 
        wait for 2*baud_time;
        
         -- 4) NOTE ON, G# 
        send_byte(x"90", Rx);
        send_byte(x"2c", Rx);
        send_byte(x"20", Rx);
        Rx <= '1'; 
        wait for 2*baud_time;
        
        -- 5) NOTE ON, C4 
        send_byte(x"90", Rx);
        send_byte(x"30", Rx);
        send_byte(x"20", Rx);
        Rx <= '1'; 
        wait for 2*baud_time;
        
        
        -- 6) NOTE OFF, C3
        send_byte(x"80", Rx);
        send_byte(x"24", Rx);
        send_byte(x"20", Rx);
        Rx <= '1'; 
        wait for 2*baud_time;
        
        -- 6) NOTE ON, G#
        send_byte(x"90", Rx);
        send_byte(x"2c", Rx);
        send_byte(x"20", Rx);
        Rx <= '1'; 
        wait for 2*baud_time;
        
        
        
        
        wait;             
    end process stim_proc;

end testbench;












