library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity divider16x16b is
    port (
		clk         : in std_logic;
		dividend    : in std_logic_vector(15 downto 0);
		divider     : in std_logic_vector(15 downto 0);
		quotient    : out std_logic_vector(15 downto 0); -- quotient of division
		remainder   : out std_logic_vector(15 downto 0); -- remainder of division
		wr_valid      : in std_logic
    );
end divider16x16b;


architecture Behavioral of divider16x16b is
begin
    process(clk,wr_valid)
    variable up,down,temp,res_temp,result,remain : std_logic_vector(15 downto 0);
    variable b : integer range 0 to 17;
    begin 
	if wr_valid = '1' then 
	    up := dividend;
	    down := divider;
	elsif clk'Event and clk = '1' then
	    result := x"0000";
	    temp := x"0000";
	    b := 0;
	    res_temp := x"0000";
		for i in 0 to 15 loop
			temp := temp+temp;
			temp := temp+up(15-b);
			b := b+1;    
			if temp < down then
			res_temp := res_temp + res_temp;
			else
			res_temp := res_temp+res_temp;
			res_temp := res_temp+1;
			temp := temp-down;
			end if;
		end loop;
		result := res_temp;
		remain := temp;
	end if;
	quotient <= result;
	remainder <= remain;
    end process;
end Behavioral;