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

        -- output Interface
        o_flush 		: out std_logic;
        o_data   		: out std_logic_vector((c_WIDTH  * c_DEPTH ) - 1 downto 0 ); -- (3 * 8) - 1
		o_status		: out std_logic_vector(23 downto 0); -- status paket, welches von UART_tx abgegriffen und bei statusabfrage versendet wird.
		-- output RAM Interface
		o_ram_addr		: out std_logic_vector(9 downto 0);
		o_ram_data		: out std_logic_vector(15 downto 0);
		o_ram_wen		: out std_logic;
		--o_ram_clk		: out std_logic_vector(); ist i_clk
		-- output Runner Interface
		o_ram_data_valid: out std_logic
	);
end decoder;

architecture rtl of decoder is
	 --CONSTANT c_RAM_SIZE : NATURAL := 4;
	 CONSTANT c_RAM_SIZE : NATURAL := 1024;
    signal r_FIFO_DATA : std_logic_vector((c_WIDTH * c_DEPTH ) - 1 downto 0 );


	-- ist diese statemachine nur f�r RAM upload zust�nde? Oder kann auch der bspw status zustand mit rein? 
	type STATE is (
		 z_POWER_ON			-- initialisierungs zustand
		,z_UPLOAD_TO_RAM 	-- wenn der befehl upload to ram gesendet wurde "0x01 00 02"
		,z_WRITE_TO_RAM 	-- der zustand wo write enable wieder auf 0 gelegt wird und der counter hochgerechnet wird
		,z_RAM_FULL 		-- zustand wenn der zähler den max wert erreicht hat
		,z_RAM_NOT_FULL 	-- wenn eine status abfrage ausgeführt wird, bevor der ram voll ist
		,z_RAM_OVERFLOW  	-- wenn keine status abfrage durchgeführt wurde, nachdem der ram voll war und noch ein 0x02 XX XX reingekommen ist
		,z_RAM_FULL_OK   	-- wenn eine status abfrage richtig kam und damit bestätigt wurde, dass jetzt der ram vom svnr gefüllt werden kann.
	);
  	signal fsm_state 		: STATE := z_POWER_ON;
	signal ram_cnt 			: NATURAL := 0;
	--signal ram_cnt 			: NATURAL RANGE 0 TO c_RAM_SIZE - 1 := 0;
	signal ram_output_data 	: std_logic_vector(15 downto 0);
	signal data_address 	: std_logic_vector (9 downto 0); -- adresse für 1024 bit
	signal write_enable		: std_logic := '0';
	signal b_full			: std_logic := '0'; -- if cnt is at max value
	signal status			: std_logic_vector(23 downto 0) := X"111111"; -- startet auf status?
	signal b_new_data		: std_logic := '0'; -- damit man einen clock auf i_read wartet. Der wert von r_FIFO_DATA ist erst ein clock danach abgreifbar
	signal w_done			: std_logic := '0';


