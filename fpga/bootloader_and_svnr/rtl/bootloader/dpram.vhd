--! \file dpram.vhd
--! \brief H�lt das vollst�ndig �bertragene RAM Bin�rimage   
--! 
--! Dient als Buffer f�r das vollst�ndig �bertragene Bin�rimage, damit ein fehlerhaft �bertragenes Image nicht direkt in den SVNR RAM �bertragen werden kann.
--!

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

--! \brief H�lt das vollst�ndig �bertragene RAM Bin�rimage   
--! 
--! Dient als Buffer f�r das vollst�ndig �bertragene Bin�rimage, damit ein fehlerhaft �bertragenes Image nicht direkt in den SVNR RAM �bertragen werden kann.
--!
entity dpram is
generic (
	addr_width : natural := 10; -- 2^10 = 1024 
	data_width : natural := 8);
port (
	--write interface
	write_en	: in std_logic;										--! Schreibe Daten
	waddr		: in std_logic_vector (addr_width - 1 downto 0); 	--! Write Adresse
	wclk		: in std_logic; 									--! Write Clock
	din			: in std_logic_vector (data_width - 1 downto 0); 	--! gol daten
	
	-- read interface
	raddr		: in std_logic_vector (addr_width - 1 downto 0); 	--! Read Adresse
	rclk		: in std_logic; -- ram clock						--! Read Clock
	dout		: out std_logic_vector (data_width - 1 downto 0)); 	--! Read Daten
end dpram;

architecture rtl of dpram is
	type mem_type is array ((2** addr_width) - 1 downto 0) of
		std_logic_vector(data_width - 1 downto 0);
	signal mem : mem_type := (others => (others => '0'));

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
