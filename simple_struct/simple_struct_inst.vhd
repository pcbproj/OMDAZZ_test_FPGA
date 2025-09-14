	component simple_struct is
		port (
			clk_clk         : in  std_logic                    := 'X'; -- clk
			code7_code7     : out std_logic_vector(7 downto 0);        -- code7
			dig_sel_dig_sel : out std_logic_vector(3 downto 0);        -- dig_sel
			leds_leds       : out std_logic_vector(3 downto 0);        -- leds
			reset_reset_n   : in  std_logic                    := 'X'; -- reset_n
			scl_in          : in  std_logic                    := 'X'; -- in
			scl_oe          : out std_logic;                           -- oe
			sda_in          : in  std_logic                    := 'X'; -- in
			sda_oe          : out std_logic;                           -- oe
			usart_rxd       : in  std_logic                    := 'X'; -- rxd
			usart_txd       : out std_logic                            -- txd
		);
	end component simple_struct;

	u0 : component simple_struct
		port map (
			clk_clk         => CONNECTED_TO_clk_clk,         --     clk.clk
			code7_code7     => CONNECTED_TO_code7_code7,     --   code7.code7
			dig_sel_dig_sel => CONNECTED_TO_dig_sel_dig_sel, -- dig_sel.dig_sel
			leds_leds       => CONNECTED_TO_leds_leds,       --    leds.leds
			reset_reset_n   => CONNECTED_TO_reset_reset_n,   --   reset.reset_n
			scl_in          => CONNECTED_TO_scl_in,          --     scl.in
			scl_oe          => CONNECTED_TO_scl_oe,          --        .oe
			sda_in          => CONNECTED_TO_sda_in,          --     sda.in
			sda_oe          => CONNECTED_TO_sda_oe,          --        .oe
			usart_rxd       => CONNECTED_TO_usart_rxd,       --   usart.rxd
			usart_txd       => CONNECTED_TO_usart_txd        --        .txd
		);

