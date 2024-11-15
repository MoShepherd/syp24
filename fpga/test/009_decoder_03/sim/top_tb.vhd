-- QUELLE: nandland.com

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tb is
end top_tb;

architecture tb of top_tb is

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

  signal r_Clk 			: std_logic := '0';
  signal w_TX_Serial 	: std_logic;
  signal w_output		: std_logic_vector(23 downto 0);
  signal r_RX_Serial 	: std_logic;

begin
  -- input signal
  r_Clk <= not r_Clk after c_CLK_PERIOD/2;

  -- Instantiate UART Transceiver
  top_inst : entity work.top
    port map(
      i_Clk => r_Clk,
      --o_output 	=> w_output,
      rxd   => r_RX_Serial,
      txd   => w_TX_Serial
    );

  gen: process 
  begin
    -- Send a command to the UART
    wait until rising_edge(r_Clk);
--  UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial);
-- 	for i in 0 to 1024 loop
--    		UART_WRITE_BYTE(X"02", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial);
-- 	end loop;

    UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial);
	for i in 0 to 1023 loop
   		UART_WRITE_BYTE(X"02", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial);
	end loop;
    UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"05", r_RX_Serial);

    --UART_WRITE_BYTE(X"02", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial);UART_WRITE_BYTE(X"12", r_RX_Serial);
    --UART_WRITE_BYTE(X"02", r_RX_Serial);UART_WRITE_BYTE(X"13", r_RX_Serial);UART_WRITE_BYTE(X"14", r_RX_Serial);
    --UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"05", r_RX_Serial);
    wait until rising_edge(r_Clk);
    wait;
  end process;
end tb;
