--! \file bootloader_runner_top.vhd
--! \brief Testbench für das Testen der Bootloader Funktionalität
--! 
--! Die Timings der emulierten UART Signale entsprechen der realen 50MHz Clock des iceduino Boards.
--! Mit dieser Testbench kann die Funktinalität des Bootloaders getestet werden. Es können mit `UART_WRITE_BYTE` Befehle an den Bootloader gesendet werden, wie sie auch von der Host App kommen.
--! Die gesamte Übertragung des Binärimages über UART dauert ~230ms, weshalb die Simulation extrem lange dauern kann.

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

  -- Low-level byte-write
  --! \brief emulates the transmission of a a serial TX Byte, so that the UART_RX.vhd component can receive and process the data further. 
  --! 
  --! 3 Times UART_WRITE_BYTE() represents one Bootloader Packet
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
  r_Clk <= not r_Clk after c_CLK_PERIOD/2;

  top_inst : entity work.top
    port map(
      clk => r_Clk,
      rxd   => r_RX_Serial,
      txd   => w_TX_Serial
    );

  gen: process 
    begin
      wait until rising_edge(r_Clk);

      -- Command: Starte Übertragung eines Binärimages
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial);

      -- Erstes Binärpaket: 0x4810 (0x48 Opcode = JA/Jump Absolute) 
      UART_WRITE_BYTE(X"02", r_RX_Serial);UART_WRITE_BYTE(X"48", r_RX_Serial);UART_WRITE_BYTE(X"10", r_RX_Serial);

      for i in 0 to 1022 loop
        -- Für die restlichen Adressen mit: 0x1000 (0x10 Opcode = NoOp/No Operation)
        UART_WRITE_BYTE(X"02", r_RX_Serial);UART_WRITE_BYTE(X"10", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);
      end loop;

      -- Statusabfrage um vollständige Übetragung zu bestätigen
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"05", r_RX_Serial); 
      
      -- Command: Debug Modus
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"06", r_RX_Serial); 
      
      -- Füge Breakpoint an Adresse 0x0011 hinzu
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial); 
      UART_WRITE_BYTE(X"05", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"11", r_RX_Serial);

      -- Füge Breakpoint an Adresse 0x0012 hinzu
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"02", r_RX_Serial); 
      UART_WRITE_BYTE(X"05", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"12", r_RX_Serial);
    
      wait for 1 us;

      -- Lösche Breakpoint an Adresse 0x0011
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"03", r_RX_Serial); 
      UART_WRITE_BYTE(X"05", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"11", r_RX_Serial);

      -- Command: Starte SVNR
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"01", r_RX_Serial);

      wait for 100 us;
      -- Command: Starte SVNR, Sollte mittlerweile durch den Breakpoint an Adresse 0x0010 gestoppt haben.
      UART_WRITE_BYTE(X"01", r_RX_Serial);UART_WRITE_BYTE(X"00", r_RX_Serial);UART_WRITE_BYTE(X"01", r_RX_Serial);

      wait until rising_edge(r_Clk);
      wait;
  end process;
end tb;
