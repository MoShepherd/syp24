
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity fifo_tb is

end entity fifo_tb;

-------------------------------------------------------------------------------

architecture dut of fifo_tb is

  -- Clock Frequency in Hz
  constant CLKFRQ : natural := 50_000_000;

  constant clk_half_periode : time := 0.5 sec / CLKFRQ;
  constant clk_periode : time := 2 * clk_half_periode;
  constant c_WIDTH : integer := 8;
  constant c_DEPTh : integer := 2;
  -- component ports
  signal r_Clk : std_logic;
  signal r_Reset : std_logic;
  signal r_WR_EN : std_logic;
  signal r_WR_DATA : std_logic_vector(c_WIDTH - 1 downto 0);
  signal w_FULL : std_logic;
  signal r_RD_EN : std_logic;
  signal w_RD_DATA : std_logic_vector(c_WIDTH - 1 downto 0);
  signal w_EMPTY : std_logic;

  -- test signals

begin -- architecture dut
  -- component instantiation

  DUT : entity work.fifo_regs_no_flags
    generic map(
      g_WIDTH => c_WIDTH,
      g_DEPTH => c_DEPTh
    )
    port map(
      i_rst_sync => r_Reset,
      i_clk      => r_Clk,
      i_wr_en    => r_WR_EN,
      i_wr_data  => r_WR_DATA,
      o_full     => w_FULL,
      i_rd_en    => r_RD_EN,
      o_rd_data  => w_RD_DATA,
      o_empty    => w_EMPTY
    );

  -- clock generation
  p_clock : process
  begin
    r_Clk <= '0';
    wait for clk_half_periode;
    r_Clk <= '1';
    wait for clk_half_periode;
  end process p_clock;

  p_write_words : process is
  begin
    r_WR_DATA <= "10101010";
    r_WR_EN <= '1';
    wait for 2 * clk_periode;
    r_WR_DATA <= "00001111";
    wait for 1 * clk_periode;
    r_WR_EN <= '0';
    wait;

  end process p_write_words;
end architecture dut;