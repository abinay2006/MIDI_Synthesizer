-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;

-- entity declaration
entity dds_sys_tb is
end entity;

--=============================================================================
--Architecture
--=============================================================================
architecture testbench of dds_sys_tb is

--=============================================================================
--Component Declaration
--===========================================================================
component DDS_Data_Gen is
GENERIC (sampling_freq : in integer);
PORT ( 	
	clk : in std_logic; -- 100 MHz clock
    clk_reset : in std_logic;
    accum_reset : in std_logic;
	midi_note_number : in std_logic_vector(6 downto 0);
    DDS_gen_en, midi2m_lookup_en : in std_logic;
    dds_sine : out std_logic_vector(15 downto 0);
    m_axis_data_tvalid : out std_logic);
end component;

--=============================================================================
--Signals
--=============================================================================
		signal clk, clk_reset, accum_reset : std_logic := '0';
        signal midi_note_number : std_logic_vector(6 downto 0) := (others => '0');
        signal DDS_gen_en, midi2m_lookup_en : std_logic := '0';
		signal dds_sine : std_logic_vector(15 downto 0) := (others => '0');
    	signal m_axis_data_tvalid :  std_logic := '0';
        
        constant clk_period : time := 10 ns;
begin

uut: DDS_Data_gen
    generic map (sampling_freq => 10) -- sampling frequency 10 MHz for simulation
	port map(
		clk 		=>  clk,
		clk_reset 		=> clk_reset,
		accum_reset 		=> accum_reset,
		midi_note_number 	=> midi_note_number, 
        DDS_gen_en => DDS_gen_en,
        midi2m_lookup_en => midi2m_lookup_en,
        dds_sine => dds_sine,
		m_axis_data_tvalid 	=> m_axis_data_tvalid);

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
stim_proc: process
begin

	wait for 2*clk_period;
    
    -- new midi note is played. BROM not yet enabled.
    -- picking note 24 for C2 (lowest keyboard note)
   	midi_note_number <= "0011000";
    
    wait for 2*clk_period;
    
     -- reset accumulator for 1 clock cycle
    accum_reset <= '1';
    wait for clk_period;
    accum_reset <= '0';
    
    -- enable the BROM for 2 clock cycle
    midi2m_lookup_en <= '1';
    wait for 2*clk_period;
    midi2m_lookup_en <= '0';

    --enable the DDS sine wave generator
    DDS_gen_en <= '1';
    wait for 500 us;
    
    -- prepare the next note. Sine wave will not change until BROM is enabled.
     -- picking note 41 which is F3
   	midi_note_number <= "0101001";
   	wait for 2*clk_period;
   	
   	-- now enable the BROM for 1 clock cycle to change the sine wave.
    midi2m_lookup_en <= '1';
    wait for 2*clk_period;
    midi2m_lookup_en <= '0';
    wait for 300 us;
    
    
    -- disenable the DDS generator and make sure there's no output
    DDS_gen_en <= '0';
    wait for 10*clk_period;
    
    -- Picking note 48 for C4 (highest keyboard note)
    midi_note_number <= "0110000";
   	wait for clk_period;
    midi2m_lookup_en <= '1';
    wait for 2*clk_period;
    midi2m_lookup_en <= '0';
    
    -- enable the DDS to see note
    DDS_gen_en <= '1';
   
    wait;

end process stim_proc;

end testbench;