begin
	o_data 			<= r_FIFO_DATA; 
	o_ram_data_valid<= w_done;

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
		--if i_read = '1' THEN hässlig
			CASE fsm_state is
				WHEN z_POWER_ON	=> 		-- initialisierungs zustand
					IF r_FIFO_DATA = X"010002" AND b_new_data = '1' THEN  -- Jump into RAM upload mode
						-- init cnt
						status <= X"000000";
						fsm_state <= z_UPLOAD_TO_RAM;
						ram_cnt <= 0;
					ELSIF r_FIFO_DATA(23 downto 16) = X"02" AND b_new_data = '1' THEN  -- man muss immer nachgucken ob auch gerade gelesen wird
						-- init cnt
						status <= X"030013"; -- Error, no RAM transmission started yet!/Command not 
						fsm_state <= z_POWER_ON;
						ram_cnt <= 0;
					ELSIF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN
						-- on status query, current state has to hold its last state.
					ELSIF b_new_data = '1' THEN
						status <= X"030014"; -- no valid packet ERROR
					ELSIF w_done = '1' THEN
						w_done <= '0';
					END IF; 
				WHEN z_UPLOAD_TO_RAM => -- wenn der befehl upload to ram gesendet wurde "0x01 00 02"
					--IF r_FIFO_DATA(r_FIFO_DATA'length - 1 downto r_FIFO_DATA'length - 8) = X"02" THEN 
					--IF r_FIFO_DATA(23 downto 16) = X"02" AND i_read = '1' THEN 
					
					-- status abfrage zu früh
					IF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN
						fsm_state <= z_RAM_NOT_FULL;
						status <= X"030011";
					-- nächstes ram inhalt
					ELSIF r_FIFO_DATA(23 downto 16) = X"02" AND b_new_data = '1' THEN
						IF ram_cnt = c_RAM_SIZE - 1 THEN 
							b_full <= '1';
						ELSE 
							b_full <= '0';
							status <= X"000000"; -- acknowledgement
						END IF;

						write_enable <= '1';
						ram_output_data <= r_FIFO_DATA(15 downto 0);
						fsm_state <= z_WRITE_TO_RAM;
					-- ELSIF b_new_data = '1' THEN
					-- 	status <= X"030014"; -- illegal packet received!
					-- 	fsm_state <=  z_POWER_ON;
					END IF;	

				WHEN z_WRITE_TO_RAM => -- zwischen schritt um write enable auf 0 zu setzten und cnt hoch zuzählen
					write_enable <= '0'; -- damit der nicht die ganze zeit darauf geschrieben wird 
					-- status <= X"030010"; -- Error BUSY
					-- status <= X"000000";
					IF b_full = '1' THEN  -- wenn es die letzte stelle war
						fsm_state <= z_RAM_FULL;
					ELSE
						ram_cnt 	<= ram_cnt + 1;
						fsm_state 	<= z_UPLOAD_TO_RAM;
						
					END IF;
				WHEN z_RAM_FULL =>		-- zustand wenn der zähler den max wert erreicht hat
					-- wait on next sig
					IF r_FIFO_DATA(23 downto 16) = X"02" AND b_new_data = '1' THEN  -- zuviele daten
						ram_cnt		<= 0; -- setzte den ram adresse zurück ram inhalt wird nicht geleert aber auch nicht abgefangen
						status <=  X"030012"; -- ERROR RAM overflow
						fsm_state 	<= z_RAM_OVERFLOW;

					END IF;	
					IF r_FIFO_DATA = X"010005" AND b_new_data = '1' THEN  -- status abfrage zu früh
						ram_cnt		<= 0; -- setzte den ram adresse zurück ram inhalt wird nicht geleert aber auch nicht abgefangen
						fsm_state 	<= z_RAM_FULL_OK;

					END IF;	
				WHEN z_RAM_NOT_FULL =>	-- wenn eine status abfrage ausgeführt wird, bevor der ram voll ist
					--return error stuff
					ram_cnt		<= 0; -- setzte den ram adresse zurück ram inhalt wird nicht geleert aber auch nicht abgefangen
					fsm_state 	<= z_POWER_ON;

					 -- ERROR TRANSMITION INCOMPLETE
				WHEN z_RAM_OVERFLOW => 	-- wenn keine status abfrage durchgeführt wurde, nachdem der ram voll war und noch ein 0x02 XX XX reingekommen ist
					ram_cnt		<= 0; -- setzte den ram adresse zurück ram inhalt wird nicht geleert aber auch nicht abgefangen
					fsm_state 	<= z_POWER_ON;
					 -- ERROR ram overflow

				WHEN z_RAM_FULL_OK =>  	-- wenn eine status abfrage richtig kam und damit bestätigt wurde, dass jetzt der ram vom svnr gefüllt werden kann.
					-- set signal to fill svnr ram from buffer
					fsm_state 	<= z_POWER_ON;
					status <=  X"000000"; -- evtl packettype f�r status einf�hren?? hier erstmal nur acknowledge zur�cksenden!
					w_done <= '1';

				WHEN OTHERS =>
					fsm_state <= z_POWER_ON;
			END CASE;
		-- END IF;
	END IF;
	END PROCESS;

	o_ram_addr 	<= std_logic_vector(to_unsigned(ram_cnt,o_ram_addr'length));
	o_ram_data 	<= ram_output_data;
	o_ram_wen 	<= write_enable;

    -- ASSERTION LOGIC - Not synthesized
    -- synthesis translate_off
--     p_ASSERT : process (i_clk) is
--     begin
--         if rising_edge(i_clk) then
--             if i_wr_en = '1' and w_FULL = '1' then
--                 report "ASSERT FAILURE - MODULE_REGISTER_FIFO: FIFO IS FULL AND BEING WRITTEN " severity failure;
--             end if;
-- 
--             if i_rd_en = '1' and w_EMPTY = '1' then
--                 report "ASSERT FAILURE - MODULE_REGISTER_FIFO: FIFO IS EMPTY AND BEING READ " severity failure;
--             end if;
--         end if;
--     end process p_ASSERT;
    -- synthesis translate_on
end rtl;
