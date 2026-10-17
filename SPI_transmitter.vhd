-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY SPI_Transmitter IS
PORT ( 	clk		: 	in 	STD_LOGIC; 
        SPI_en 	: 	in 	STD_LOGIC;
        Data_in : 	in	STD_LOGIC_VECTOR(15 downto 0); --thte sine wave
		MOSI	: 	out STD_LOGIC;
		CS		:	out	STD_LOGIC);
end SPI_Transmitter;


ARCHITECTURE behavior of SPI_Transmitter is
signal Shift_reg : std_logic_vector(15 downto 0) := (others => '0');
signal count : unsigned(3 downto 0) := (others => '0');
type state is (idle, load, shift);
signal currState, nextState : state := idle;
signal data_tc, shift_en, load_en, reset : std_logic := '0';


BEGIN

-- FSM
stateUpdate : process(clk) begin
	if rising_edge(clk) then
    	currState <= nextState;
    end if;
end process stateUpdate;

stateLogic : process(currState, SPI_en, data_tc) begin
	nextState <= currState; -- default
    
    case (currState) is
    	when idle =>
        	if SPI_en = '1' then nextState <= load; end if;
    	when load => nextState <= shift;
        when shift =>
        	if data_tc = '1' then nextState <= idle; end if;
        when others => nextState <= idle;
    end case;
    
end process stateLogic;

outputLogic : process(currState) begin
    load_en <= '0';
    shift_en <= '0';
    CS <= '1';
    reset <= '0';
    
    case (currState) is
    	when load => 
    	   load_en <= '1';
            CS <= '0';
            reset <= '1';
        when shift => 
        	shift_en <= '1';
            CS <= '0';
        when others => null;
    end case;
    
end process outputLogic;

-- datapath
datapath: process(clk)
begin
	if rising_edge(clk) then
        
		if load_en = '1' then
            shift_reg <= Data_in; -- 2 bytes total 
        elsif shift_en = '1' then
        	shift_reg <= shift_reg(14 downto 0) & '0'; -- MSB first, so shift left
        end if;

	end if;
    
end process datapath;

-- counters
dataCounter: process(clk) begin
    if rising_edge(clk) then
    	if data_tc = '1' or reset = '1' then
        	count <= (others => '0');
        else 
    		count <= count + 1;
         end if;
    end if;
    
end process dataCounter;

-- asynchronous:
--hardwire MOSI to the MSB
MOSI <= shift_reg(15);

-- TC for counters
data_tc <= '1' when count = 15 else '0';

end behavior;
        
        