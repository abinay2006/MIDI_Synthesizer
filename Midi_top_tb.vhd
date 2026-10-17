--------------------------------------------------------------------------------
-- overall_top_level_tb.vhd


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity overall_top_level_tb is
end overall_top_level_tb;

architecture behavioral of overall_top_level_tb is

component overall_top_level is
    generic(
	CLOCK_DIVIDER_RATIO: integer := 4);
    PORT ( 	
	clk_ext_port : in std_logic; -- 100 MHz fast clock
    dataIn_midi_Rx : in std_logic;
    reset : in std_logic;
    
    --DDS_gen_en, midi2m_lookup_en : in std_logic;
    cs : out std_logic;
    MOSI : out std_logic;
    spi_sclk_ext_port : out std_logic
    );
    end component;

    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';
    signal rx : std_logic := '1';   -- serial line idle
    signal sclk    : std_logic;
    signal cs      : std_logic;
    signal mosi    : std_logic;

    -- timing
    constant clk_period : time := 10 ns;    -- 100 MHz
    constant baud_time : time := 32 us;    -- baud


    -- drive one MIDI byte: start(0) + 8 data LSB-first + stop(1) 
    -- used claude for this loop function
    procedure send_byte(constant b : in std_logic_vector(7 downto 0);
                        signal rx_send : out std_logic) is
    begin
        rx_send <= '0';                       -- start bit
        wait for baud_time;
        for i in 0 to 7 loop             -- data, LSB first
            rx_send <= b(i);
            wait for baud_time;
        end loop;
        rx_send <= '1';                       -- stop bit
        wait for baud_time;
    end procedure;

begin


  uut : overall_top_level
      port map ( clk_ext_port            => clk,
                dataIn_midi_Rx => rx,
                reset          => reset,
                spi_sclk_ext_port           => sclk,
                cs             => cs,
                MOSI           => mosi );

    ----------------------------------------------------------------------------
    -- 100 MHz clock
    ----------------------------------------------------------------------------
    clkgen_proc: process
     begin

        clk <= '0';
        wait for clk_period / 2;

        clk <= '1';
        wait for clk_period / 2;

    end process clkgen_proc;

    ----------------------------------------------------------------------------
    -- stimulus
    ----------------------------------------------------------------------------
    stim_proc: process begin
        -- start in reset, Rx high so idle
        reset <= '1'; --check reset
        Rx    <= '1';
        wait for 4*clk_period;
        reset <= '0';
        wait for 4*clk_period;
       
        -- 1) NOTE ON C2 - the lowest on the keyboard given
        send_byte(x"90", Rx); --byte 1 on (1001)
        send_byte(x"18", Rx); -- byte 2 - note: C2
        send_byte(x"10", Rx); -- velocity

        Rx <= '1';        -- back to idle
        
        wait for 30 ms;
        -- 2) NOTE ON, F3
        send_byte(x"90", Rx);
        send_byte(x"29", Rx);
        send_byte(x"20", Rx);
        Rx <= '1'; 
        wait for 30 ms;
        
        -- 3) NOTE OFF, C4 
        send_byte(x"80", Rx);
        send_byte(x"30", Rx);
        send_byte(x"20", Rx);
        Rx <= '1'; 
        wait for 10 ms;
          -- 4) NOTE ON, C4 
        send_byte(x"90", Rx);
        send_byte(x"30", Rx);
        send_byte(x"20", Rx);
        Rx <= '1'; 
        wait for 30 ms;
        reset <= '1';
  
        
       --wait for 2 ms;
        
--         -- 4) NOTE ON, G# 
--        send_byte(x"90", Rx);
--        send_byte(x"2c", Rx);
--        send_byte(x"20", Rx);
--        Rx <= '1'; 
--        wait for 2 ms;
        
--        -- 5) NOTE ON, C4 
--        send_byte(x"90", Rx);
--        send_byte(x"30", Rx);
--        send_byte(x"20", Rx);
--        Rx <= '1'; 
--       wait for 2 ms;
        
        
--        -- 6) NOTE OFF, C3
--        send_byte(x"80", Rx);
--        send_byte(x"24", Rx);
--        send_byte(x"20", Rx);
--        Rx <= '1'; 
--        wait for 2 ms;
        
--        -- 6) NOTE ON, G#
--        send_byte(x"90", Rx);
--        send_byte(x"2c", Rx);
--        send_byte(x"20", Rx);
--        Rx <= '1'; 
--        wait for 2 ms;
        
        wait;             
    end process stim_proc;

end behavioral;