-- vorbereitung um tx zu syntetisieren
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_3_type.all;

entity top is
	port (
		i_Clk 		: in std_logic;
		rxd   		: in std_logic;
 		--o_output 	: out std_logic_vector(24 - 1 downto 0 );
		txd			: out std_logic
	);
end top;

architecture rtl of top is
	-- Want to interface to 115200 baud UART
	-- 50000000 / 115200 = 434.028 Clocks Per Bit.
	constant c_CLKS_PER_BIT : integer := 434;
	constant c_WIDTH : integer := 8;
	constant c_DEPTH : integer := 2;

	--constant cnt_size: integer := 5000;
	-- type
	--signals

	-- UART_TX signale
    signal r_Clk       : std_logic;
    signal r_RX_Serial : std_logic;
    signal w_RX_DV     : std_logic; -- data valid pulse: indicates when RX_Byte has valid content
    signal w_RX_Byte   : std_logic_vector(7 downto 0);

	-- Fifo
	signal w_rd_data_burst	: std_logic_vector( 24 - 1 downto 0 ); -- (3 * 8) - 1

	signal r_Reset			: std_logic := '0'; -- wird als flush verwendet
	signal r_WR_EN			: std_logic := '0';
	signal r_WR_DATA		: std_logic_vector (7 downto 0);
	signal w_FULL			: std_logic := '0'; -- wird als logik für wr_en verwendet
	signal r_RD_EN			: std_logic := '0';   -- wird nicht verwendet
	signal w_RD_DATA		: std_logic_vector (7 downto 0); -- wird nicht verwendet
	signal w_EMPTY			: std_logic := '0';	  -- wird nicht verwendet

	--	decoder
	signal r_rst_sync  		: std_logic := '0';
	signal r_rd_data_burst 	: std_logic_vector(24 - 1 downto 0 ); -- array of 3 byte
	signal r_read			: std_logic := '0';
	signal w_flush			: std_logic := '0';
	signal w_data			: std_logic_vector(24 - 1 downto 0 ); -- (3 * 8) - 1

	-- UART TX 
   --signal r_Clk       : std_logic; -- schon deklariert
   signal r_TX_DV     : std_logic;
   signal r_TX_Byte   : std_logic_vector(7 downto 0);
   signal w_TX_Active : std_logic;
   signal w_TX_Serial : std_logic;
   signal w_TX_Done   : std_logic;

begin

	r_Clk <= i_Clk;
	r_RX_Serial <= rxd;
	
	r_rd_en <= '0';
	r_rst_sync <= '0';

	UART_RX_INST : entity work.UART_RX
		generic map(
			g_CLKS_PER_BIT => c_CLKS_PER_BIT
		)
		port map(
			i_Clk         => r_Clk
			, i_RX_Serial => r_RX_Serial
			,o_RX_DV       => w_RX_DV
			,o_RX_Byte     => w_RX_Byte
		);

	r_wr_en <= w_RX_DV and not w_FULL; --nochmal später angucken -- was machen wir bei overflow?
	r_WR_DATA <= w_RX_Byte;
	

	FIFO_INST : entity work.fifo_3
		port map(
			i_rst_sync		    => r_Reset, -- wird als flush verwendet
			i_clk			    => r_Clk,

			i_wr_en			    => r_WR_EN,
			i_wr_data		    => r_WR_DATA,
			o_full			    => w_FULL, -- wird als logik für wr_en verwendet

			i_rd_en			    => r_RD_EN,   -- wird nicht verwendet
			o_rd_data		    => w_RD_DATA, -- wird nicht verwendet
			o_empty		 		=> w_EMPTY,	  -- wird nicht verwendet
			o_rd_data_burst		=> w_rd_data_burst
		);

	r_rd_data_burst <= w_rd_data_burst;
	r_Reset 		<= w_flush;
	r_read 			<= w_FULL;

	decoder_inst : entity work.decoder 
	port map(
        i_rst_sync => r_rst_sync
        ,i_clk      => r_Clk
        -- input Interface
        ,i_rd_data_burst   	=> r_rd_data_burst
        ,i_read				=> r_read
        -- output Interface
        ,o_flush 		=> w_flush
        ,o_data   		=> w_data
	);

	--o_output 	<= w_data; 
	r_TX_DV 	<= w_flush;
	--r_TX_Byte 	<= ""X"00";
	r_TX_Byte 	<= (others => '0');

	UART_TX_inst : entity work.UART_TX 
	generic map (
	  -- 50000000 / 115200 = 434.028 Clocks Per Bit.
		g_CLKS_PER_BIT => c_CLKS_PER_BIT     -- Needs to be set correctly
	)
	port map (
		 i_Clk       => r_Clk
		,i_TX_DV     => r_TX_DV    
		,i_TX_Byte   => r_TX_Byte  
		,o_TX_Active => w_TX_Active
		,o_TX_Serial => w_TX_Serial
		,o_TX_Done   => w_TX_Done  
	);
	--port map ( r_Clk,r_TX_DV,r_TX_Byte,w_TX_Active,w_TX_Serial,w_TX_Done);
	txd <= w_TX_Serial;

	p_automat : process (i_Clk)
	begin
		if rising_edge(i_Clk) then

		end if;
	end process;

end rtl;
