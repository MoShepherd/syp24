-- vorbereitung um tx zu syntetisieren
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_TX_fpga is
port (
	 i_Clk       : in  std_logic
	;txd : out std_logic
);
end UART_TX_fpga;

architecture rtl of UART_TX_fpga is
  -- Want to interface to 115200 baud UART
  -- 50000000 / 115200 = 434.028 Clocks Per Bit.
	constant c_CLKS_PER_BIT : integer := 434;
	constant cnt_size: integer := 50000000;
	--constant cnt_size: integer := 5000;
	-- type
  	type t_zustaende is (z_init, z_count, z_send, z_wait);
	--signals
  	signal automat : t_zustaende := z_init;

    signal r_TX_DV     : std_logic := '0'; --datavalid
    signal r_TX_Byte   : std_logic_vector(7 downto 0) := "01011000"; -- X
    signal w_TX_Active : std_logic;
    --signal w_TX_Serial : std_logic;
    signal w_TX_Done   : std_logic;
	signal cnt		   : natural range 0 to cnt_size - 1 := 0;
	
begin
  UART_TX_INST : entity work.UART_TX
    generic map (
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
		 i_Clk       => i_Clk
		,i_TX_DV     => r_TX_DV    
		,i_TX_Byte   => r_TX_Byte  
		,o_TX_Active => w_TX_Active
		,o_TX_Serial => txd
		,o_TX_Done   => w_TX_Done  
      );

	  p_automat : process (i_Clk)
	  begin
		if rising_edge(i_Clk) then
		  case automat is
			when z_init =>
				cnt 	<= 0;	
				r_Tx_DV <= '0';
				automat <= z_count;
			when z_count =>
				if cnt < cnt_size - 1 then
					r_Tx_DV <= '0';
					cnt <= cnt + 1;	
				else 	
					automat <= z_send;
				end if;
			when z_send =>
				r_Tx_DV <= '1';
				cnt 	<= 0;
				automat <= z_wait;
			when z_wait =>
				r_Tx_DV <= '0';
				if w_TX_Done = '1' then
					automat <= z_count;
				end if;
			when others =>
			  automat <= z_init;
		  end case;
		end if;
	  end process;

end rtl;
