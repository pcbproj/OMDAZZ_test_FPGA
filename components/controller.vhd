library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

USE work.i2c_pkg.ALL;

entity controller is
	port(
		en			: in  std_logic;
		clk			: in  std_logic;
		leds	 	: out std_logic_vector( 3 downto 0 );
		
		code7		: out std_logic_vector(7 downto 0);
		dig_sel	: out std_logic_vector(3 downto 0);
		
		---------- UART signals ----------------
		uart_tx_data 	: out std_logic_vector(15 downto 0); 	-- data for transmittion
		uart_rx_data 	: in  std_logic_vector(15 downto 0); 	-- external data received
		uart_tx_dv		: out std_logic;						-- tx data valid data latched by rising edge
		uart_rx_ready	: in  std_logic;						-- rx data ready, data set by rising edge
		uart_rx_busy	: in  std_logic;						-- rx busy = 1 while reception in progress
		uart_tx_ready 	: in  std_logic;						-- ready for new operation;	
		
		--------- I2C signals ------------------
		i2c_ena       : out     STD_LOGIC;                    --latch in command
		i2c_addr      : out     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
		i2c_rw        : out     STD_LOGIC;                    --'0' is write, '1' is read
		i2c_data_wr   : out     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
		i2c_busy      : in    	STD_LOGIC;                    --indicates transaction in progress
		i2c_data_rd   : in    	STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
		i2c_ack_error : inout	STD_LOGIC                    --flag if improper acknowledge from slave
		
	);
end controller;

	
architecture behave of controller is

	CONSTANT CLK_FREQ_HZ 		: INTEGER := 50_000_000;
	CONSTANT UART_BAUDRATE		: INTEGER := 9600;
	constant CLK_I2C_HZ			: INTEGER := 100_000;
	
	CONSTANT wait_500ms  		: INTEGER := CLK_FREQ_HZ / 2;  
	CONSTANT wait_5ms			: INTEGER := CLK_FREQ_HZ / 200;
	
	constant I2C_SLAVE_ADDR 	: STD_LOGIC_VECTOR( 6 DOWNTO 0 ) := "1001000";
	constant TEMPER_REG_ADDR	: STD_LOGIC_VECTOR( 7 DOWNTO 0 ) := x"00";
	
	
	
	component pgen IS		-- 1 cicle pulse generator
	GENERIC(
		Edge : STD_LOGIC	-- 0 = falling edge, 1 = rising edge pulse gen
	);
	PORT(
		Enable : IN  STD_LOGIC;
		Clk    : IN  STD_LOGIC;
		Input  : IN  STD_LOGIC;
		Output : OUT STD_LOGIC
	);
	END component pgen;
	
	
	component segment_7_hex is
    port(
		clk       : in  std_logic;
		en        : in  std_logic;
		dec_in    : in  std_logic_vector(15 downto 0);-- all 4 digits to show
		dp_in     : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		wr_valid  : IN  STD_LOGIC;
		c_sel     : out std_logic_vector(3 downto 0); -- anod selection
		code7_dp  : out std_logic_vector(7 downto 0)
    );
	 end component;
	
	

		
		
	SIGNAL wait_cnt				: integer range 0 to wait_500ms;
	SIGNAL tx_start				: std_logic;
	SIGNAL dv_cnt 				: integer range 0 to 2;
	SIGNAL symbol_counter  		: integer range 0 to 3;
	
	signal cnt_100Hz   			: integer range 0 to wait_5ms;
	signal clk_100Hz			: std_logic;
	signal btn_cnt              : integer range 0 to 4;
	
	
	
	
	
	type FSM_State	is 	( IDLE, READ_TEMPER, SEND_TEMPER, UART_RD, SEG7_IND );
	signal PresState : FSM_State;
	
	signal reset_n   :   STD_LOGIC;                    --active low reset

	signal count_1Hz 	: integer range 0 to wait_500ms;
	signal clk_1Hz		: STD_LOGIC;
	signal StartPulse	: STD_LOGIC;
	
	
	signal sda_line		: STD_LOGIC;
	signal scl_line		: STD_LOGIC;
	
	SIGNAL I2C_RxDataLen : INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	SIGNAL I2C_RxArray   : I2C_Rd_Array;
	SIGNAL RxByteCnt     : INTEGER RANGE 0 TO 15;
	
	SIGNAL I2C_ByteCnt : INTEGER RANGE 0 TO I2C_DATA_LEN_MAX;
	SIGNAL I2C_PackLen : INTEGER RANGE 0 TO 63;
	
	SIGNAL RegWrDone 	: STD_LOGIC;
	SIGNAL RegRdDone 	: STD_LOGIC;
	SIGNAL I2C_BusyPrev : STD_LOGIC;
	
	
	SIGNAL I2C_Load      : STD_LOGIC;
	signal I2C_DevAddr  : STD_LOGIC_VECTOR( I2C_ADDR_WIDTH-1 DOWNTO 0 );	
	signal I2C_WrData   : STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );	
	signal I2C_RdData   : STD_LOGIC_VECTOR( I2C_DATA_WIDTH-1 DOWNTO 0 );	
	signal I2C_Err      : STD_LOGIC;	
	
	SIGNAL Temper  		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	
	SIGNAL temper_ind7	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL wr_ind_pulse	: STD_LOGIC;
	
	

