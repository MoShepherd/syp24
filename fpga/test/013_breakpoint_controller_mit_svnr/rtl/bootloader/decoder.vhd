-------------------------------------------------------------------------------
-- Description: Creates a Synchronous FIFO made out of registers.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_3_type.all;

entity decoder is
    port (
		-- clock and reset
        i_rst_sync : in std_logic;
        i_clk      : in std_logic;

        -- input Interface
        i_rd_data_burst   	: in std_logic_vector((c_WIDTH  * c_DEPTH ) - 1 downto 0 ); -- array of 3 byte
        i_read				: in std_logic;
		i_bp_edit_done 		: in std_logic;
		i_cpu_halt			: in std_logic;
		i_halt_address		: in std_logic_vector(15 downto 0);
		i_tx_done			: in std_logic;
        -- output Interface
        o_flush 			: out std_logic;
        o_data   			: out std_logic_vector((c_WIDTH  * c_DEPTH ) - 1 downto 0 ); -- (3 * 8) - 1
		o_status			: out std_logic_vector(23 downto 0) := X"000001"; -- status paket, welches von UART_tx abgegriffen und bei statusabfrage versendet wird.
		-- output RAM Interface
		i_runner_done		: in std_logic;
		o_ram_addr			: out std_logic_vector(9 downto 0);
		o_ram_data			: out std_logic_vector(15 downto 0);
		o_ram_wen			: out std_logic;
		o_ram_runner_begin	: out std_logic;
		o_ram_uploading		: out std_logic := '0';
		--o_ram_clk		: out std_logic_vector(); ist i_clk
		-- output Runner Interface
		o_ram_data_valid	: out std_logic;

		-- output breakpoint interface
		o_breakpoint_add	: out std_logic;
		o_breakpoint_delete	: out std_logic;
		o_breakpoint_value 	: out std_logic_vector(15 downto 0);

		o_cpu_run			: out std_logic; -- run/continue signal for bp controller and/or single step
		o_svnr_reset		: out std_logic;
		o_tx_trig			: out std_logic := '0'
	);
end decoder;

architecture rtl of decoder is
	 --CONSTANT c_RAM_SIZE : NATURAL := 4;
	 CONSTANT c_RAM_SIZE : NATURAL := 1024;
    signal r_FIFO_DATA : std_logic_vector((c_WIDTH * c_DEPTH ) - 1 downto 0 );

	-- ist diese statemachine nur für RAM upload zustände? Oder kann auch der bspw status zustand mit rein? 
	type STATE is (
		 z_POWER_ON				-- initialisierungs zustand
		,z_UPLOAD_TO_RAM 		-- wenn der befehl upload to ram gesendet wurde "0x01 00 02"
		,z_WRITE_TO_RAM 		-- der zustand wo write enable wieder auf 0 gelegt wird und der counter hochgerechnet wird
		,z_RAM_FULL 			-- zustand wenn der zÃ¤hler den max wert erreicht hat
		,z_RAM_NOT_FULL 		-- wenn eine status abfrage ausgefÃ¼hrt wird, bevor der ram voll ist
		,z_RAM_OVERFLOW  		-- wenn keine status abfrage durchgefÃ¼hrt wurde, nachdem der ram voll war und noch ein 0x02 XX XX reingekommen ist
		,z_RAM_FULL_OK   		-- wenn eine status abfrage richtig kam und damit bestÃ¤tigt wurde, dass jetzt der ram vom svnr gefÃ¼llt werden kann.
		,z_DEBUG_INIT   		-- DEBUG initialstate, von hier aus werden alle Debuganfragen gestartet
		,z_DEBUG_AWAIT_ADD_BP	-- DEBUG 1st state fürs erstellen eines breakpoints; warte auf weiteres BP Paket
		,z_DEBUG_AWAIT_DEL_BP	-- DEBUG 1st state fürs löschen eines breakpoints; warte auf weiteres BP Paket
		,z_ADDING_BP_WAIT_TX
		,z_DELETING_BP_WAIT_TX
		,z_DEBUG_ADDING_BP  	-- DEBUG 2nd state fürs erstellen eines bps; warte auf signal fertig vom breakpoint controller
		,z_DEBUG_DELETING_BP  	-- DEBUG 2nd state fürs löschen eines bps; warte auf signal fertig vom breakpoint controller
		,z_DEBUG_RUNNING  		-- DEBUG 2nd state fürs löschen eines bps; warte auf signal fertig vom breakpoint controller
		,z_DEBUG_WAIT_TX
		,z_DEBUG_HALT			-- Breakpoint found, or single step executed
		,z_RUNNING  			-- SVNR in Running Mode
		,z_RESETTING  			-- SVNR getting reset
	);
  	signal fsm_state_decoder: STATE := z_POWER_ON;
	signal ram_cnt 			: NATURAL := 0;
	--signal ram_cnt 			: NATURAL RANGE 0 TO c_RAM_SIZE - 1 := 0;
	signal ram_output_data 	: std_logic_vector(15 downto 0);
	signal data_address 	: std_logic_vector (9 downto 0); -- adresse fÃ¼r 1024 bit
	signal write_enable		: std_logic := '0';
	signal b_full			: std_logic := '0'; -- if cnt is at max value
	signal status			: std_logic_vector(23 downto 0) := X"000000"; -- startet auf status?
	signal b_new_data		: std_logic := '0'; -- damit man einen clock auf i_read wartet. Der wert von r_FIFO_DATA ist erst ein clock danach abgreifbar
	signal w_done			: std_logic := '0';

	-- signal for breakpoint controller
	-- signal w_breakpoint_add		: std_logic := '0';
	-- signal w_breakpoint_delete	: std_logic := '0';
	-- signal w_breakpoint_value 	: std_logic_vector(15 downto 0);

