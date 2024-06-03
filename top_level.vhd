library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity top_level is
	port(
		
		clk       	: in	std_logic;
		en        	: in	std_logic;
		leds_out		: out	std_logic_vector( 3 downto 0 );
		keys_in		: in	std_logic_vector( 3 downto 0);
		buzer			: out std_logic;
		TXD			: out	std_logic;
		RXD			: in	std_logic;
		SDA			: inout std_logic;
		SCL			: inout	std_Logic;
		seg7_code	: out	std_logic_vector(7 downto 0);
		dig_sel		: out	std_logic_vector(3 downto 0)
	);
	
end top_level;


architecture arch of top_level is

	signal top_sda_in, top_sda_oe	: std_logic;
	signal top_scl_in, top_scl_oe 	: std_logic;
	
	
	 component simple_struct is
        port (
            clk_clk       : in  std_logic                    := 'X';             -- clk
            leds_leds     : out std_logic_vector(3 downto 0);                    -- leds
				code7_code7     : out std_logic_vector(7 downto 0);        --   code7.code7
				dig_sel_dig_sel : out std_logic_vector(3 downto 0);        -- dig_sel.dig_sel
            reset_reset_n : in  std_logic                    := 'X';             -- reset_n
            scl_in        : in  std_logic                    := 'X';             -- in
            scl_oe        : out std_logic;                                       -- oe
            sda_in        : in  std_logic                    := 'X';             -- in
            sda_oe        : out std_logic;                                       -- oe
            usart_rxd     : in  std_logic                    := 'X';             -- rxd
            usart_txd     : out std_logic                                        -- txd
        );
    end component simple_struct;
	 
	 signal sig_500Hz : std_logic;
	 signal cnt_500Hz : INTEGER range 0 to 100_000;
	 	 

begin
	
	 u0 : component simple_struct
        port map (
            clk_clk       => clk, 				--   clk.clk
            leds_leds     =>  open, --leds_out, 		--      .leds
            reset_reset_n =>  en, 				-- reset.reset_n
				code7_code7     =>  seg7_code,     --   code7.code7
				dig_sel_dig_sel =>  dig_sel, 
            scl_in        =>  top_scl_in,		--   scl.in
            scl_oe        =>  top_scl_oe,		--      .oe
            sda_in        =>  top_sda_in,		--   sda.in
            sda_oe        =>  top_sda_oe,		--      .oe
            usart_rxd     =>  RXD,				-- usart.rxd
            usart_txd     =>  TXD				--      .txd
        );
	
	
	SDA <= '0' when top_sda_oe = '1' else 'Z';
	top_sda_in <= SDA;
	
	SCL <= '0' when top_scl_oe = '1' else 'Z';
	top_scl_in <= SCL;
	
	leds_out <= keys_in;
	
	buzer <= not (((not keys_in(0)) OR (not keys_in(1)) OR (not keys_in(2)) OR (not keys_in(3))) AND sig_500Hz);
	
	gen_500Hz: process(clk)
	begin
		if rising_edge(clk) then
			if cnt_500Hz < ( 50_000_000 / 500 / 2) then
				cnt_500Hz <= cnt_500Hz + 1;
			else
				cnt_500Hz <= 0;
				sig_500Hz <= not sig_500Hz;
			end if;
		end if;
	
	
	end process;

	
end arch;