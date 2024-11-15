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
        o_data   		: out std_logic_vector((c_WIDTH  * c_DEPTH ) - 1 downto 0 ) -- (3 * 8) - 1
    );
end decoder;

architecture rtl of decoder is
    signal r_FIFO_DATA : std_logic_vector((c_WIDTH * c_DEPTH ) - 1 downto 0 );
begin

	o_data <= r_FIFO_DATA; 

    p_CONTROL : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_rst_sync = '1' then
				r_FIFO_DATA <= (others => '0');
				o_flush <= '0';
            elsif i_read = '1' then
				r_FIFO_DATA <= i_rd_data_burst;
				o_flush <= '1';
			else
				o_flush <= '0';
            end if; -- sync reset
        end if; -- rising_edge(i_clk)
    end process p_CONTROL;

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
