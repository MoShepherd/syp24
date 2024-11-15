--! \file bootloader_top.vhd
--! \brief top Entität des Bootloaders, enthält die gesamte Bootloader Funktionalität  
--! 
--! Stellt Ports zur direkten Interaktion mit SVNR bereit.
--!	Direkte Interaktion mit FPGA Pins erfolgt durch: 
--! i_rxd
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_3_type.all;

--! \brief top Entität des Bootloaders, enthält die gesamte Bootloader Funktionalität  
--! 
--! Stellt Ports zur direkten Interaktion mit SVNR bereit.
--!	Direkte Interaktion mit FPGA Pins erfolgt durch: 
--! i_rxd
--!
entity bootloader_top is
	port (
		i_Clk             : in std_logic;						
		i_rxd             : in std_logic;							--! Serielle UART RX Daten
		i_program_counter : in std_logic_vector(15 downto 0);		--! Program Counter des SVNR
		i_cpu_step_fin    : in std_logic;							--! Wird high wenn die SVNR CPU einen Step vollzogen hat
		--o_output 	: out std_logic_vector(24 - 1 downto 0 );
		o_txd              : out std_logic;							--! Serielle UART TX Daten
		o_svnr_cpu_en      : out std_logic;							--! CPU enable fuer den SVNR
		o_svnr_ram_address : out std_logic_vector(15 downto 0);		--! Wenn Bootloader SVNR-RAM Read/Write Kontrolle hat (bspw. bei Image-Upload oder Debug RAM Abfrage): Addresse des zuzugreifendem RAM
		o_svnr_ram_data_in : out std_logic_vector(15 downto 0);		--! Wenn Bootloader SVNR-RAM Write Kontrolle hat (bspw. bei Image-Upload): RAM Daten an der Adresse von `o_svnr_ram_address`
		o_svnr_wnr         : out std_logic;							--! Wenn Bootloader SVNR-RAM Read/Write Kontrolle hat: wnr Signal fuer SVNR (Siehe SVNR Dokumentation)
		o_svnr_addrstrb    : out std_logic;							--! Wenn Bootloader SVNR-RAM Read/Write Kontrolle hat: addrstrb Signal fuer SVNR (Siehe SVNR Dokumentation)
		o_svnr_run         : out std_logic;							--! Startet den SVNR - zusaetzlich zu cpu_en benoetigt  
		o_svnr_reset	   : out std_logic							--! Sorgt fuer einen reset der SVNR CPU. Program Counter und alle Register werden genullt.
	);
end bootloader_top;

