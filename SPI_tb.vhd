-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;

-- entity declaration
entity spi_transmitter_tb is
end entity;

--=============================================================================
--Architecture
--=============================================================================
architecture testbench of spi_transmitter_tb is

--=============================================================================
--Component Declaration
--===========================================================================
component SPI_Transmitter is
PORT ( 	clk		: 	in 	STD_LOGIC; 
        SPI_en 	: 	in 	STD_LOGIC;
        Data_in : 	in	STD_LOGIC_VECTOR(15 downto 0);
		MOSI	: 	out STD_LOGIC;
		CS		:	out	STD_LOGIC);
end component;

--=============================================================================
--Signals
--=============================================================================
		signal clk_in, MOSI : STD_LOGIC := '0';
        signal SPI_en, CS, sys_clk : STD_LOGIC := '0';
        signal Data_in : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
        
        constant clk_period : time := 10 ns;
begin

uut: SPI_Transmitter
	port map(
		clk 		=>  clk_in,
        SPI_en 		=> SPI_en,
        Data_in 	=> Data_in,
		MOSI		=> MOSI,
		CS			=> CS);

--=============================================================================
--clk_100MHz generation 
--=============================================================================
clkgen_proc: process
begin

	clk_in <= '0';
    wait for clk_period / 2;
    
   	clk_in <= '1';
    wait for clk_period / 2;

end process clkgen_proc;

--stimulus
--=============================================================================
stim_proc: process
begin

	wait for 2*clk_period;
    
    -- load data. Nothing happens until enabled
    Data_in <= "0011011100111110";
    wait for 2*clk_period;
    --enable the transmission for 1 clock cycle
  	SPI_en <= '1';
  	wait for clk_period;
  	SPI_en <= '0';
    
    wait;

end process stim_proc;

end testbench;