begin

	 
	
	start_gen: pgen 		-- 1 cicle pulse generator
	GENERIC MAP(
		Edge => '1' 	--  1 = rising edge pulse gen
	)
	PORT MAP(
		Enable 	=>	reset_n	,
		Clk    	=>	clk		,
		Input  	=>	clk_1Hz		,
		Output 	=>	StartPulse		-- generate start pulse 1 cicle clk width every second 
	);
	
	seg_7_indicstor:	segment_7_hex 
    port map(
		clk       	=> clk,
		en        	=> '1',
		dec_in    	=> temper_ind7,	-- all 4 digits to show
		dp_in     	=> "0000",
		wr_valid 	=> wr_ind_pulse,
		c_sel     	=> dig_sel,	-- anod selection
		code7_dp  	=> code7
    );
	
	
	
		
	reset_n	<= en;
	
	
	i2c_ena     	<=	 I2C_Load    ;
	i2c_addr    	<=	 I2C_DevAddr ;
--	i2c_rw_int      <=	 I2C_RW      ;
	i2c_data_wr 	<=	 I2C_WrData  ;
--	I2C_Busy_int   	<=	i2c_busy      ;
	I2C_RdData 		<=	i2c_data_rd   ;
	I2C_Err    		<=	i2c_ack_error ;
	
	
	
	leds(0) 	<= clk_1Hz;
	
	
	gen_1Hz: process( reset_n, clk )
	begin
		if reset_n = '0' then
			count_1Hz 	<= 0;
			clk_1Hz		<= '0';
		elsif rising_edge( clk ) then
			if count_1Hz < wait_500ms/8 then
				count_1Hz <= count_1Hz + 1;
			else	
				count_1Hz <= 0;
				clk_1Hz <= NOT clk_1Hz;
			end if;
		
		end if;
	end process;
	

	FSM: process( reset_n, clk )
		variable show_cnt : integer range 0 to 4;
		
	begin
		if reset_n = '0' then
			PresState <= IDLE;
			show_cnt 	:= 0;
			Temper		 <= ( others => '0' );
			temper_ind7 <= (OTHERS => '0');
			wr_ind_pulse <= '0';
			
			uart_tx_dv 		<= '0';
		elsif rising_edge( clk ) then
		
			I2C_BusyPrev <= I2C_Busy;
			
			case ( PresState ) is
			
			when IDLE =>
				I2C_Load 	<= '0';
				I2C_ByteCnt <= 0;
				RegWrDone  	<= '0';
				RegRdDone  	<= '0';
				I2C_BusyPrev <= '0';
				wr_ind_pulse <= '0';
--				temper_ind7 <= (OTHERS => '0');
				
				show_cnt 	:= 0;
				
				I2C_RxDataLen <= 2;
				
				uart_tx_dv 		<= '0';
			
				IF uart_rx_ready = '1' THEN
					PresState <= UART_RD;
				ELSE
										
					IF I2C_Busy = '0' THEN
						IF StartPulse = '1' THEN
							PresState <= READ_TEMPER; 
						END IF;
					ELSE
						PresState <= IDLE;
					END IF;
				END IF;
				
				
				
			
			when READ_TEMPER =>
				if RegRdDone = '0' then    
					i2c_array_rd( 
				          I2C_SLAVE_ADDR,    -- I2C Bus device Address
	                      TEMPER_REG_ADDR, -- I2C device internal register address
	                      I2C_RxArray,		   -- I2C device temper readed 2 bytes
	                      I2C_ByteCnt,          -- Byte Counter
						  I2C_RxDataLen,		-- Rx Array len = 2 bytes
	                      I2C_DevAddr,         
	                      I2C_RW,              
	                      I2C_Load,             
	                      I2C_Busy,            
	                      I2C_BusyPrev,        
	                      RegRdDone,           -- Data Read Ready Flag
	                      I2C_WrData,
	                      I2C_RdData           
	                );
					PresState <= READ_TEMPER;
				
				elsif I2C_Err = '0' then
					Temper 		<= I2C_RxArray(0);	-- use MSB of readed temper value. It's in integer temper value
					RegRdDone 	<= '0';
					PresState 	<= SEND_TEMPER;
				else
					PresState <= IDLE;
					
				end if;
			
			when SEND_TEMPER =>
				if show_cnt < 2 then
					show_cnt := show_cnt + 1;
					
					uart_tx_dv 		<= '1';
					uart_tx_data( 7 downto 0 ) 	<= Temper;
					PresState 		<= SEND_TEMPER;
				else
					uart_tx_dv 		<= '0';
					show_cnt := 0;
					PresState <= IDLE;
				end if;
			
			when UART_RD =>
				temper_ind7 <= uart_rx_data;
				wr_ind_pulse <= '1';
				PresState <= IDLE;
			
			
			when OTHERS => 
				PresState <= IDLE;
				
			end case;
			
		
		end if;
	
	
	end process;
	
	
	
	
	
	
end behave;