-- Hexadimal to decomal code converter for
-- 7 segment indicator
-- simbol shows by zero and hide by '1'
-- also include whole process of indication 
-- wr_valid_n - is short low pulse for input data latching


-- NOT DEBUGED!!! ----------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity segment_7_hex is
    port(
		clk       : in  std_logic;
		en        : in  std_logic;
		dec_in    : in  std_logic_vector(15 downto 0);-- all 4 digits to show
		dp_in     : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		wr_valid  : IN  STD_LOGIC;
		c_sel     : out std_logic_vector(3 downto 0); -- anod selection
		code7_dp  : out std_logic_vector(7 downto 0)
    );
end segment_7_hex;

architecture Behavioral of segment_7_hex is



SIGNAL dec      : std_logic_vector(7 downto 0);
SIGNAL dots     : STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL div_cnt  : INTEGER RANGE 0 TO 25000;  --511;
SIGNAL clk_1kHz : STD_LOGIC;
SIGNAL seg_sel  : INTEGER RANGE 0 TO 3;
SIGNAL seg_num  : INTEGER RANGE 0 TO 3;

CONSTANT DIG_DIV : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"000A";  -- divide for 10
SIGNAL dec1_in  : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL dec2_in  : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL d0,d1,d2,d3 : STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL d_in  : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal dp	: std_logic_vector( 3 downTO 0 );


begin

code7_dp <= dec;

divider_1kHz: PROCESS(clk)
BEGIN
	IF en = '0' THEN
		clk_1kHz <= '0';
		div_cnt  <= 0;
	ELSIF en = '1' AND RISING_EDGE(clk) THEN
		IF div_cnt < 25_000 THEN
			div_cnt <= div_cnt + 1;
		ELSE
			div_cnt <= 0;
			clk_1kHz <= NOT clk_1kHz;
		END IF;
	END IF;
END PROCESS;

seg_num <= 0 WHEN dec_in < x"000F" ELSE 
		1 WHEN dec_in < x"00FF" ELSE 
		2 WHEN dec_in < x"0FFF" ELSE 
		3;



seg_sel_cnt: PROCESS(clk_1kHz)
BEGIN
	IF en = '0' THEN
		seg_sel <= 0;
	ELSIF RISING_EDGE(clk_1kHz) THEN
		IF seg_sel < seg_num THEN
			seg_sel <= seg_sel + 1;
		ELSE
			seg_sel <= 0;
		END IF;
	END IF;
END PROCESS;



process (clk, wr_valid)
	variable hex : STD_LOGIC_VECTOR(3 DOWNTO 0);
begin
	IF en = '0' THEN
		c_sel<= "1111";
	elsif (wr_valid = '1' ) then
		d_in	<= dec_in;
		dp		<= dp_in;
		
    ELSIF RISING_EDGE(clk) then --rising edge 
		CASE seg_sel IS
		WHEN 0 => 
			hex := d_in(3 DOWNTO 0);
			c_sel <= "1110";
			dec(7) <= NOT dp(0);
		WHEN 1 =>
			hex := d_in(7 DOWNTO 4);
			c_sel <= "1101";
			dec(7) <= NOT dp(1);
		WHEN 2 =>
			hex := d_in(11 DOWNTO 8);
			c_sel <= "1011";
			dec(7) <= NOT dp(2);
		WHEN 3 =>
			hex := d_in(15 DOWNTO 12);
			c_sel <= "0111";
			dec(7) <= NOT dp(3);
		WHEN OTHERS => NULL;
		END CASE;
		
		case hex is
			when "0000" => dec(6 downto 0) <= "1000000"; -- 0
			when "0001" => dec(6 downto 0) <= "1111001"; -- 1
			when "0010" => dec(6 downto 0) <= "0100100"; -- 2
			when "0011" => dec(6 downto 0) <= "0110000"; -- 3
			when "0100" => dec(6 downto 0) <= "0011001"; -- 4
			when "0101" => dec(6 downto 0) <= "0010010"; -- 5
			when "0110" => dec(6 downto 0) <= "0000010"; -- 6
			when "0111" => dec(6 downto 0) <= "1111000"; -- 7
			when "1000" => dec(6 downto 0) <= "0000000"; -- 8
			when "1001" => dec(6 downto 0) <= "0010000"; -- 9
			when "1010" => dec(6 downto 0) <= "0001000"; -- A
			when "1011" => dec(6 downto 0) <= "0000011"; -- b
			when "1100" => dec(6 downto 0) <= "1000110"; -- C
			when "1101" => dec(6 downto 0) <= "0100001"; -- d
			when "1110" => dec(6 downto 0) <= "0000110"; -- E
			when "1111" => dec(6 downto 0) <= "0001110"; -- F
		when others => null;
		end case;
    end if;
end process;



end Behavioral;