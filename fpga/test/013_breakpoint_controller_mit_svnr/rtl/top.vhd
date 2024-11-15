library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

LIBRARY work;

use work.mem_buffer.all;

entity top is
	port (
		clk 		: in std_logic;
		rxd   		: in std_logic;
		txd			: out std_logic
	);
end top;

architecture ARCH of top is
    signal r_cpu_en             : std_logic := '0';
    signal r_ram_address        : std_logic_vector(15 downto 0) := x"0000";
    signal r_ram_data_in        : std_logic_vector(15 downto 0);
    signal r_wnr                : std_logic := '1';
    signal r_addrstrb           : std_logic;
    signal s_program_counter    : std_logic_vector(15 downto 0);
    signal s_ws2812_out         : std_logic    ;
    signal s_btn                : std_logic_vector(4 downto 0) ;
    signal s_sw                 : std_logic_vector(1 downto 0) ;
    signal s_zehner             : std_logic_vector(3 downto 0);
    signal s_einer              : std_logic_vector(3 downto 0);
    signal s_cpu_step_fin       : std_logic;
    signal s_svnr_reset         : std_logic;

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
            ws2812_out      => s_ws2812_out,
            btn             => s_btn,
            sw              => s_sw,
            zehner          => s_zehner,
            einer           => s_einer,
            program_counter => s_program_counter,
            cpu_step_fin    => s_cpu_step_fin,
            reset_ext       => s_svnr_reset
        );

    BOOTLOADER : entity work.bootloader_top
        port map (
            i_Clk				=> clk,
            i_rxd				=> rxd,
            i_program_counter	=> s_program_counter,
            i_cpu_step_fin      => s_cpu_step_fin,
            o_txd				=> txd,
            o_svnr_cpu_en      	=> r_cpu_en,
            o_svnr_ram_address	=> r_ram_address(15 downto 0),
            o_svnr_ram_data_in	=> r_ram_data_in(15 downto 0),
            o_svnr_wnr			=> r_wnr,
            o_svnr_addrstrb		=> r_addrstrb,
            o_svnr_reset        => s_svnr_reset
        );
end ARCH;
