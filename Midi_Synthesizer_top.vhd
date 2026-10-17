-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; -- change the signed bit opposite to what it is

--   midi_rx --> input_conditioner --> SCI --> DDS_Data_Gen --> SPI --> PmodDA2

ENTITY overall_top_level IS
generic(
	CLOCK_DIVIDER_RATIO : integer := 4);
PORT ( 	
	clk_ext_port : in std_logic; -- 100 MHz fast clock
    dataIn_midi_Rx : in std_logic;
    reset : in std_logic;
    
    --DDS_gen_en, midi2m_lookup_en : in std_logic;
    cs : out std_logic;
    MOSI : out std_logic;
    spi_sclk_ext_port : out std_logic
    );
end overall_top_level;

architecture structural of overall_top_level is
-- signals that connect components together
-- sci
    signal clk          : std_logic; -- system clock (scaled down by divider)
    signal rx_sync     : std_logic;                      -- synchronized MIDI out
    signal byte2        : std_logic_vector(7 downto 0);  -- note number
    signal note_num     : std_logic_vector(6 downto 0);
    signal note_on      : std_logic;                     
 
 -- dds
    signal sin_DDS      : std_logic_vector(15 downto 0); -- signed sine sample from DDS
    signal dds_valid    : std_logic;
 
 -- SPI
    signal cs_sel       : std_logic;          -- CS output   
    
 -- CLK DIVIDER
    constant div       : integer := 4;      
 

-- declare all components
component sample_divider is -- divider for DDS samplin
   generic ( divider_tc : integer := 521 );
     port ( clk      : in  std_logic;
            reset    : in  std_logic;
            clock_en : out std_logic );
end component;
 
component input_conditioner is -- add this and fix later
	port(
    	clk: in STD_Logic;
    	input: in STD_Logic; -- each byte at a time serially
        output : out std_logic --coming out of the synchronizer
        );
end component;

COMPONENT SCI_Receiver
GENERIC(
	constant MAX1 : integer:= 400;
    constant MAX2 : integer:= 800);
PORT ( 	clk : in   STD_LOGIC;
		Rx	: 	in 	STD_LOGIC;
        Reset : in STD_LOGIC;
        byte1_out : out STD_LOGIC_VECTOR(7 downto 0);
        byte2_out : out STD_LOGIC_VECTOR(7 downto 0);
        byte3_out : out STD_LOGIC_VECTOR(7 downto 0);
        noteOn_out: out STD_LOGIC
        );
END COMPONENT;

COMPONENT DDS_Data_Gen
    GENERIC (sampling_freq : in integer := 521);
  PORT (
	clk : in std_logic; -- 25 MHz
    clk_reset : in std_logic;
    accum_reset : in std_logic;
	midi_note_number : in std_logic_vector(6 downto 0);
    DDS_gen_en, midi2m_lookup_en : in std_logic;
    dds_sine : out std_logic_vector(15 downto 0);
    m_axis_data_tvalid : out std_logic
  );
END COMPONENT;

COMPONENT SPI_Transmitter
PORT ( 	clk		: 	in 	STD_LOGIC; 
        SPI_en 	: 	in 	STD_LOGIC;
        Data_in : 	in	STD_LOGIC_VECTOR(15 downto 0);
		MOSI	: 	out STD_LOGIC;
		CS		:	out	STD_LOGIC
        );
END COMPONENT;

-- system clock divider
component system_clock_generator is
	generic (
	   CLOCK_DIVIDER_RATIO : integer := CLOCK_DIVIDER_RATIO);
    port (
        input_clk_port		: in  std_logic;
        system_clk_port	    : out std_logic;
		fwd_clk_port		: out std_logic);
end component;


begin -- instantiate all the components
            
System_Synchronizer : input_conditioner
  port map ( clk    => clk,
            input  => dataIn_midi_Rx,
            output => rx_sync);
            
System_SCI : SCI_Receiver
    port map ( clk       => clk,
              Rx         => rx_sync,
              Reset      => reset,
              byte1_out  => open,
              byte2_out  => byte2,
              byte3_out  => open,
              noteOn_out => note_on);

note_num <= byte2(6 downto 0);   -- convert byte2 (8 bits) to 7 bits to map to the dds: 0 to 127 7 bits

System_DDS : DDS_Data_Gen
  port map ( clk                => clk,
            clk_reset          => reset,
            accum_reset        => reset,
            midi_note_number   => note_num,
            DDS_gen_en         => note_on,
            midi2m_lookup_en   => note_on,
            dds_sine           => sin_DDS,
            m_axis_data_tvalid => dds_valid );


System_SPI : SPI_Transmitter
  port map ( clk     => clk,
            SPI_en  => dds_valid,
            Data_in => sin_DDS,
            MOSI    => MOSI,
            CS      => cs);
            
clocking: system_clock_generator 
generic map(
	CLOCK_DIVIDER_RATIO => CLOCK_DIVIDER_RATIO)             
port map(
	input_clk_port 		=> clk_ext_port,
	system_clk_port 	=> clk,
	fwd_clk_port		=> spi_sclk_ext_port);



 

end structural;
        
        