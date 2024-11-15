-- vorbereitung um tx zu syntetisieren
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_feedback_fifo_fpga is
	port (
		i_Clk : in std_logic;
		txd   : out std_logic;
		rxd   : in std_logic
	);
end uart_feedback_fifo_fpga;

architecture rtl of uart_feedback_fifo_fpga is
	-- Want to interface to 115200 baud UART
	-- 50000000 / 115200 = 434.028 Clocks Per Bit.
	constant c_CLKS_PER_BIT : integer := 434;
	constant c_WIDTH : integer := 8;
	constant c_DEPTH : integer := 2;

	--constant cnt_size: integer := 5000;
	-- type
	--signals

	signal r_TX_DV : std_logic := '0'; --datavalid
	signal r_TX_Byte : std_logic_vector(7 downto 0) := "00000000"; -- X
	signal w_TX_Active : std_logic;
	--signal w_TX_Serial : std_logic;
	signal w_TX_Done : std_logic;

	signal w_RX_DV : std_logic;
	signal w_RX_Byte : std_logic_vector(7 downto 0);

	signal r_Reset : std_logic;
	signal r_WR_EN : std_logic;
	signal r_WR_DATA : std_logic_vector(c_WIDTH - 1 downto 0);
	signal w_FULL : std_logic;
	signal r_RD_EN : std_logic;
	signal w_RD_DATA : std_logic_vector(c_WIDTH - 1 downto 0);
	signal w_EMPTY : std_logic;
	signal w_buffer : std_logic_vector(c_WIDTH - 1 downto 0);

begin

	r_WR_EN <= w_RX_DV and not w_full;
	r_WR_DATA <= w_RX_Byte;
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

	r_RD_EN <= not w_TX_Active and not w_EMPTY;
	r_TX_DV <= not w_TX_Active and not w_EMPTY;

	r_TX_BYTE <= w_RD_DATA;
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

	r_Reset <= '0';
	FIFO_INST : entity work.fifo_regs_no_flags
		generic map(
			g_WIDTH => c_WIDTH,
			g_DEPTH => c_DEPTh
		)
		port map(
			i_rst_sync => r_Reset,
			i_clk      => i_Clk,
			i_wr_en    => r_WR_EN,
			i_wr_data  => r_WR_DATA,
			o_full     => w_FULL,
			i_rd_en    => r_RD_EN,
			o_rd_data  => w_RD_DATA,
			o_empty    => w_EMPTY
		);

	p_automat : process (i_Clk)
	begin
		if rising_edge(i_Clk) then

		end if;
	end process;

end rtl;