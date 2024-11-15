-------------------------------------------------------------------------------
-- Description: Creates a Synchronous FIFO made out of registers.
--              Generic: g_WIDTH sets the width of the FIFO created.
--              Generic: g_DEPTH sets the depth of the FIFO created.
--
--              Total FIFO register usage will be width * depth
--              Note that this fifo should not be used to cross clock domains.
--              (Read and write clocks NEED TO BE the same clock domain)
--
--              FIFO Full Flag will assert as soon as last word is written.
--              FIFO Empty Flag will assert as soon as last word is read.
--
--              FIFO is 100% synthesizable.  It uses assert statements which do
--              not synthesize, but will cause your simulation to crash if you
--              are doing something you shouldn't be doing (reading from an
--              empty FIFO or writing to a full FIFO).
--
--              No Flags = No Almost Full (AF)/Almost Empty (AE) Flags
--              There is a separate module that has programmable AF/AE flags.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fifo_3_type.all;

entity fifo_3 is
    port (
        i_rst_sync : in std_logic;
        i_clk      : in std_logic;

        -- FIFO Write Interface
        i_wr_en   : in std_logic;
        i_wr_data : in std_logic_vector(c_WIDTH - 1 downto 0);
        o_full    : out std_logic;

        -- FIFO Read Interface
        i_rd_en   		: in std_logic;
        o_rd_data 		: out std_logic_vector(c_WIDTH - 1 downto 0);
        o_empty   		: out std_logic;
        o_rd_data_burst : out std_logic_vector( (c_WIDTH * c_DEPTH)- 1 downto 0 )
    );
end fifo_3;

architecture rtl of fifo_3 is

    type t_FIFO_DATA is array (0 to c_DEPTH - 1) of std_logic_vector(c_WIDTH - 1 downto 0);
    signal r_FIFO_DATA : t_FIFO_DATA := (others => (others => '0'));

    signal r_WR_INDEX : integer range 0 to c_DEPTH - 1 := 0;
    signal r_RD_INDEX : integer range 0 to c_DEPTH - 1 := 0;

    -- # Words in FIFO, has extra range to allow for assert conditions
    signal r_FIFO_COUNT : integer range -1 to c_DEPTH + 1 := 0;

    signal w_FULL : std_logic;
    signal w_EMPTY : std_logic;

begin

    p_CONTROL : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_rst_sync = '1' then
                r_FIFO_COUNT <= 0;
                r_WR_INDEX <= 0;
                r_RD_INDEX <= 0;
            else

                -- Keeps track of the total number of words in the FIFO
                if (i_wr_en = '1' and i_rd_en = '0') then
                    r_FIFO_COUNT <= r_FIFO_COUNT + 1;
                elsif (i_wr_en = '0' and i_rd_en = '1') then
                    r_FIFO_COUNT <= r_FIFO_COUNT - 1;
                end if;

                -- Keeps track of the write index (and controls roll-over)
                if (i_wr_en = '1' and w_FULL = '0') then
                    if r_WR_INDEX = c_DEPTH - 1 then
                        r_WR_INDEX <= 0;
                    else
                        r_WR_INDEX <= r_WR_INDEX + 1;
                    end if;
                end if;

                -- Keeps track of the read index (and controls roll-over)        
                if (i_rd_en = '1' and w_EMPTY = '0') then
                    if r_RD_INDEX = c_DEPTH - 1 then
                        r_RD_INDEX <= 0;
                    else
                        r_RD_INDEX <= r_RD_INDEX + 1;
                    end if;
                end if;

                -- Registers the input data when there is a write
                if i_wr_en = '1' then
                    r_FIFO_DATA(r_WR_INDEX) <= i_wr_data;
                end if;

            end if; -- sync reset
        end if; -- rising_edge(i_clk)
    end process p_CONTROL;

    o_rd_data <= r_FIFO_DATA(r_RD_INDEX);
    w_FULL <= '1' when r_FIFO_COUNT = c_DEPTH else
        '0';
    w_EMPTY <= '1' when r_FIFO_COUNT = 0 else
        '0';

    o_full 			<= w_FULL;
    o_empty 		<= w_EMPTY;

	o_rd_data_burst(23 downto 16) 	<= r_FIFO_DATA(0);
	o_rd_data_burst(15 downto 8) 	<= r_FIFO_DATA(1);
	o_rd_data_burst(7 downto 0) 	<= r_FIFO_DATA(2);

    -- ASSERTION LOGIC - Not synthesized
    -- synthesis translate_off

    p_ASSERT : process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if i_wr_en = '1' and w_FULL = '1' then
                report "ASSERT FAILURE - MODULE_REGISTER_FIFO: FIFO IS FULL AND BEING WRITTEN " severity failure;
            end if;

            if i_rd_en = '1' and w_EMPTY = '1' then
                report "ASSERT FAILURE - MODULE_REGISTER_FIFO: FIFO IS EMPTY AND BEING READ " severity failure;
            end if;
        end if;
    end process p_ASSERT;

    -- synthesis translate_on
end rtl;
