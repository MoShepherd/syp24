-------------------------------------------------------------------------------
-- SVNR auf iceduino
-- Hardware Adressen:
--
-- 0004: Input von SW1 bis SW7:
--       Bit  15  14  13  12  11  10  09  08  07  06  05  04  03  02  01  00
--            --  --  --  --  --  --  --  -- SW7 SW6 --  SW5 SW4 SW3 SW2 SW1
-- 0005: Output an 2 Hexdigit Display an PMOD1
-- 0006: Output an LEDS D1...D8
-- 0007: Output PMOD3.1 Pin 9 (P2_3) für Beep
--
-- 03C0 .. 03FF WS2812 8x8 RGB Matrix Ausgang PMOD3.1 Pin 11 (P1_3) f. Dout
--       eine 16 BIt Speicherstelle pro Pixel:
--       Bit 15..12: reserviert
--       Bit 11..8: Rot  Wert (0000 => aus, 1111 = max. Helligkeit)
--       Bit  7..4: Grün Wert (0000 => aus, 1111 = max. Helligkeit)
--       Bit  3..0: Blau Wert (0000 => aus, 1111 = max. Helligkeit)
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity svnr is
  port (
    clk         : in  std_logic;
    cpu_en      : in std_logic;
    ram_address_ext : in std_logic_vector(15 downto 0);
    ram_data_in_ext : in std_logic_vector(15 downto 0);
    wnr_ext         : in std_logic;
    addrstrb_ext    : in std_logic;
    -- PMOD 3 
    beep        : out std_logic;         -- # PMOD 3.1 P2_3 Pin 9
    ws2812_out  : out std_logic;         -- # PMOD3.0 P1_3  Pin 11
    -- Simple I/Os --
    led         : out std_logic_vector(7 downto 0);
    btn         : in  std_logic_vector(4 downto 0);
    sw          : in  std_logic_vector(1 downto 0);
    -- 2 Seg Di splay an PMOD 1
    zehner      : out std_logic_vector(3 downto 0);
    einer       : out std_logic_vector(3 downto 0)
    );  

end svnr;

architecture STRUCTURE of svnr is

  signal ALU_greater_zero                          : std_logic;
  signal ALU_operand_c_out                         : std_logic_vector (15 downto 0);
  signal Akku_q                                    : std_logic_vector (15 downto 0);
  signal BefehlsregUpperByte_Zero_dout             : std_logic_vector (15 downto 0);
  signal Befehlsregister_OPCode_q                  : std_logic_vector (7 downto 0);
  signal Befehlsregister_Operand_q                 : std_logic_vector (7 downto 0);
  signal Befehlsregister_Operand_q_16              : std_logic_vector (15 downto 0);
  signal Hilfsregister_q                           : std_logic_vector (15 downto 0);
  signal Programmzaehler_q                         : std_logic_vector (15 downto 0);
  signal Speicher_LowerByte_Dout                   : std_logic_vector (7 downto 0);
  signal Speicher_LowerByte_Dout_16                : std_logic_vector (15 downto 0);
  signal Speicher_UpperByte_n_Dout                 : std_logic_vector (7 downto 0);
  signal Steuerwerk_address_select                 : std_logic_vector (1 downto 0);
  signal Steuerwerk_akku_data_in_select            : std_logic_vector (1 downto 0);
  signal Steuerwerk_alu_operand_b_select           : std_logic;
  signal Steuerwerk_load_akku                      : std_logic;
  signal Steuerwerk_load_hilfsregister             : std_logic;
  signal Steuerwerk_load_programmzaehler           : std_logic;
  signal Steuerwerk_programmzaehler_data_in_select : std_logic_vector (1 downto 0);
  signal Steuerwerk_speicher_data_in_select        : std_logic_vector (1 downto 0);
  signal Steuerwerk_strobe                         : std_logic;
  signal Steuerwerk_wr                             : std_logic;
  signal alu_n_0_equal_zero                        : std_logic;
  signal alu_n_0_less_zero                         : std_logic;
  signal bus_tri_0_output                          : std_logic_vector (15 downto 0);
  signal Programmzaehler_inc                       : std_logic_vector (15 downto 0);
  signal mux_2_n_0_result                          : std_logic_vector (15 downto 0);
  signal mux_4_n_0_result                          : std_logic_vector (15 downto 0);
  signal mux_4_n_1_result                          : std_logic_vector (15 downto 0);
  signal address_multiplexer_out                   : std_logic_vector (15 downto 0);
  signal programmzaehler_mux_out                   : std_logic_vector (15 downto 0);
  signal steuerautomat_0_calculate                 : std_logic;
  signal steuerautomat_0_clear_register            : std_logic;
  signal steuerautomat_0_load_befehlsregister      : std_logic;
  signal stim_0_reset                              : std_logic;
  signal stim_n_0_clk_t                            : std_logic;
  signal mem_init_running                          : std_logic;  -- Vom speicher
  signal anzeige_2_hexdigits                       : std_logic_vector(7 downto 0);  -- Vom speicher
  signal clk_to_mem                                : std_logic;
  signal r_clk_out                                 : std_logic;
  signal r_ext_ram_mux_out                         : std_logic_vector(33 downto 0) := "0000000000000000000000000000000000";
                                        -- zum Reset
  signal reset_mem                                 : std_logic;  -- extra reset
  -- für speicher