architecture rtl of bootloader_top is
	--! Want to interface to 115200 baud UART
	--! 50000000 / 115200 = 434.028 Clocks Per Bit.
	constant c_CLKS_PER_BIT : integer := 434;
	constant c_WIDTH : integer := 8;
	constant c_DEPTH : integer := 2;
	constant c_ADDR_WIDTH : natural := 10;
	constant c_DATA_WIDTH : natural := 16;

	--constant cnt_size: integer := 5000;
	-- type
	--signals

	-- UART_TX signale
	signal r_Clk : std_logic;
	signal r_RX_Serial : std_logic;
	signal w_RX_DV : std_logic; 					--! data valid pulse: indicates when RX_Byte has valid content
	signal w_RX_Byte : std_logic_vector(7 downto 0);
	signal s_tx_packet_done : std_logic := '1';
	signal tx_buf_rdy : std_logic;

	-- Fifo
	signal w_rd_data_burst : std_logic_vector(24 - 1 downto 0); -- (3 * 8) - 1

	signal r_Reset : std_logic := '0'; -- wird als flush verwendet
	signal r_WR_EN : std_logic := '0';
	signal r_WR_DATA : std_logic_vector (7 downto 0);
	signal w_FULL : std_logic := '0'; -- wird als logik fÃ¼r wr_en verwendet
	signal r_RD_EN : std_logic := '0'; -- wird nicht verwendet
	signal w_RD_DATA : std_logic_vector (7 downto 0); -- wird nicht verwendet
	signal w_EMPTY : std_logic := '0'; -- wird nicht verwendet

	--	decoder
	signal r_rst_sync 			: std_logic := '0';
	signal r_rd_data_burst 		: std_logic_vector(24 - 1 downto 0); -- array of 3 byte
	signal r_read 				: std_logic := '0';
	signal w_flush 				: std_logic := '0';
	signal w_data 				: std_logic_vector(24 - 1 downto 0); -- (3 * 8) - 1
	signal w_status 			: std_logic_vector(23 downto 0);
	signal w_ram_addr 			: std_logic_vector(9 downto 0);
	signal w_ram_data 			: std_logic_vector(15 downto 0);
	signal w_ram_wen 			: std_logic := '0';
	signal w_ram_data_valid 	: std_logic := '0';
	signal w_ram_runner_begin 	: std_logic := '0';
	signal w_ram_uploading 		: std_logic;
	signal r_cpu_halt			: std_logic;
	signal s_tx_trig			: std_logic := '0';

	-- tx buffer
	signal r_wen : std_logic; -- Write enable
	signal r_data_in : std_logic_vector(23 downto 0); -- Input data
	signal w_data_out : std_logic_vector(23 downto 0); -- Output data
	signal w_tx_rdy_to_fetch : std_logic;
	-- UART TX 
	--signal r_Clk       	: std_logic; -- schon deklariert
	signal r_TX_DV : std_logic;
	signal r_TX_Byte : std_logic_vector(7 downto 0);
	signal w_TX_Active : std_logic;
	signal w_TX_Serial : std_logic;
	signal w_TX_Done : std_logic;

	-- DPRAM
	signal r_write_en : std_logic;
	signal r_waddr : std_logic_vector(c_ADDR_WIDTH - 1 downto 0) := (others => '0');
	signal r_wclk : std_logic;
	signal r_din : std_logic_vector(c_DATA_WIDTH - 1 downto 0);
	signal r_raddr : std_logic_vector(c_ADDR_WIDTH - 1 downto 0) := (others => '0');
	signal r_rclk : std_logic;
	signal w_dout : std_logic_vector(c_DATA_WIDTH - 1 downto 0);
	--DPRAM END

	-- BREAKPOINT CONTROLLER
	signal r_program_counter : std_logic_vector(15 downto 0);
	signal r_breakpoint_delete : std_logic;
	signal r_breakpoint_add : std_logic;
	signal s_breakpoint_value : std_logic_vector(15 downto 0);
	signal w_bp_controller_cpu_en : std_logic;
	signal r_bp_edit_done : std_logic;
	signal s_breakpoint_enable : std_logic;

	-- SINGLE STEP
	signal w_single_step_cpu_en : std_logic;
	signal s_ss_run : std_logic;

	-- cpu_en mux
	signal s_cpu_run : std_logic;
	signal s_cpu_en_mux_out : std_logic;

	-- runner
	signal r_runner_done : std_logic;

	type STATE is (
		z_tx_start
		, z_tx_byte
		, z_count
	);
	signal fsm_state : STATE := z_tx_start;

	signal tx_packet_byte_cnt : natural range 0 to 2 := 0;

