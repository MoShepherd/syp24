-- QUELLE: nandland.com

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;


entity bootloader_top_tb is
end bootloader_top_tb;

architecture tb of bootloader_top_tb is

  -- Test Bench uses a 50 MHz Clock
  -- 1/50000000 = CLK_PERIOD
  constant c_CLK_PERIOD : time := 20 ns;

  -- Want to interface to 115200 baud UART
  -- 50000000 / 115200 = 217 Clocks Per Bit.
  constant c_CLKS_PER_BIT : integer := 434;

  -- 1/115200:
  constant c_BIT_PERIOD : time := 8680 ns;

  -- procedure BEGIN
  -- Low-level byte-write
  procedure UART_WRITE_BYTE (
    i_Data_In : in std_logic_vector(7 downto 0);
    signal o_Serial : out std_logic) is
  begin

    -- Send Start Bit
    o_Serial <= '0';
    wait for c_BIT_PERIOD;

    -- Send Data Byte
    for ii in 0 to 7 loop
      o_Serial <= i_Data_In(ii);
      wait for c_BIT_PERIOD;
    end loop; -- ii

    -- Send Stop Bit
    o_Serial <= '1';
    wait for c_BIT_PERIOD;
  end UART_WRITE_BYTE;
  -- procedure END

  signal r_Clk 			          : std_logic := '0';
  signal w_TX_Serial 	        : std_logic;
  signal w_output		          : std_logic_vector(23 downto 0);
  signal r_RX_Serial 	        : std_logic;

  signal w_svnr_cpu_en        : std_logic;
  signal w_svnr_ram_address   : std_logic_vector(15 downto 0);
  signal w_svnr_ram_data_in   : std_logic_vector(15 downto 0);
  signal w_svnr_wnr         	: std_logic;
  signal w_svnr_addrstrb      : std_logic;
  signal r_program_counter    : std_logic_vector(15 downto 0);

begin
  -- input signal
  r_Clk <= not r_Clk after c_CLK_PERIOD/2;

  -- Instantiate UART Transceiver
  bootloader_top_inst : entity work.bootloader_top
    port map(
      i_Clk               => r_Clk,
      --o_output 	=> w_output,
      i_rxd               =>  r_RX_Serial,
      o_txd               =>  w_TX_Serial,
      i_program_counter   =>  r_program_counter,
    	o_svnr_cpu_en      	=>  w_svnr_cpu_en,
    	o_svnr_ram_address	=>  w_svnr_ram_address,
    	o_svnr_ram_data_in	=>  w_svnr_ram_data_in,
    	o_svnr_wnr			    =>  w_svnr_wnr,
    	o_svnr_addrstrb		  =>  w_svnr_addrstrb
    );

  gen: process 
  begin
    -- Send a command to the UART
    wait until rising_edge(r_Clk);
    -- send DEBUG CMD
    UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"06", r_RX_Serial);
    -- send ADD BP CMD
    UART_WRITE_BYTE(X"04", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial);
    -- send BP ADDRESS
    UART_WRITE_BYTE(X"05", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"03", r_RX_Serial);
    
    -- add second BP
    -- send ADD BP CMD
    UART_WRITE_BYTE(X"04", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial);
    -- send BP ADDRESS
    UART_WRITE_BYTE(X"05", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"04", r_RX_Serial);

    -- delete first BP
    -- send ADD BP CMD
    UART_WRITE_BYTE(X"04", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"03", r_RX_Serial);
    -- send BP ADDRESS
    UART_WRITE_BYTE(X"05", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"03", r_RX_Serial);

  end process;
end tb;
