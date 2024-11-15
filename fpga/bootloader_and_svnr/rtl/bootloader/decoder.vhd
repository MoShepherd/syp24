--! \file decoder.vhd
--! \brief Verarbeitet Bootloader Pakete und leitet diese an die entsprechenden Funktionalit�ten des Bootloaders weiter. 
--! 
--! Bietet Signale zum Beschreiben des SVNR Rams (`o_ram_addr`, `o_ram_data`, `o_ram_wen`, `o_ram_runner_begin`, `o_ram_uploading`)
--! , sowie das `cpu_en` Signal, welches die CPU des SVNRs steuern kann.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fifo_3_type.all;

--! \brief Verarbeitet Bootloader Pakete und leitet diese an die entsprechenden Funktionalit�ten des Bootloaders weiter. 
--! 
--! Bietet Signale zum Beschreiben des SVNR Rams (`o_ram_addr`, `o_ram_data`, `o_ram_wen`, `o_ram_runner_begin`, `o_ram_uploading`)
--! , sowie das `cpu_en` Signal, welches die CPU des SVNRs steuern kann.
--!
--! Auf jedes empfangene Bootloader Paket gibt der Decoder eine Response �ber `o_status` an den UART TX weiter, welcher an die Host App zur�ck gesendet wird. 
--! Diese Response kann entweder als einfache Statusinformationen/Acknowledgment dienen, oder angeforderte Daten zur�ckgeben. 	
--! Die Hauptaufgabe des Decoders liegt in seiner Statemachine, in der die UART Inputs verarbeitet werden und entsprechende Aktionen in der Programmlogik des Bootloaders ausgef�hrt werden.
--! Diese Logik umfasst:
--! - Korrektes Kopieren des Bin�rimage in den SVNR RAM
--! - Pr�fung der Integrit�t einer vollst�ndigen �bertragung des Bin�rimage
--! - Erzeugen von Statusmeldungen/Fehlermeldungen, welche als Response an die Host App zur�ck �bertragen werden werden sollen
--! - Stati zum Einhalten der Reihenfolge aller Debugger Funktionalit�ten, hierzu geh�rt:
--! - Breakpoints hinzuf�gen/l�schen
--! - SVNR CPU starten/stoppen
entity decoder is
    port (
		-- clock and reset
        i_rst_sync : in std_logic;
        i_clk      : in std_logic;

        -- input Interface
        i_rd_data_burst   	: in std_logic_vector((c_WIDTH  * c_DEPTH ) - 1 downto 0 ); 	--! 3 Byte - 1 Bootloader Paket Input aus dem FIFO RX Input Buffer
        i_read				: in std_logic;													--! Read Signal welches die anliegenden 3 Byte 
		i_bp_edit_done 		: in std_logic;													--! Signalisiert Breakpoint Hinzufuegen/Loeschen abgeschlossen
		i_cpu_halt			: in std_logic;													--! Signalisiert CPU ist angehalten (Enweder in Breakpoint gefahren, oder im Single-Step Modus Step vollzogen)
		i_halt_address		: in std_logic_vector(15 downto 0);								--! Indiziert die Adresse, an der die CPU angehalten hat. 
		i_tx_done			: in std_logic;													--! Signalisiert ein gesamtes Bootloader Paket (3 Byte) per UART uebertragen
        -- output Interface	
        o_flush 			: out std_logic;												--! Bootloader Paket ist erfolgreich gelesen - Signalisiert Starten der TX Response
        o_data   			: out std_logic_vector((c_WIDTH  * c_DEPTH ) - 1 downto 0 ); 	--! Gibt direkt das zuletzt vollstaendig gelesene Bootloader RX Paket nach aussen
		o_status			: out std_logic_vector(23 downto 0) := X"000001"; 				--! Status/Response Paket, welches von UART_tx abgegriffen und bei Statusabfrage versendet wird.
		-- output RAM Interface
		i_runner_done		: in std_logic;													--! Signalisiert Kopieren von DPRAM in den SVNR RAM erfolgreich abgeschlossen - Wenn das Signal high ist, ist die RAM Uebertragung vollstaendig abgeschlossen
		o_ram_addr			: out std_logic_vector(9 downto 0);								--! 
		o_ram_data			: out std_logic_vector(15 downto 0);							--! 
		o_ram_wen			: out std_logic;												--! 
		o_ram_runner_begin	: out std_logic;												--! Startet das Kopieren von DPRAM in den SVNR RAM durch den Runner
		o_ram_uploading		: out std_logic := '0';											--! Signalisiert eine laufende RAM Uebertragung
		-- output Runner Interface
		o_ram_data_valid	: out std_logic;												--! Indiziert die Integritaet des DPRAMs an den Runner

		-- output breakpoint interface
		o_breakpoint_add	: out std_logic;												--! Signalisiert Hinzufuegen eines Breakpoints an den Breakpoint-Controller
		o_breakpoint_delete	: out std_logic;												--! Signalisiert Loeschen eines Breakpoints an den Breakpoint-Controller
		o_breakpoint_value 	: out std_logic_vector(15 downto 0);							--! Adresse des Hinzuzufuegenden/ zu Loeschenden Breakpoints 

		o_cpu_run			: out std_logic; 												--! run/continue Signal fuer Breakpoint Controller und/oder Single-Step
		o_svnr_reset		: out std_logic;												--! SVNR Reset
		o_tx_trig			: out std_logic := '0'											--! Startet UART TX Response Paketuebertragung
	);
