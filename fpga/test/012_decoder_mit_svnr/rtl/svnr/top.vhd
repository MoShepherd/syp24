library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library work;
use work.mem_buffer.all;

entity top is
    port (
        clk        : in  std_logic;
        ws2812_out : out std_logic;
        led        : out std_logic_vector(7 downto 0);
        btn        : in  std_logic_vector(4 downto 0);
        sw         : in  std_logic_vector(1 downto 0);
        zehner     : out std_logic_vector(3 downto 0);
        einer      : out std_logic_vector(3 downto 0)
    );
end top;

architecture ARCH of top is
    signal r_cpu_en       : std_logic := '0';
    signal r_ram_address  : std_logic_vector(15 downto 0) := x"0000";
    signal r_ram_data_in  : std_logic_vector(15 downto 0);
    signal r_wnr          : std_logic := '1';
    signal r_addrstrb     : std_logic;

    type STATE_TYPE is (state_ram_data,
                        state_ram_addrstr);

    signal state : STATE_TYPE :=state_ram_data;           


begin
    SVNR : entity work.svnr
        port map (
            clk             => clk,
            cpu_en          => r_cpu_en,
            ram_address_ext => r_ram_address,
            ram_data_in_ext => r_ram_data_in,
            wnr_ext         => r_wnr,
            addrstrb_ext    => r_addrstrb,
            ws2812_out      => ws2812_out,
            btn             => btn,
            sw              => sw,
            zehner          => zehner,
            einer           => einer
        );
-- AUTOMAT mit 2 zuständen für write to ram, da mehrere cpu zyklen benötigt werden um in den RAM zu schreiben
    process(clk)
    begin
        r_wnr <= '1';
        if rising_edge(clk) then
            case state is
                when state_ram_data =>
                    r_addrstrb <= '0';

                    -- Write data to memory until address 1024
                    if r_ram_address <= "0100000000" then
                        r_ram_data_in <= mem_buffer_image(to_integer(unsigned(r_ram_address))); -- Use ram_data_in value to write to memory
                        r_ram_address <= std_logic_vector(unsigned(r_ram_address) + 1);
                    end if;
                    state <= state_ram_addrstr;

                when state_ram_addrstr => 
                    r_addrstrb <= '1';
                    state <= state_ram_data;
            end case;
            
        end if;
    end process;

end ARCH;
