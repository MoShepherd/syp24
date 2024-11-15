-------------------------------------------------------------------------------
-- Title      : Testbench for design "svnr"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : svnr_mem_copy_tb.vhd
-- Author     : thk  <thk@thkvm>
-- Company    : 
-- Created    : 2021-12-14
-- Last update: 2022-12-19
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2021 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-12-14  1.0      thk     Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity svnr_mem_copy_tb is

end entity svnr_mem_copy_tb;

-------------------------------------------------------------------------------

architecture dut of svnr_mem_copy_tb is

  -- Clock Frequency in Hz
  constant CLKFRQ           : natural := 50_000_000;
  constant clk_half_periode : time    := 0.5 sec / CLKFRQ;

  -- component ports
  signal clk    : std_logic;
--  signal reset : std_logic;
  signal beep   : std_logic;
  signal zehner : std_logic_vector(3 downto 0);
  signal einer  : std_logic_vector(3 downto 0);
  signal ws2812_out : std_logic;
  signal led : std_logic_vector(7 downto 0);
  signal btn : std_logic_vector(4 downto 0);
  signal sw  : std_logic_vector(1 downto 0);

begin  -- architecture dut
  -- component instantiation

  DUT : entity work.top
    port map (
      clk        => clk,
      ws2812_out => ws2812_out,
      led        => led,
      btn        => btn,
      sw         => sw,
      zehner     => zehner,
      einer      => einer);

  -- clock generation
  p_clock : process
  begin
    clk <= '0'; wait for clk_half_periode;
    clk <= '1'; wait for clk_half_periode;
  end process p_clock;

end architecture dut;

