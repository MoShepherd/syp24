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
	constant c_ADDR_WIDTH : NATURAL := 10;
	constant c_DATA_WIDTH : NATURAL := 16;

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
	signal w_status			: std_logic_vector(23 downto 0);
	signal w_ram_addr		: std_logic_vector(9  downto 0);
    signal w_ram_data		: std_logic_vector(15 downto 0);
	signal w_ram_wen 		: std_logic := '0';
	signal w_ram_data_valid : std_logic := '0';

	-- tx buffer
	signal r_wen      		: std_logic;      -- Write enable
	signal r_data_in  		: std_logic_vector(23 downto 0); -- Input data
	signal w_data_out 		: std_logic_vector(23 downto 0);  -- Output data
	signal w_rdy_to_fetch	: std_logic;


	-- UART TX 
   --signal r_Clk       : std_logic; -- schon deklariert
   	signal r_TX_DV     : std_logic;
   	signal r_TX_Byte   : std_logic_vector(7 downto 0);
   	signal w_TX_Active : std_logic;
   	signal w_TX_Serial : std_logic;
   	signal w_TX_Done   : std_logic;

	-- DPRAM
	signal r_write_en  	: std_logic;
    signal r_waddr		: std_logic_vector(c_ADDR_WIDTH - 1 downto 0);
    signal r_wclk 		: std_logic;
    signal r_din 		: std_logic_vector(c_DATA_WIDTH - 1 downto 0);
    signal r_raddr 		: std_logic_vector(c_ADDR_WIDTH - 1 downto 0);
    signal r_rclk 		: std_logic;
    signal w_dout 		: std_logic_vector(c_DATA_WIDTH - 1 downto 0);
	--DPRAM END
   
	-- signal runner
	signal r_runner_begin		: std_logic := '0';
	signal r_runner_reset		: std_logic := '0';
	signal r_runner_addr_in 	: std_logic_vector(10 downto 0);
	signal r_runner_running		: std_logic := '0';
	--signal r_runner_cnt 		: natural range 0 to 1023 := 0;
	signal r_runner_cnt 		: unsigned(9 downto 0) := (others => '0');
	signal w_runner_addr_out 	: std_logic_vector(10 downto 0);
	signal w_runner_done		: std_logic := '0';
	signal w_runner_data		: std_logic_vector(15 downto 0);

    type STATE is (
		 z_tx_wait
		,z_tx_start
		,z_tx_byte
		,z_count
	);
	signal fsm_state 		: STATE := z_tx_start;

	signal tx_packet_byte_cnt: natural range 0 to 2 :=0;

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
	r_data_in 		<= w_status;

	decoder_inst : entity work.decoder 
	port map(
        i_rst_sync => r_rst_sync
        ,i_clk      => r_Clk
        -- input Interface
        ,i_rd_data_burst   	=> r_rd_data_burst
        ,i_read				=> r_read
        -- output Interface
        ,o_flush			=> w_flush
        ,o_data				=> w_data
		,o_status			=> w_status
		,o_ram_addr			=> w_ram_addr
		,o_ram_data			=> w_ram_data
		,o_ram_wen			=> w_ram_wen
		,o_ram_data_valid 	=> w_ram_data_valid
	);

	tx_buffer_inst : entity work.tx_buffer
	port map (
		clk				=> r_Clk, 
		wen				=> r_wen, 
		data_in			=> r_data_in,
		data_out		=> w_data_out,
		o_rdy_to_fetch 	=> w_rdy_to_fetch
	);

	r_wen <= w_flush;
	--o_output 	<= w_data; 
	-- TODO: TX Packet Buffer!
	-- that holds the status signal until it is sent once (achieved with TX_Done => WR_EN signal) 
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

	r_TX_Byte <= w_data_out(23 downto 16) WHEN tx_packet_byte_cnt = 0 ELSE
	w_data_out(15 downto 8) WHEN tx_packet_byte_cnt = 1 ELSE
	w_data_out(7 downto 0);

	p_automat : process (i_Clk)
	begin
		if rising_edge(i_Clk) then
			CASE fsm_state IS
				WHEN z_tx_wait => 
					r_TX_DV 	<= '0';
					IF w_TX_Done = '1' THEN
						-- IF tx_packet_byte_cnt >= 2 THEN
						-- 	tx_packet_byte_cnt <= 0;
						-- END IF;
						fsm_state <=  z_tx_start;
					END IF;
				WHEN z_tx_start => 
					IF w_flush = '1' OR tx_packet_byte_cnt >=1 THEN
						fsm_state <=  z_tx_byte;
					END IF;	
					
				WHEN z_tx_byte => 
					r_Tx_DV <= '1';
					fsm_state <= z_count;
				WHEN z_count => 
					IF tx_packet_byte_cnt >= 2 THEN 
						tx_packet_byte_cnt <=  0;
					ELSE
						tx_packet_byte_cnt <= tx_packet_byte_cnt + 1;
					END IF;
					fsm_state <= z_tx_wait;
			END CASE;
		end if;
	end process;



	-- DECODER -> DPRAM signal
	r_write_en 	<= w_ram_wen;
	r_waddr		<= w_ram_addr;
	r_wclk		<= r_clk;
	r_din		<= w_ram_data;

	-- DPRAM
	dpram_inst : entity work.dpram
	generic map (
		 addr_width => c_ADDR_WIDTH --1024 speicher adressen 
		,data_width => c_DATA_WIDTH -- 2 Byte pro adresse
	)
	port map (
		write_en	=> r_write_en
		,waddr		=> r_waddr
		,wclk		=> r_wclk
		,din		=> r_din
		
		,raddr		=> r_raddr
		,rclk		=> r_rclk
		,dout		=> w_dout
	);

	w_runner_data 	<= w_dout; --dpram 
	r_runner_begin 	<= w_ram_data_valid; --decoder
	r_raddr 		<= std_logic_vector(r_runner_cnt); --interner cnt
	--r_raddr 		<= std_logic(to_unsigned(r_runner_cnt, r_runner_addr_in'length)); --interner cnt

	--r_runner_addr_in 	<= std_logic(to_unsigned(r_runner_cnt,r_runner_addr_in'length)); --interner cnt
	--r_runner_addr_out 	<= std_logic(to_unsigned(r_runner_cnt,r_runner_addr_out'length));--interner cnt

	p_runner : process (i_Clk) -- stellt eine komponente dar, die den svnr speicher füllen soll, nachdem der dpram voll geschrieben wurde.
	begin
		if rising_edge(i_Clk) then
			if r_runner_reset = '1' then
				--r_runner_cnt <= 0;
				r_runner_cnt <= (others => '0');
				--r_runner_begin  '0';
				w_runner_done <= '0';
			elsif r_runner_begin = '1' then
				--r_runner_cnt <= 0;
				r_runner_cnt 		<= (others => '0');
				r_runner_running 	<= '1';
			elsif r_runner_running = '1'then
				--if r_runner_cnt < 1023 then
				if r_runner_cnt 	< "1111111111" then
				--if r_runner_cnt 	< "0000000011" then
					r_runner_cnt <= r_runner_cnt + 1;
				else 
					--r_runner_cnt 		<= '0';
					r_runner_cnt <= (others => '0');
					r_runner_running 	<= '0';
 					w_runner_done 		<= '1';
				end if;
			elsif w_runner_done = '1' then
				w_runner_done 			<= '0';
			end if;
		end if;
	end process;

end rtl;