begin
	r_Clk <= i_Clk;
	r_RX_Serial <= i_rxd;

	r_rd_en <= '0';
	r_rst_sync <= '0';

	--! UART RX Komponente
	UART_RX_INST : entity work.UART_RX
		generic map(
			g_CLKS_PER_BIT => c_CLKS_PER_BIT
		)
		port map(
			i_Clk         => r_Clk
			, i_RX_Serial => r_RX_Serial
			, o_RX_DV     => w_RX_DV
			, o_RX_Byte   => w_RX_Byte
		);

	r_wr_en <= w_RX_DV and not w_FULL; --nochmal spÃ¤ter angucken -- was machen wir bei overflow?
	r_WR_DATA <= w_RX_Byte;

	--! UART RX Buffer
	FIFO_INST : entity work.fifo_3
		port map(
			i_rst_sync => r_Reset, -- wird als flush verwendet
			i_clk      => r_Clk,

			i_wr_en   => r_WR_EN,
			i_wr_data => r_WR_DATA,
			o_full    => w_FULL, -- wird als logik fÃ¼r wr_en verwendet

			i_rd_en         => r_RD_EN,   -- wird nicht verwendet
			o_rd_data       => w_RD_DATA, -- wird nicht verwendet
			o_empty         => w_EMPTY,   -- wird nicht verwendet
			o_rd_data_burst => w_rd_data_burst
		);

	r_rd_data_burst <= w_rd_data_burst;
	r_Reset <= w_flush;
	r_read <= w_FULL;
	r_data_in <= w_status;
	o_svnr_run <= s_cpu_run;

	--! Decoder für Bootloader Pakete - enthält die Grundlogik des Bootloaders
	decoder_inst : entity work.decoder
		port map(
			i_rst_sync => r_rst_sync
			, i_clk    => r_Clk
			-- input Interface
			, i_rd_data_burst 	  	=> r_rd_data_burst
			, i_read          	  	=> r_read
			, i_bp_edit_done  	  	=> r_bp_edit_done
			, i_runner_done  	  	=> r_runner_done
			, i_cpu_halt 		  	=> r_cpu_halt
			, i_halt_address	  	=> r_program_counter
			, i_tx_done			  	=> s_tx_packet_done
			-- output Interface
			, o_flush             	=> w_flush
			, o_data              	=> w_data
			, o_status            	=> w_status
			, o_ram_addr          	=> w_ram_addr
			, o_ram_data          	=> w_ram_data
			, o_ram_wen           	=> w_ram_wen
			, o_ram_data_valid    	=> w_ram_data_valid
			, o_ram_runner_begin  	=> w_ram_runner_begin
			, o_ram_uploading	  	=> w_ram_uploading
			, o_breakpoint_add    	=> r_breakpoint_add
			, o_breakpoint_delete 	=> r_breakpoint_delete
			, o_breakpoint_value  	=> s_breakpoint_value
			, o_cpu_run           	=> s_cpu_run
			, o_svnr_reset		  	=> o_svnr_reset
			, o_tx_trig			  	=> s_tx_trig
		);

	runner_inst: entity work.runner
		port map(
			i_Clk				=> r_Clk,
			i_Begin				=> w_ram_runner_begin,
			o_Done				=> r_runner_done,
			i_dpram_data		=> w_dout,
			o_dpram_raddr		=> r_raddr, 			--same as o_svnr_ram_address
			o_svnr_ram_address	=> o_svnr_ram_address, 	--same as o_dpram_raddr
			o_svnr_ram_data_in	=> o_svnr_ram_data_in, 	--same as i_dpram_data
			o_svnr_wnr			=> o_svnr_wnr,
			o_svnr_addrstrb		=> o_svnr_addrstrb		
		);

	tx_buffer_inst : entity work.tx_buffer
		port map(
			clk            => r_Clk,
			wen            => r_wen,
			data_in        => r_data_in,
			data_out       => w_data_out,
			o_rdy_to_fetch => w_tx_rdy_to_fetch
		);

	r_wen <= w_flush or s_tx_trig;
	--o_output 	<= w_data; 
	UART_TX_inst : entity work.UART_TX
		generic map(
			-- 50000000 / 115200 = 434.028 Clocks Per Bit.
			g_CLKS_PER_BIT => c_CLKS_PER_BIT -- Needs to be set correctly
		)
		port map(
			i_Clk         => r_Clk
			, i_TX_DV     => r_TX_DV
			, i_TX_Byte   => r_TX_Byte
			, o_TX_Active => w_TX_Active
			, o_TX_Serial => w_TX_Serial
			, o_TX_Done   => w_TX_Done
		);
	--port map ( r_Clk,r_TX_DV,r_TX_Byte,w_TX_Active,w_TX_Serial,w_TX_Done);

	o_txd <= w_TX_Serial;

	r_TX_Byte <= w_data_out(23 downto 16) when tx_packet_byte_cnt = 0 else
		w_data_out(15 downto 8) when tx_packet_byte_cnt = 1 else
		w_data_out(7 downto 0);
	
	-- Statemachine zur Koordination des Versenden eines Bootloader Response Pakets
	p_automat : process (i_Clk)
	begin
		if rising_edge(i_Clk) then
			case fsm_state is
				when z_tx_start =>
					-- if w_ram_uploading = '0' and (w_flush = '1' or s_tx_trig = '1' or tx_packet_byte_cnt >= 1) then
					if w_ram_uploading = '0' and (w_tx_rdy_to_fetch = '1' or tx_packet_byte_cnt >= 1) then
						s_tx_packet_done <= '0';
						r_Tx_DV <= '1';
						fsm_state <= z_tx_byte;
					end if;

				when z_tx_byte =>
					r_Tx_DV <= '0';
					if w_TX_Done = '1' then
						fsm_state <= z_count;
					end if;
					
				when z_count =>
					-- r_Tx_DV <= '0';
					if tx_packet_byte_cnt >= 2 then
						tx_packet_byte_cnt <= 0;
						s_tx_packet_done <= '1';
						fsm_state <= z_tx_start;
					else
						tx_packet_byte_cnt <= tx_packet_byte_cnt + 1;
						fsm_state <= z_tx_start;
					end if;
			end case;
		end if;
	end process;

	-- DECODER -> DPRAM signal
	r_write_en <= w_ram_wen;
	r_waddr <= w_ram_addr;
	r_wclk <= r_clk;
	r_rclk <= r_clk;
	r_din <= w_ram_data;

	-- DPRAM
	dpram_inst : entity work.dpram
		generic map(
			addr_width   => c_ADDR_WIDTH --1024 speicher adressen 
			, data_width => c_DATA_WIDTH -- 2 Byte pro adresse
		)
		port map(
			write_en => r_write_en
			, waddr  => r_waddr
			, wclk   => r_wclk
			, din    => r_din

			, raddr  => r_raddr
			, rclk   => r_rclk
			, dout   => w_dout
		);

	r_program_counter <= i_program_counter;
	-- r_breakpoint_delete <= ;
	-- r_breakpoint_add 	<= ;
	-- r_breakpoint_value 	<= ;

	breakpoint_controller_inst : entity work.breakpoint_controller
		port map(
			i_clk               => r_wclk,
			i_program_counter   => r_program_counter,
			i_breakpoint_delete => r_breakpoint_delete,
			i_breakpoint_add    => r_breakpoint_add,
			i_breakpoint_value  => s_breakpoint_value,
			i_breakpoint_enable => s_breakpoint_enable,
			i_run               => s_cpu_run,
			o_cpu_en            => w_bp_controller_cpu_en,
			o_cpu_halt			=> r_cpu_halt,
			o_edit_done         => r_bp_edit_done
		);

	single_step_inst : entity work.single_step
		port map(
			i_run          => s_cpu_run,
			i_cpu_step_fin => i_cpu_step_fin,
			o_cpu_en       => w_single_step_cpu_en
		);

	-- detect rising edge on s_cpu_run and enable cpu run in general
	process (i_clk, s_cpu_run)
	begin
		if rising_edge(i_clk) then
			if s_cpu_run = '1' then
				o_svnr_cpu_en <= s_cpu_en_mux_out;
			else
				o_svnr_cpu_en <= '0';
			end if;
		end if;
	end process;

	-- Schaltet zwischen den Erzeugern des cpu_en Signal. Da im Moment nur Breakpoints die CPU steuern können, ist diese Verbindung hardwired. 
	cpu_en_mux : entity work.mux_4_1
		port map(
			a               => w_bp_controller_cpu_en,
			b               => w_single_step_cpu_en, -- TODO: UPLOAD RAM Mode?
			c               => '1',	
			d               => '0',
			y               => s_cpu_en_mux_out,
			sel(1 downto 0) => "00"
		);

end rtl;