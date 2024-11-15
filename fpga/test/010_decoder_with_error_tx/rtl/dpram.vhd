library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity dpram is
generic (
	addr_width : natural := 10; -- 2^10 = 1024 
	data_width : natural := 8);
port (
	write_en	: in std_ulogic;
	waddr		: in std_ulogic_vector (addr_width - 1 downto 0); -- die aktuelle adresse des gol64
	wclk		: in std_ulogic; -- clk von gol
	din			: in std_ulogic_vector (data_width - 1 downto 0); -- gol daten
	
	raddr		: in std_ulogic_vector (addr_width - 1 downto 0); -- ram addr
	rclk		: in std_ulogic; -- ram clock
	dout		: out std_ulogic_vector (data_width - 1 downto 0)); -- to ram output
end dpram;

architecture rtl of dpram is
	type mem_type is array ((2** addr_width) - 1 downto 0) of
		std_ulogic_vector(data_width - 1 downto 0);
	signal mem : mem_type;

begin
	process (wclk)
 -- Write memory.
	 begin
		 if (wclk'event and wclk = '1') then
			 if (write_en = '1') then
			 	mem(to_integer(unsigned(waddr))) <= din;
			 end if;
		 end if;
	 end process;

 -- Read memory.
	 process (rclk)
	 begin
		 if (rclk'event and rclk = '1') then
		 	dout <= mem(to_integer(unsigned(raddr)));
		 end if;
	 end process;
 end rtl;
