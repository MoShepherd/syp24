library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sig3_tb is
end entity;

architecture tb of sig3_tb is
	constant half_period : time := 10 ns;
	constant clk_period : time := half_period * 2;
	signal s_clk : std_ulogic := '0';
	signal s_a, s_b, s_c, s_d : std_ulogic;
begin
  -- clock generation
  s_clk <= not s_clk after half_period;

	a : process (s_clk)
	begin 
	if rising_edge(s_clk) then
		s_d <= s_c;		
		s_c <= s_b;		
		s_b <= s_a;		
	end if;
	end process;
	

	wavegen_proc : process
	begin
	s_a <= '0';	
	wait for CLK_PERIOD;
	s_a <= '1';	
	wait for 10* CLK_PERIOD;
	s_a <= '0';	
	wait for 10* CLK_PERIOD;
	wait;
	end process;	
end architecture;
