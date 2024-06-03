
library IEEE;
use IEEE.std_logic_1164.all;

entity usart is
	generic(
		CLK_FREQ_HZ	: INTEGER := 50_000_000;
		BAUD_RATE   : INTEGER := 9600;	
		DATA_BITS	: INTEGER := 8;
		PARITY		: INTEGER := 0; -- yes(even)=2 yes(odd)=1 no=0
		STOP_BITS	: INTEGER := 1	--yes(two bits)=2 yes(one bit)=1 no=0
	);
    port(	
		en			: in  std_logic;
		clk 		: in  std_logic;
		rx 			: in  std_logic;
		tx 			: out std_logic;
		tx_data 	: in  std_logic_vector(15 downto 0); -- data for transmittion
		rx_data 	: out std_logic_vector(15 downto 0); -- external data received
		tx_dv		: in  std_logic;		-- tx data valid/ data latched by rising edge
		rx_dv		: out std_logic;
		rx_busy		: out std_logic;
		tx_ready 	: out std_logic	-- ready for new operation;	
    );
end usart;
architecture Behavioral of usart is

constant baud : integer := CLK_FREQ_HZ / BAUD_RATE / 2;

type FSM_RX_State is ( IDLE, START, RD_BITS, PARITY_CHECK, STOP );


signal bit_clk 		: std_logic := '0';		-- internal clock 
signal baud_counter : integer range 0 to baud;
signal bits 		: integer range 0 to ( DATA_BITS + STOP_BITS + PARITY + 1 ) := 0; 
signal send_data		: std_logic_vector(15 downto 0);
signal receive_data  : std_logic_vector(15 downto 0);
signal tx_dv_latch	: std_logic := '0';
signal tx_en		: std_logic := '0';
signal tx_out		: std_logic := '1';

--signal rx_bit_clk	: std_logic := '0';	-- recceive bit clock
signal rx_bits      : integer range 0 to ( DATA_BITS + STOP_BITS + PARITY + 1 ) := 0;
signal rx_counter : integer range 0 to (baud * 2); 

signal pr_state, next_state : FSM_RX_State;

begin

	assert(PARITY = 0)
		report "*** ERROR: PARITY must be zero! PARITY = 0!"
		severity FAILURE;
	
	tx <= tx_out;

    process(clk, en)
	begin
		if en = '0' then
			baud_counter <= 0;
			bit_clk <= '0';
		elsif ( clk = '1' and clk'Event ) then
			if baud_counter < (baud - 1) then 
				baud_counter <= baud_counter + 1;
			else
				bit_clk <= not bit_clk;
				baud_counter <= 0; 
			end if;
		end if;
    end process;
    
	
    tx_starter: process (clk, en)
	begin
		if en = '0' then
			tx_dv_latch <= '0';
		elsif rising_edge(clk) then
			if (tx_dv = '1') then
				send_data(15 downto 1) <= tx_data(14 downto 0);	-- shift left to add start bit 0
				send_data(0) <= '0';
				if STOP_BITS = 1 then
					send_data( DATA_BITS + PARITY + STOP_BITS ) <= '1';  -- stop bit
				elsif STOP_BITS = 2 then
					send_data( DATA_BITS + PARITY + STOP_BITS ) <= '1';  -- stop bit
					send_data( DATA_BITS + PARITY + STOP_BITS - 1 ) <= '1';  -- stop bit
				end if;
				if tx_en = '0' then
					tx_dv_latch <= '1';
				end if;
			elsif tx_en = '1' then
				tx_dv_latch <= '0';
			end if;
		end if;
	end process;   
	
	
	transmitter: process(bit_clk, en) 
	begin
		if en = '0' then
			tx_en <= '0';
			bits <= 0;
			tx_out <= '1';
			tx_ready <= '1';
		elsif rising_edge(bit_clk) then
			if ( tx_dv_latch = '1' or tx_en = '1') then	--set data into usart transmittion
				tx_ready <= '0';
				tx_en <= '1';
				if bits < ( ( DATA_BITS + PARITY + STOP_BITS + 1 ) ) then
					tx_out <= send_data(bits);
					bits <= bits + 1;
				else
					bits <= 0;
					tx_ready <= '1';
					tx_out <= '1';
					tx_en <= '0';
				end if;
			end if;
		end if;
    end process;
	
	
	receiver_FSM: process(en, clk)
	begin
		if en = '0' then
			pr_state <= IDLE;
			next_state <= IDLE;
			rx_bits <= 0;
			rx_dv <= '0';
			rx_counter <= 0;
			rx_busy <= '0';
			receive_data <= (others => '0');
		elsif rising_edge(clk) then
			
			pr_state <= next_state;
			
			case pr_state is
			
			when IDLE =>
				rx_bits <= 0;
				rx_dv <= '0';
				rx_counter <= 0;
				rx_busy <= '0';
				if (rx = '0') then  -- start condition detected
					next_state <= START;
				end if;
			
			when START => 			-- count for start condition time and set latch moments for bits
				rx_busy <= '1';
				if rx_counter < baud then
					rx_counter <= rx_counter + 1;
				else
					rx_counter <= 0;
					next_state <= RD_BITS;
				end if;
			
			when RD_BITS =>
				if ( rx_counter < (baud*2) ) then
					rx_counter <= rx_counter + 1;
				else
					rx_counter <= 0;
					if ( rx_bits < ( DATA_BITS ) ) then
						rx_bits <= rx_bits + 1;
						receive_data(rx_bits) <= rx;
					else
						rx_bits <= 0;
						rx_counter <= 0;
						if PARITY = 0 then
							next_state <= STOP;
						else
							next_state <= PARITY_CHECK;
						end if;
					
					end if;
				
				end if;
			
			when PARITY_CHECK =>
				next_state <= IDLE;
			
			when STOP =>
				if(rx_counter < baud) then
					rx_counter <= rx_counter + 1;
				else
					rx_busy <= '0';
					rx_counter <= 0;
					if rx = '1' then
						rx_dv <= '1';
						rx_data <= receive_data;
					else	
						rx_dv <= '0';
					end if;
					next_state <= IDLE;
				end if;
			
			when others =>
				next_state <= IDLE;
			
			end case;
			
		end if;
	
	end process;
	
        
end Behavioral;