end decoder;

architecture rtl of decoder is
	 --CONSTANT c_RAM_SIZE : NATURAL := 128;
	CONSTANT c_RAM_SIZE : NATURAL := 1024;
    signal r_FIFO_DATA : std_logic_vector((c_WIDTH * c_DEPTH ) - 1 downto 0 );

	-- ist diese statemachine nur f�r RAM upload zust�nde? Oder kann auch der bspw status zustand mit rein? 
	type STATE is (
		 z_POWER_ON				--! initialisierungs zustand
		,z_UPLOAD_TO_RAM 		--! wenn der befehl upload to ram gesendet wurde "0x01 00 02"
		,z_WRITE_TO_RAM 		--! der zustand wo write enable wieder auf 0 gelegt wird und der counter hochgerechnet wird
		,z_RAM_FULL 			--! zustand wenn der zähler den max wert erreicht hat
		,z_RAM_NOT_FULL 		--! wenn eine status abfrage ausgeführt wird, bevor der ram voll ist
		,z_RAM_OVERFLOW  		--! wenn keine status abfrage durchgeführt wurde, nachdem der ram voll war und noch ein 0x02 XX XX reingekommen ist
		,z_RAM_FULL_OK   		--! wenn eine status abfrage richtig kam und damit bestätigt wurde, dass jetzt der ram vom svnr gefüllt werden kann.
		,z_DEBUG_INIT   		--! DEBUG initialstate, von hier aus werden alle Debuganfragen gestartet
		,z_DEBUG_AWAIT_ADD_BP	--! DEBUG 1st state f�rs erstellen eines breakpoints; warte auf weiteres BP Paket
		,z_DEBUG_AWAIT_DEL_BP	--! DEBUG 1st state f�rs l�schen eines breakpoints; warte auf weiteres BP Paket
		,z_ADDING_BP_WAIT_TX	--! Warte bis Status korrekt �ber UART TX versendet worden ist.
		,z_DELETING_BP_WAIT_TX  --! Warte bis Status korrekt �ber UART TX versendet worden ist.
		,z_DEBUG_ADDING_BP  	--! DEBUG 2nd state f�rs erstellen eines bps; warte auf signal fertig vom breakpoint controller
		,z_DEBUG_DELETING_BP  	--! DEBUG 2nd state f�rs l�schen eines bps; warte auf signal fertig vom breakpoint controller
		,z_DEBUG_RUNNING  		--! DEBUG 2nd state f�rs l�schen eines bps; warte auf signal fertig vom breakpoint controller
		,z_DEBUG_WAIT_TX		--! Warte bis Status korrekt �ber UART TX versendet worden ist.
		,z_DEBUG_HALT			--! Breakpoint found, or single step executed
		,z_RUNNING  			--! SVNR in Running Mode
		,z_RESETTING  			--! SVNR getting reset
	);
  	signal fsm_state_decoder: STATE := z_POWER_ON;
	signal ram_cnt 			: NATURAL := 0;
	signal ram_output_data 	: std_logic_vector(15 downto 0);
	signal data_address 	: std_logic_vector (9 downto 0); -- adresse f�r 1024 bit
	signal write_enable		: std_logic := '0';
	signal b_full			: std_logic := '0'; -- if cnt is at max value
	signal status			: std_logic_vector(23 downto 0) := X"000000"; -- startet auf status?
	signal b_new_data		: std_logic := '0'; -- damit man einen clock auf i_read wartet. Der wert von r_FIFO_DATA ist erst ein clock danach abgreifbar
	signal w_done			: std_logic := '0';

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

				WHEN z_UPLOAD_TO_RAM => -- wenn der befehl upload to ram gesendet wurde "0x01 00 02"
					--IF r_FIFO_DATA(r_FIFO_DATA'length - 1 downto r_FIFO_DATA'length - 8) = X"02" THEN 
					--IF r_FIFO_DATA(23 downto 16) = X"02" AND i_read = '1' THEN 
						-- status abfrage zu früh
					IF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN
						fsm_state_decoder <= z_RAM_NOT_FULL;
						status <= X"030011";
					-- nächstes ram inhalt
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

				WHEN z_WRITE_TO_RAM => -- zwischen schritt um write enable auf 0 zu setzten und cnt hoch zuzählen
					write_enable <= '0'; -- damit der nicht die ganze zeit darauf geschrieben wird 
					-- status <= X"030010"; -- Error BUSY
					IF b_full = '1' THEN  -- wenn es die letzte stelle war
						fsm_state_decoder <= z_RAM_FULL;
					ELSE
						ram_cnt 	<= ram_cnt + 1;
						fsm_state_decoder 	<= z_UPLOAD_TO_RAM;
						
					END IF;
				WHEN z_RAM_FULL =>		-- zustand wenn der zähler den max wert erreicht hat
					-- wait on next sig
					IF r_FIFO_DATA(23 downto 16) = X"02" AND b_new_data = '1' THEN  -- zuviele daten
						ram_cnt		<= 0; -- setzte den ram adresse zurück ram inhalt wird nicht geleert aber auch nicht abgefangen
						status <=  X"030012"; -- ERROR RAM overflow
						o_ram_uploading <= '0';
						fsm_state_decoder 	<= z_RAM_OVERFLOW;

					END IF;	
					IF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN  -- status abfrage zu früh
						ram_cnt		<= 0; -- setzte den ram adresse zurück ram inhalt wird nicht geleert aber auch nicht abgefangen
						o_ram_runner_begin <= '1';
						status <=  X"000003"; -- Der Ram ist richtig gef�llt der SVNR kann gestartet werden
						o_ram_uploading <= '0';
						fsm_state_decoder 	<= z_RAM_FULL_OK;

					END IF;	
				WHEN z_RAM_NOT_FULL =>	-- wenn eine status abfrage ausgeführt wird, bevor der ram voll ist
					--return error stuff
					ram_cnt		<= 0; -- setzte den ram adresse zurück ram inhalt wird nicht geleert aber auch nicht abgefangen
					fsm_state_decoder 	<= z_POWER_ON;

					 -- ERROR TRANSMITION INCOMPLETE
				WHEN z_RAM_OVERFLOW => 	-- wenn keine status abfrage durchgeführt wurde, nachdem der ram voll war und noch ein 0x02 XX XX reingekommen ist
					IF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN  -- status abfrage zu früh
						ram_cnt		<= 0; -- setzte den ram adresse zurück ram inhalt wird nicht geleert aber auch nicht abgefangen
						fsm_state_decoder 	<= z_POWER_ON;
						
					 -- ERROR ram overflow
					END IF;

				WHEN z_RAM_FULL_OK =>  	-- wenn eine status abfrage richtig kam und damit bestätigt wurde, dass jetzt der ram vom svnr gefüllt werden kann.
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

					IF r_FIFO_DATA = X"010007" AND b_new_data = '1' THEN  -- reset svnr
						o_svnr_reset <= '1';
						o_cpu_run <= '1';
						status <= X"000007";
					END IF;

					IF r_FIFO_DATA = X"010001" AND b_new_data = '1' THEN  -- start running
						o_cpu_run <= '0';
						status <= X"000006"; -- Status running
						fsm_state_decoder <= z_DEBUG_WAIT_TX;
					END IF;

					IF r_FIFO_DATA = X"010102" AND b_new_data = '1' THEN  -- SET BREAKPOINT Comand
						status <= X"000008"; -- await set address
						fsm_state_decoder <= z_DEBUG_AWAIT_ADD_BP;
					END IF;

					IF r_FIFO_DATA = X"010103" AND b_new_data = '1' THEN  -- DEL BREAKPOINT Comand
						o_cpu_run <= '0';
						status <= X"000009"; -- await del address
						fsm_state_decoder <= z_DEBUG_AWAIT_DEL_BP;
					END IF;

				-- ADD/DELETE BREAKPOINTS
				WHEN z_DEBUG_WAIT_TX => 
					IF i_tx_done = '1' THEN
						o_cpu_run <= '1';
						fsm_state_decoder <= z_DEBUG_RUNNING;
					END IF;
				
				WHEN z_DEBUG_RUNNING => 
					 IF i_tx_done = '1' THEN
					 	status(23 downto 16) <= X"05";
					 	status(15 downto 0) <= i_halt_address;
					 	o_tx_trig <= '1';
					 END IF;
					
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
						o_cpu_run <= '0';
						status <= X"000006"; -- status RUNNING
						fsm_state_decoder <= z_DEBUG_WAIT_TX;
						-- status <= X""; -- TODO: Status DEBUG HALT
					END IF;
				WHEN z_DEBUG_AWAIT_ADD_BP => 
					IF r_FIFO_DATA(23 downto 16) = X"05" AND b_new_data = '1' THEN  -- erwarte addresse des breakpoints
							
							o_breakpoint_value <= r_FIFO_DATA(15 downto 0);  		
							o_breakpoint_add <= '1';
							status <= X"00000a"; -- acknowledgement
							fsm_state_decoder <= z_ADDING_BP_WAIT_TX;
					END IF;

				WHEN z_DEBUG_AWAIT_DEL_BP => 
					IF r_FIFO_DATA(23 downto 16) = X"05" AND b_new_data = '1' THEN  -- erwarte addresse des breakpoints
							
							o_breakpoint_value <= r_FIFO_DATA(15 downto 0);  
							o_breakpoint_delete <= '1';
							status <= X"00000b"; -- acknowledgement
							fsm_state_decoder <= z_DELETING_BP_WAIT_TX;
					END IF;

				WHEN z_ADDING_BP_WAIT_TX => 
					o_breakpoint_add <= '0';

					IF i_bp_edit_done = '1' THEN
						fsm_state_decoder <= z_DEBUG_ADDING_BP;
					END IF;

				WHEN z_DELETING_BP_WAIT_TX => 
					o_breakpoint_delete <= '0';
					
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
				if i_tx_done = '1' then 
					o_tx_trig <= '1';
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
