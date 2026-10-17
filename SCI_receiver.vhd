--Code your design here

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY SCI_Receiver is
GENERIC(
	constant MAX1 : integer:= 400; --first time count for baud rate to read at the middle of the data
    constant MAX2 : integer:= 800); -- successive count for the baud rate to read the data bits
PORT ( 	clk : in   STD_LOGIC;
		Rx	: 	in 	STD_LOGIC;
        Reset : in STD_LOGIC;
        byte1_out : out STD_LOGIC_VECTOR(7 downto 0); -- Note on or off
        byte2_out : out STD_LOGIC_VECTOR(7 downto 0); -- note number
        byte3_out : out STD_LOGIC_VECTOR(7 downto 0); -- velocity of the note
        noteOn_out: out STD_LOGIC -- to be used as enable for the next component
        ); 
end SCI_Receiver; 


ARCHITECTURE behavioral of SCI_Receiver is
	type state is (idle, waitTc2, rightShift, waitTc, rightShift2, byteDone, done); -- SCI FSM states; 
    
    signal bit_count: unsigned(3 downto 0):= "0000";
    signal byte_count: unsigned(1 downto 0):= "00";
	signal counter1 : unsigned (9 downto 0) := (others => '0'); --400
    signal counter2 : unsigned (9 downto 0):= (others => '0'); --800
    signal data : STD_LOGIC_VECTOR(29 downto 0):= (others => '0');
    
    signal byte1, byte2, byte3: std_logic_vector(7 downto 0) := (others => '0');
    signal noteOn : std_logic := '0';
    
    signal count1_en, count2_en, shift_en, load_en, bit_inc: STD_LOGIC:= '0';
    
    signal tc2, tc, bit_count_tc, byte_count_tc, byte_add: STD_LOGIC:= '0';
    signal current_state, next_state: state:= idle;
    
    begin
    
 stateUpdate:process(clk) begin
 	if(rising_edge(clk)) then
        if(reset = '1') then
            current_state <= idle;
        else
    	current_state <= next_state;
       end if;
    end if;
 end process stateUpdate;
 
NSLogic: process(current_state, Rx, tc2, bit_count_tc, tc, byte_count_tc) begin
 	next_state <= current_state;
    case current_state is
    	when idle =>
        	if(Rx = '0') then
            	next_state <= waitTc2;
            end if;
       when waitTc2 =>
       		if(tc2 = '1') then
            	next_state <= rightShift;
             end if;
             
       when rightShift =>
       		next_state <= waitTc;
       
       when waitTc =>
       		if(tc = '1') then
            	next_state <= rightShift2;
       		end if;
       when rightShift2 =>
       		if(bit_count_tc = '0') then
            	next_state <= waitTc;
            elsif(byte_count_tc = '0') then
            	next_state <= byteDone;
            else
            	next_state <= done;
             end if;
       when byteDone =>
                next_state <= idle;              -- wait for the next start bit
       when done =>
       		next_state <= idle;
       when others =>
       		next_state <= current_state;
            
       end case;
end process NSLogic;
       		
Output: process(current_state) begin
	count1_en <= '0';
    count2_en <= '0';
    load_en <= '0';
    shift_en <= '0';
    bit_inc <= '0';
    byte_add <= '0';
	case current_state is
    	when waitTc2 =>
        	count1_en <= '1'; --for reading the first bit in the sequence of 30 bits
        
        when rightShift =>
        	shift_en <= '1';
            bit_inc <= '1';
        
        when waitTc =>
        	count2_en <= '1'; --for reading the rest of the 30 bits in the middle
            
        when rightShift2 =>
        	shift_en <= '1';
            bit_inc <= '1';
            
        when byteDone =>
             byte_add <= '1'; --indicate all three bytes in the input sequence have been read
                
        when done =>
            byte_add <= '0';
            load_en <= '1';
        
        when others =>
            count1_en <= '0';
            count2_en <= '0';
            load_en  <= '0';
            shift_en <= '0';
            bit_inc <= '0';
            byte_add <= '0';
     end case;
  end process Output;
  
  --Datapath
  process(clk) begin
  	if(rising_edge(clk)) then
    	if(count1_en = '1') then 
        	if(tc2 = '0') then
        	counter1 <= counter1 + 1;
            end if;
        else
        	 counter1 <= (others => '0');
        end if;
        
    	if(count2_en = '1') then
        	if(tc = '0') then
        	counter2 <= counter2 + 1;
            end if;
        else
        	 counter2 <= (others => '0');
        end if;
        
        
        if(shift_en = '1') then
        	data <= Rx & data(29 downto 1);
        end if;
        
        if(bit_inc = '1') then
            if(bit_count_tc = '1') then
                bit_count <= "0000";
             else
        	    bit_count <= bit_count+1;
             end if;        	
        end if;
        
        if (byte_add = '1') then
             byte_count <= byte_count + 1; --keep track of which byte (1,2,3)
        elsif load_en = '1' then
             byte_count <= (others => '0');
        end if;
        
        
        if (load_en = '1') then --getting the individual byte values
            byte1 <= data(8 downto 1);
 			byte2 <= data(18 downto 11);
		    byte3 <= data(28 downto 21);
        	
        	if (data(8 downto 5)) = "1001" then --Getting the signal for whether the note is on or not
                    noteOn <= '1';
            else
                 noteOn <= '0';
            end if;
        end if;
        
        if(reset = '1') then
            counter1   <= (others => '0');
            counter2   <= (others => '0');
            bit_count  <= (others => '0');
            byte_count <= (others => '0');
            data       <= (others => '0');
            byte1      <= (others => '0');
            byte2      <= (others => '0');
            byte3      <= (others => '0');
            noteOn     <= '0';
        end if;
    
   end if;
 end process;       	
           
--tc for the counters
 bit_count_tc <= '1' when bit_count = 9 else '0';
  byte_count_tc <= '1' when byte_count = 2      else '0';
 tc2 <= '1' when counter1 = MAX1-1 else '0';
 tc <= '1' when counter2 = MAX2-1 else '0';
 
 --hardwire the signals to the output
 byte1_out <= byte1;
 byte2_out <= byte2;
 byte3_out <= byte3;
 noteOn_out <= noteOn;
end behavioral;
            	