begin
	o_data 				<= r_FIFO_DATA; 
	o_ram_data_valid	<= w_done;

    p_CONTROL : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_rst_sync = '1' then
				r_FIFO_DATA <= (others => '0');
				o_flush <= '0';
				b_new_data <= '0';
            elsif i_read = '1' then
				r_FIFO_DATA <= i_rd_data_burst;
				b_new_data <= '1';
				o_flush <= '1';
			else
				o_flush <= '0';
				b_new_data <= '0';
            end if; -- sync reset
        end if; -- rising_edge(i_clk)
    end process p_CONTROL;

	o_status <=  status;
	-- Automat
	p_automat : PROCESS(i_Clk) 
	BEGIN 
	IF rising_edge(i_Clk) THEN 
			CASE fsm_state_decoder is
				WHEN z_POWER_ON	=> 		-- initialisierungs zustand
					o_svnr_reset <= '0';
					IF r_FIFO_DATA = X"010001" AND b_new_data = '1' THEN  -- EXECUTE SVNR
						-- init cnt
						status <= X"000004"; -- RUNNING
						o_cpu_run <= '1';
						fsm_state_decoder <= z_RUNNING;
						ram_cnt <= 0;
					END IF;
					IF r_FIFO_DATA = X"010002" AND b_new_data = '1' THEN  -- Jump into RAM upload mode
						-- init cnt
						status <= X"000002";
						o_ram_runner_begin <= '0';
						fsm_state_decoder <= z_UPLOAD_TO_RAM;
						ram_cnt <= 0;
					END IF;
					IF r_FIFO_DATA(23 downto 16) = X"02" AND b_new_data = '1' THEN  -- man muss immer nachgucken ob auch gerade gelesen wird
						-- init cnt
						status <= X"030013"; -- Error, no RAM transmission started yet!/Command not 
						fsm_state_decoder <= z_POWER_ON;
						ram_cnt <= 0;
					END IF;
					IF r_FIFO_DATA = X"010006" AND b_new_data = '1' THEN  -- Jump into RAM upload mode
						-- DEBUG MO	DE
						status <= X"000005";
						fsm_state_decoder <= z_DEBUG_INIT;
					END IF;
					IF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN
						-- on status query, current state has to hold its last state.
						status <= X"000001"; -- POWER_ON
					END IF;
					IF r_FIFO_DATA = X"010007" AND b_new_data = '1' THEN  -- reset svnr
						o_svnr_reset <= '1';
						o_cpu_run <= '1';
						fsm_state_decoder <= z_RESETTING;
					END IF;
					-- o_cpu_run <= '1';
					-- IF b_new_data = '1' THEN
					-- 	status <= X"030014"; -- no valid packet ERROR
					-- END IF; 

				WHEN z_UPLOAD_TO_RAM => -- wenn der befehl upload to ram gesendet wurde "0x01 00 02"
					--IF r_FIFO_DATA(r_FIFO_DATA'length - 1 downto r_FIFO_DATA'length - 8) = X"02" THEN 
					--IF r_FIFO_DATA(23 downto 16) = X"02" AND i_read = '1' THEN 
					-- status abfrage zu frÃ¼h
					IF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN
						fsm_state_decoder <= z_RAM_NOT_FULL;
						status <= X"030011";
					-- nÃ¤chstes ram inhalt
					ELSIF r_FIFO_DATA(23 downto 16) = X"02" AND b_new_data = '1' THEN
						o_ram_uploading <= '1';
						IF ram_cnt = c_RAM_SIZE - 1 THEN 
							b_full <= '1';
						ELSE 
							b_full <= '0';
						END IF;

						write_enable <= '1';
						ram_output_data <= r_FIFO_DATA(15 downto 0);
						fsm_state_decoder <= z_WRITE_TO_RAM;
					-- 	ELSIF b_new_data = '1' THEN
					-- 	status <= X"030014"; -- illegal packet received!
					-- 	fsm_state <=  z_POWER_ON;
					END IF;

				WHEN z_WRITE_TO_RAM => -- zwischen schritt um write enable auf 0 zu setzten und cnt hoch zuzÃ¤hlen
					write_enable <= '0'; -- damit der nicht die ganze zeit darauf geschrieben wird 
					-- status <= X"030010"; -- Error BUSY
					-- status <= X"000000";
					IF b_full = '1' THEN  -- wenn es die letzte stelle war
						fsm_state_decoder <= z_RAM_FULL;
					ELSE
						ram_cnt 	<= ram_cnt + 1;
						fsm_state_decoder 	<= z_UPLOAD_TO_RAM;
						
					END IF;
				WHEN z_RAM_FULL =>		-- zustand wenn der zÃ¤hler den max wert erreicht hat
					-- wait on next sig
					IF r_FIFO_DATA(23 downto 16) = X"02" AND b_new_data = '1' THEN  -- zuviele daten
						ram_cnt		<= 0; -- setzte den ram adresse zurÃ¼ck ram inhalt wird nicht geleert aber auch nicht abgefangen
						status <=  X"030012"; -- ERROR RAM overflow
						o_ram_uploading <= '0';
						fsm_state_decoder 	<= z_RAM_OVERFLOW;

					END IF;	
					IF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN  -- status abfrage zu frÃ¼h
						ram_cnt		<= 0; -- setzte den ram adresse zurÃ¼ck ram inhalt wird nicht geleert aber auch nicht abgefangen
						o_ram_runner_begin <= '1';
						status <=  X"000003"; -- Der Ram ist richtig gefüllt der SVNR kann gestartet werden
						o_ram_uploading <= '0';
						fsm_state_decoder 	<= z_RAM_FULL_OK;

					END IF;	
				WHEN z_RAM_NOT_FULL =>	-- wenn eine status abfrage ausgefÃ¼hrt wird, bevor der ram voll ist
					--return error stuff
					ram_cnt		<= 0; -- setzte den ram adresse zurÃ¼ck ram inhalt wird nicht geleert aber auch nicht abgefangen
					fsm_state_decoder 	<= z_POWER_ON;

					 -- ERROR TRANSMITION INCOMPLETE
				WHEN z_RAM_OVERFLOW => 	-- wenn keine status abfrage durchgefÃ¼hrt wurde, nachdem der ram voll war und noch ein 0x02 XX XX reingekommen ist
					IF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN  -- status abfrage zu frÃ¼h
						ram_cnt		<= 0; -- setzte den ram adresse zurÃ¼ck ram inhalt wird nicht geleert aber auch nicht abgefangen
						fsm_state_decoder 	<= z_POWER_ON;
						
					 -- ERROR ram overflow
					END IF;

				WHEN z_RAM_FULL_OK =>  	-- wenn eine status abfrage richtig kam und damit bestÃ¤tigt wurde, dass jetzt der ram vom svnr gefÃ¼llt werden kann.
					-- set signal to fill svnr ram from buffer
					if i_runner_done = '1' then
						o_ram_runner_begin <= '0';
						status <= X"000001"; --poweron
						fsm_state_decoder 	<= z_POWER_ON;
					end if;
				-- TODO: BREAKPOINTS Routines-  
				WHEN z_DEBUG_INIT => 
					-- an dieser stelle bezieht der cpu_en des svnr sein signal vom Breakpoint controller
					-- TODO: was geschieht im single step modus?

					o_breakpoint_add 	<= '0';
					o_breakpoint_delete <= '0';

					o_svnr_reset		<= '0';
					o_cpu_run 			<= '0';

					o_tx_trig			<= '0';
					-- TODO: gibt es einen grundsätzlichen cpu_run??

					IF r_FIFO_DATA = X"010007" AND b_new_data = '1' THEN  -- reset svnr
						o_svnr_reset <= '1';
						o_cpu_run <= '1';
						status <= X"000007";
					END IF;

					IF r_FIFO_DATA = X"010001" AND b_new_data = '1' THEN  -- start running
						o_cpu_run <= '1';
						status <= X"000006"; -- Status running
						fsm_state_decoder <= z_DEBUG_WAIT_TX;
					END IF;

					IF r_FIFO_DATA = X"010102" AND b_new_data = '1' THEN  -- SET BREAKPOINT Comand
						status <= X"000008"; -- ACK
						fsm_state_decoder <= z_DEBUG_AWAIT_ADD_BP;
					END IF;

					IF r_FIFO_DATA = X"010103" AND b_new_data = '1' THEN  -- DEL BREAKPOINT Comand
						o_cpu_run <= '0';
						status <= X"000009"; -- ACK
						fsm_state_decoder <= z_DEBUG_AWAIT_DEL_BP;
					END IF;

				-- ADD/DELETE BREAKPOINTS
				WHEN z_DEBUG_WAIT_TX => 
					IF i_tx_done = '1' THEN
						fsm_state_decoder <= z_DEBUG_RUNNING;
					END IF;
				
				WHEN z_DEBUG_RUNNING => 
					-- IF i_tx_done = '1' THEN
						status(23 downto 16) <= X"05";
						status(15 downto 0) <= i_halt_address;
						o_tx_trig <= '1';
					-- END IF;
					
					IF r_FIFO_DATA = X"010008" AND b_new_data = '1' THEN  -- stop running
						fsm_state_decoder <= z_DEBUG_INIT;
						status <= X"000005"; -- status DEBUG_INIT
					END IF;
					-- breakpoint found, or single step executed
					IF i_cpu_halt = '1' THEN
						o_cpu_run <= '0';
						status(23 downto 16) <= X"05"; -- Addresspaket
						status(15 downto 0) <= i_halt_address; -- kopiere halt addresse, also pc an halt stelle
						o_tx_trig <= '1';
						fsm_state_decoder <= z_DEBUG_HALT;
					END IF;

				WHEN z_DEBUG_HALT => 
					o_tx_trig <= '0';
					IF r_FIFO_DATA = X"010001" AND b_new_data = '1' THEN  -- start running
						o_cpu_run <= '1';
						status <= X"000006"; -- status RUNNING
						fsm_state_decoder <= z_DEBUG_WAIT_TX;
						-- status <= X""; -- TODO: Status DEBUG HALT
					END IF;
				WHEN z_DEBUG_AWAIT_ADD_BP => 
					IF r_FIFO_DATA(23 downto 16) = X"05" AND b_new_data = '1' THEN  -- erwarte addresse des breakpoints
							
							o_breakpoint_value <= r_FIFO_DATA(15 downto 0);  		
							o_breakpoint_add <= '1';
							status <= X"111111"; -- acknowledgement
							fsm_state_decoder <= z_ADDING_BP_WAIT_TX;
					END IF;

				WHEN z_DEBUG_AWAIT_DEL_BP => 
					IF r_FIFO_DATA(23 downto 16) = X"05" AND b_new_data = '1' THEN  -- erwarte addresse des breakpoints
							
							o_breakpoint_value <= r_FIFO_DATA(15 downto 0);  
							o_breakpoint_delete <= '1';
							status <= X"222222"; -- acknowledgement
							fsm_state_decoder <= z_DEBUG_DELETING_BP;
					END IF;

				WHEN z_ADDING_BP_WAIT_TX => 
					IF i_bp_edit_done = '1' THEN
						fsm_state_decoder <= z_DEBUG_ADDING_BP;
					END IF;

				WHEN z_DELETING_BP_WAIT_TX => 
					IF i_bp_edit_done = '1' THEN
						fsm_state_decoder <= z_DEBUG_DELETING_BP;
					END IF;

				WHEN z_DEBUG_ADDING_BP => 
					-- Breakpoint wird in Liste geschrieben
					if i_tx_done = '1' then 
						o_tx_trig <= '1';
						o_breakpoint_add <= '0';
						status <= X"000005";
						fsm_state_decoder <= z_DEBUG_INIT;
					END IF;

				WHEN z_DEBUG_DELETING_BP => 
					IF i_tx_done = '1' then 
						o_breakpoint_delete <= '0';
						status <= X"000005";
						fsm_state_decoder <= z_DEBUG_INIT;
					END IF;
				WHEN z_RUNNING => 
					IF r_FIFO_DATA = X"010007" AND b_new_data = '1' THEN  -- reset svnr
						o_svnr_reset <= '1';
						o_cpu_run <= '1';
						status <=  X"000007";
						fsm_state_decoder <= z_RESETTING;
					END IF;					
				
				WHEN z_RESETTING =>
					o_svnr_reset <= '0';
					o_cpu_run <= '0';
					status <= X"000001";
					fsm_state_decoder <= z_POWER_ON;

				WHEN OTHERS =>
					fsm_state_decoder <= z_POWER_ON;
			END CASE;
		-- END IF;
	END IF;
	END PROCESS;

	o_ram_addr 	<= std_logic_vector(to_unsigned(ram_cnt,o_ram_addr'length));
	o_ram_data 	<= ram_output_data;
	o_ram_wen 	<= write_enable;

end rtl;
