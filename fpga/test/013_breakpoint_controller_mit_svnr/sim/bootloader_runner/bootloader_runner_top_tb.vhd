-- QUELLE: nandland.com

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bootloader_runner_top_tb is
end bootloader_runner_top_tb;

architecture tb of bootloader_runner_top_tb is

  -- Test Bench uses a 50 MHz Clock
  -- 1/50000000 = CLK_PERIOD
  constant c_CLK_PERIOD : time := 20 ns;
  -- at 12MHz Clock:
  -- 1/12000000
  -- constant c_CLK_PERIOD : time := 83 ns;

  -- Want to interface to 115200 baud UART
  -- 50000000 / 115200 = 217 Clocks Per Bit.
  constant c_CLKS_PER_BIT : integer := 434;

  -- 12000000 / 115200
  -- constant c_CLKS_PER_BIT : integer := 104;

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
  signal r_Counter1 : integer := 0;
  signal r_Counter2 : integer := 0;

begin
  -- input signal
  r_Clk <= not r_Clk after c_CLK_PERIOD/2;

  -- Instantiate UART Transceiver
  top_inst : entity work.top
    port map(
      clk => r_Clk,
      --o_output 	=> w_output,
      rxd   => r_RX_Serial,
      txd   => w_TX_Serial
    );

  gen: process 
    begin
      -- Send a command to the UART
      wait until rising_edge(r_Clk);
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial);

      for i in 0 to 1023 loop
        -- r_Counter1 <= r_Counter1 + 1;  -- Increment the first counter
  
        -- -- Check for overflow
        -- if r_Counter1 = 256 then
        --   r_Counter1 <= 0;             -- Reset first counter on overflow
        --   r_Counter2 <= r_Counter2 + 1;  -- Increment the second counter
        -- end if;
  
        -- -- Send data with incremented values
        -- UART_WRITE_BYTE(X"02", r_RX_Serial);
        -- UART_WRITE_BYTE(std_logic_vector(to_unsigned(r_Counter2, 8)), r_RX_Serial);
        -- UART_WRITE_BYTE(std_logic_vector(to_unsigned(r_Counter1, 8)), r_RX_Serial);
        UART_WRITE_BYTE(X"02", r_RX_Serial);UART_WRITE_BYTE(X"48", r_RX_Serial);UART_WRITE_BYTE(X"10", r_RX_Serial);
        -- UART_WRITE_BYTE(X"02", r_RX_Serial);UART_WRITE_BYTE(X"10", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);
      end loop;

      -- get status to ensure right status
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"05", r_RX_Serial); 
      
      -- enter debug
      -- UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"06", r_RX_Serial); 
      
      -- add breakpoint at address 0x0000
      -- UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial); 
      -- UART_WRITE_BYTE(X"05", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"10", r_RX_Serial);

      -- start svnr
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"01", r_RX_Serial);

      -- wait for 100 us;
      -- resume svnr, it shouldve stopped at breakpoint 0x0010 by then
      -- UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"01", r_RX_Serial);

      wait until rising_edge(r_Clk);
      wait;
  end process;
end tb;
