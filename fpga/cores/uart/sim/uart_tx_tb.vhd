-- QUELLE: nandland.com

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity uart_tx_tb is
end uart_tx_tb;

architecture tb of uart_tx_tb is

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
    i_Data_In       : in  std_logic_vector(7 downto 0);
    signal o_Serial : out std_logic) is
  begin

    -- Send Start Bit
    o_Serial <= '0';
    wait for c_BIT_PERIOD;

    -- Send Data Byte
    for ii in 0 to 7 loop
      o_Serial <= i_Data_In(ii);
      wait for c_BIT_PERIOD;
    end loop;  -- ii

    -- Send Stop Bit
    o_Serial <= '1';
    wait for c_BIT_PERIOD;
  end UART_WRITE_BYTE;
-- procedure END



-- signals
  	--signal r_Clock     : std_logic := '0';
  	--signal w_RX_Byte   : std_logic_vector(7 downto 0);
  	--signal r_RX_Serial : std_logic := '1';

    signal r_Clk       : std_logic := '0';
    signal r_TX_DV     : std_logic := '1'; --datavalid
    signal r_TX_Byte   : std_logic_vector(7 downto 0) := "01011000"; -- X
    signal w_TX_Active : std_logic;
    signal w_TX_Serial : std_logic;
    signal w_TX_Done   : std_logic;



begin
	-- input signal
  	r_Clk <= not r_Clk after c_CLK_PERIOD/2;

  -- Instantiate UART Transceiver
  UART_TX_INST : entity work.UART_TX
    generic map (
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
		 i_Clk       => r_Clk
		,i_TX_DV     => r_TX_DV    
		,i_TX_Byte   => r_TX_Byte  
		,o_TX_Active => w_TX_Active
		,o_TX_Serial => w_TX_Serial
		,o_TX_Done   => w_TX_Done  
      );


  process is
  begin
	-- Send a command to the UART
	--wait until rising_edge(r_Clock);
	--UART_WRITE_BYTE(X"3F", r_RX_Serial);
	--wait until rising_edge(r_Clock);
	wait;
	end process;
end tb;
