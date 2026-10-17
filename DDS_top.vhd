-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY DDS_Data_Gen IS
GENERIC (sampling_freq : in integer := 521); --based on the 48Khz Fs and the 25MHz clock rate
PORT ( 	
	clk : in std_logic; 
    clk_reset : in std_logic;
    accum_reset : in std_logic;
	midi_note_number : in std_logic_vector(6 downto 0); -- 0 to 127
    DDS_gen_en, midi2m_lookup_en : in std_logic;
    dds_sine : out std_logic_vector(15 downto 0);
    m_axis_data_tvalid : out std_logic);
end DDS_Data_Gen;


architecture structural of DDS_Data_Gen is
signal clk_sampling : std_logic := '0'; -- scaled down system clock for DDS sampling
signal m_lookup : std_logic_vector(15 downto 0);
signal DDS_addr : std_logic_vector(15 downto 0);
signal dds_sine_int: std_logic_vector(15 downto 0);

-- declare all components
component sample_divider is
  generic ( divider_tc : in integer := 521);
  port (
    clk   : in  std_logic;         --  clock (25MHz)
    reset : in  std_logic;        
    clock_en : out std_logic         -- tell if on for the accumulator to add at the sample clock rise
  );
end component;

component accumulator is
	port(
    	clk: in STD_Logic;
        reset: in STD_Logic;
        clock_en: in STD_Logic;
    	m: in unsigned(15 downto 0); --from lookup - to add to accumulator
        address: out std_logic_vector(15 downto 0) --gets address to send to the DDS
        );
end component;

COMPONENT dds_compiler_0 --takes the address frm the accumulator to give the sine wave out
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_phase_tvalid : IN STD_LOGIC;
    s_axis_phase_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0) 
  );
END COMPONENT;

COMPONENT blk_mem_gen_0 --ROM that holds the corresponding m values for each note to give to the accumulator to add
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0) 
  );
END COMPONENT;

begin -- instantiate all the components
clk_divider_Fs : sample_divider
generic map ( divider_tc => sampling_freq)
  
port map (	clk => clk,
    		reset => clk_reset,
    		clock_en => clk_sampling);  
            
DDS_accumulator : accumulator
port map(
    	clk => clk, 
        reset => accum_reset,
        clock_en => clk_sampling, -- only samples on slow clock
    	m => unsigned(m_lookup), --from lookup - to add to accumulator
        address => DDS_addr 
        );

phase_to_sine_compiler : dds_compiler_0
  PORT MAP (
    aclk => clk,
    s_axis_phase_tvalid => DDS_gen_en,
    s_axis_phase_tdata => DDS_addr,
    m_axis_data_tvalid => m_axis_data_tvalid,
    m_axis_data_tdata => dds_sine_int
  );

BROM_midiNum2m : blk_mem_gen_0
  PORT MAP (
    clka => clk,
    ena =>  midi2m_lookup_en,
    addra => midi_note_number,
    douta => m_lookup
  );

--normalizing by fliping the MSB which is the 12th bit to go to the SPI
dds_sine <= "0000"& not (dds_sine_int(11)) & dds_sine_int(10 downto 0);
end structural;
        
        