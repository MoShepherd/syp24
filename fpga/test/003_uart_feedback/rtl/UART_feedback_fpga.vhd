-- vorbereitung um tx zu syntetisieren
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_feedback_fpga is
	port (
		i_Clk : in std_logic;
		txd   : out std_logic;
		rxd   : in std_logic
	);
end UART_feedback_fpga;

architecture rtl of UART_feedback_fpga is
	-- Want to interface to 115200 baud UART
	-- 50000000 / 115200 = 434.028 Clocks Per Bit.
	constant c_CLKS_PER_BIT : integer := 434;
	--constant cnt_size: integer := 5000;
	-- type
	type t_zustaende is (z_idle, z_received);
	--signals
	signal automat : t_zustaende := z_idle;

	signal r_TX_DV : std_logic := '0'; --datavalid
	signal r_TX_Byte : std_logic_vector(7 downto 0) := "00000000"; -- X
	signal w_TX_Active : std_logic;
	--signal w_TX_Serial : std_logic;
	signal w_TX_Done : std_logic;

	signal w_RX_DV : std_logic;
	signal w_RX_Byte : std_logic_vector(7 downto 0);
begin
	UART_RX_INST : entity work.UART_RX
		generic map(
			g_CLKS_PER_BIT => c_CLKS_PER_BIT
		)
		port map(
			i_Clk         => i_Clk
			, i_RX_Serial => rxd,
			o_RX_DV       => w_RX_DV,
			o_RX_Byte     => w_RX_Byte
		);

	UART_TX_INST : entity work.UART_TX
		generic map(
			g_CLKS_PER_BIT => c_CLKS_PER_BIT
		)
		port map(
			i_Clk         => i_Clk
			, i_TX_DV     => r_TX_DV
			, i_TX_Byte   => r_TX_Byte
			, o_TX_Active => w_TX_Active
			, o_TX_Serial => txd
			, o_TX_Done   => w_TX_Done
		);

	p_automat : process (i_Clk)
	begin
		if rising_edge(i_Clk) then
			case automat is
				when z_idle =>
					r_TX_DV <= '0';
					if w_RX_DV = '1' then
						r_TX_Byte <= w_RX_Byte;
						automat <= z_received;
					end if;
				when z_received =>
					r_TX_DV <= '1';
					if w_TX_Done = '1' then
						r_TX_DV <= '0';
						automat <= z_idle;
					end if;
				when others =>
					automat <= z_idle;
			end case;
		end if;
	end process;

end rtl;