begin
  Akku : entity work.register_en
    generic map (
      size        => 16,
      clear_value => 0)
    port map (
      clock_t => stim_n_0_clk_t,
      clr     => steuerautomat_0_clear_register,
      load    => Steuerwerk_load_akku,
      data    => mux_4_n_0_result(15 downto 0),
      q       => Akku_q);

  Befehlsregister_OPCode : entity work.register_en
    generic map (
      size        => 8,
      clear_value => 0
      )
    port map (
      clock_t          => stim_n_0_clk_t,
      load             => steuerautomat_0_load_befehlsregister,
      clr              => steuerautomat_0_clear_register,
      data => Speicher_UpperByte_n_Dout(7 downto 0),
      q(7 downto 0)    => Befehlsregister_OPCode_q(7 downto 0)
      );

  Befehlsregister_Operand_n : entity work.register_en
    generic map (
      size        => 8,
      clear_value => 0
      )
    port map (
      clock_t          => stim_n_0_clk_t,
      load             => steuerautomat_0_load_befehlsregister,
      clr              => steuerautomat_0_clear_register,
      data => Speicher_LowerByte_Dout(7 downto 0),
      q(7 downto 0)    => Befehlsregister_Operand_q(7 downto 0)
      );
  Befehlsregister_Operand_q_16 <= "00000000" & Befehlsregister_Operand_q;

  Hilfsregister_n : entity work.register_en
    generic map (
      size        => 16,
      clear_value => 0
      )
    port map (
      clock_t           => stim_n_0_clk_t,
      load              => Steuerwerk_load_hilfsregister,
      clr               => steuerautomat_0_clear_register,
      data => bus_tri_0_output(15 downto 0),
      q(15 downto 0)    => Hilfsregister_q(15 downto 0)
      );

  -----------------------------------
  -- Programmzähler
  Programmzaehler : entity work.register_en
    generic map (
      size        => 16,
      clear_value => 0
      )
    port map (
      clock_t           => stim_n_0_clk_t,
      load              => Steuerwerk_load_programmzaehler,
      clr               => steuerautomat_0_clear_register,
      data => programmzaehler_mux_out(15 downto 0),
      q(15 downto 0)    => Programmzaehler_q(15 downto 0)
      );

  increment_n_0 : entity work.increment_n
    generic map (
      SIZE => 16
      )
    port map (
      inp  => Programmzaehler_q(15 downto 0),
      outp(15 downto 0) => Programmzaehler_inc(15 downto 0)  -- Programmzaehler_inc
      );

  -----------------------------------
  -- ALU
  alu_n_0 : entity work.alu_n
    port map (
      clock_t                    => stim_n_0_clk_t,
      cal                        => steuerautomat_0_calculate,
      equal_zero                 => alu_n_0_equal_zero,
      greater_zero               => ALU_greater_zero,
      less_zero                  => alu_n_0_less_zero,
      opcode(7 downto 0)         => Befehlsregister_OPCode_q(7 downto 0),
      operand_a_in(15 downto 0)  => Akku_q(15 downto 0),
      operand_b_in(15 downto 0)  => mux_2_n_0_result(15 downto 0),
      operand_c_out(15 downto 0) => ALU_operand_c_out(15 downto 0),
      reset_init                 => steuerautomat_0_clear_register
      );


  -----------------------------------
  -- Multiplexer

  Speicher_LowerByte_Dout(7 downto 0)        <= bus_tri_0_output(7 downto 0);
  Speicher_LowerByte_Dout_16                 <= "00000000" & Speicher_LowerByte_Dout;
  Speicher_UpperByte_n_Dout(7 downto 0)      <= bus_tri_0_output(15 downto 8);
  BefehlsregUpperByte_Zero_dout(15 downto 0) <= "00000000" & Befehlsregister_Operand_q(7 downto 0);

  mux_2_n_0 : entity work.mux_2_n
    generic map (
      size => 16
      )
    port map (
      data0  => bus_tri_0_output(15 downto 0),
      data1  => BefehlsregUpperByte_Zero_dout(15 downto 0),
      result(15 downto 0) => mux_2_n_0_result(15 downto 0),
      sel                 => Steuerwerk_alu_operand_b_select
      );
  mux_4_n_0 : entity work.mux_4_n
    generic map (
      size => 16
      )
    port map (
      data0  => BefehlsregUpperByte_Zero_dout(15 downto 0),
      data1  => bus_tri_0_output(15 downto 0),
      data2  => ALU_operand_c_out(15 downto 0),
      data3  => Hilfsregister_q(15 downto 0),
      result(15 downto 0) => mux_4_n_0_result(15 downto 0),
      sel(1 downto 0)     => Steuerwerk_akku_data_in_select(1 downto 0)
      );
  mux_4_n_1 : entity work.mux_4_n
    generic map (
      size => 16
      )
    port map (
      data0  => BefehlsregUpperByte_Zero_dout(15 downto 0),
      data1  => Akku_q(15 downto 0),
      data2  => ALU_operand_c_out(15 downto 0),
      data3  => Hilfsregister_q(15 downto 0),
      result(15 downto 0) => mux_4_n_1_result(15 downto 0),
      sel(1 downto 0)     => Steuerwerk_speicher_data_in_select(1 downto 0)
      );

  address_mux : entity work.mux_4_n
    generic map (
      size => 16
      )
    port map (
      data0  => Befehlsregister_Operand_q_16,  -- ist 8 Bit
      data1  => Programmzaehler_q(15 downto 0),
      data2  => Hilfsregister_q(15 downto 0),
      data3  => "0000000000000000",
      result(15 downto 0) => address_multiplexer_out(15 downto 0),  -- address_multiplexer_out
      sel(1 downto 0)     => Steuerwerk_address_select(1 downto 0)
      );
  programmzaehler_mux : entity work.mux_4_n
    generic map (
      size => 16
      )
    port map (
      data0  => Programmzaehler_inc(15 downto 0),
      data1  => Befehlsregister_Operand_q_16,
      data2  => bus_tri_0_output,  -- Speicher_LowerByte_Dout_16,
      data3  => "0000000000000000",
      result(15 downto 0) => programmzaehler_mux_out(15 downto 0),  -- programmzaehler_mux_out
      sel(1 downto 0)     => Steuerwerk_programmzaehler_data_in_select(1 downto 0)
      );


  --- Mux ram_address, ram_data_in, addrstrb and wnr form external, when cpu is stopped. This allows to feed in external ram.
  ext_ram_mux : entity work.mux_2_n
    generic map(
      size => 34
    )
    port map(
      data0(0) => addrstrb_ext,
      data0(1) => wnr_ext,
      data0(17 downto 2) => ram_address_ext(15 downto 0),
      data0(33 downto 18) => ram_data_in_ext(15 downto 0),
      data1(0) => Steuerwerk_strobe,
      data1(1) => Steuerwerk_wr,
      data1(17 downto 2) => address_multiplexer_out(15 downto 0),
      data1(33 downto 18) => mux_4_n_1_result(15 downto 0),
      result(0) => r_ext_ram_mux_out(0),
      result(1) => r_ext_ram_mux_out(1),
      result(17 downto 2) => r_ext_ram_mux_out(17 downto 2),
      result(33 downto 18) => r_ext_ram_mux_out(33 downto 18),
      sel => cpu_en
    );

  svnr_mem_1 : entity work.svnr_mem
    port map (
      clk                      => clk_to_mem,
      addrstrb                 => r_ext_ram_mux_out(0),
      ram_address(15 downto 0) => r_ext_ram_mux_out(17 downto 2),  -- 
      ram_data_in              => r_ext_ram_mux_out(33 downto 18),
      ram_data_out             => bus_tri_0_output,
      reset_init               => stim_0_reset,
      beep                     => beep,
      ws2812_out               => ws2812_out,
      led                      => led,
      btn                      => btn,
      sw                       => sw,
      PMOD1                    => anzeige_2_hexdigits,
      wnr                      => r_ext_ram_mux_out(1),
      reset_mem                => reset_mem,
      mem_init_running         => mem_init_running
      );


  zehner <= anzeige_2_hexdigits(7 downto 4);
  einer  <= anzeige_2_hexdigits(3 downto 0);

  steuerautomat_n_0 : entity work.steuerautomat_n
    port map (
      reset_init                                 => stim_0_reset,
      clk_t                                      => stim_n_0_clk_t,
      opcode(7 downto 0)                         => Befehlsregister_OPCode_q(7 downto 0),
      greater_zero                               => ALU_greater_zero,
      equal_zero                                 => alu_n_0_equal_zero,
      less_zero                                  => alu_n_0_less_zero,
      clear_register                             => steuerautomat_0_clear_register,
      strobe                                     => Steuerwerk_strobe,
      wr                                         => Steuerwerk_wr,
      address_select(1 downto 0)                 => Steuerwerk_address_select(1 downto 0),
      speicher_data_in_select(1 downto 0)        => Steuerwerk_speicher_data_in_select(1 downto 0),
      akku_data_in_select(1 downto 0)            => Steuerwerk_akku_data_in_select(1 downto 0),
      load_akku                                  => Steuerwerk_load_akku,
      load_befehlsregister                       => steuerautomat_0_load_befehlsregister,
      load_programmzaehler                       => Steuerwerk_load_programmzaehler,
      programmzaehler_data_in_select(1 downto 0) => Steuerwerk_programmzaehler_data_in_select(1 downto 0),
      load_hilfsregister                         => Steuerwerk_load_hilfsregister,
      alu_operand_b_select                       => Steuerwerk_alu_operand_b_select,
      calculate                                  => steuerautomat_0_calculate
      );


  clkreset_1 : entity work.clkreset
    port map (
      clk_input_pin    => clk,
      mem_init_running => mem_init_running,
      clk_t            => r_clk_out,
      reset_init       => stim_0_reset,
      reset_mem        => reset_mem);


  process(clk)
  begin
    clk_to_mem <= r_clk_out;
    if (rising_edge(clk)) then
      if cpu_en = '1' then
        stim_n_0_clk_t <= r_clk_out;
      end if;
      if cpu_en = '0' then
        stim_n_0_clk_t <= '0';
        
      end if;
    end if;

  end process;  
end STRUCTURE;
