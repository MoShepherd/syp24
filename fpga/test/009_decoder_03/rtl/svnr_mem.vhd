
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.svnr_memory_image.all;

entity svnr_mem is
  port (
    clk              : in  std_logic;
    wnr              : in  std_logic;
    reset_init       : in  std_logic;   -- langer reset
    ram_address      : in  std_logic_vector(15 downto 0);
    addrstrb         : in  std_logic;
    beep             : out std_logic;
    ws2812_out       : out std_logic;
    led              : out std_logic_vector(7 downto 0);
    btn              : in  std_logic_vector(4 downto 0);
    sw               : in  std_logic_vector(1 downto 0);
    PMOD1            : out std_logic_vector(7 downto 0);
    ram_data_in      : in  std_logic_vector(15 downto 0);
    ram_data_out     : out std_logic_vector(15 downto 0);
    reset_mem        : in  std_logic;   -- SPeicher reset 
    mem_init_running : out std_logic    -- Solange der Speicher gefüllt wird 
    );
end svnr_mem;

architecture behv of svnr_mem is
  constant maxbytes : integer := 1024;

  type mem_type_xs is array (0 to maxbytes-1) of std_logic_vector(15 downto 0);

  -- signals for display
  signal reset_n    : std_logic;
  signal ws2812_sul : std_ulogic;

  signal disp_address       : std_logic_vector(5 downto 0);
  signal disp_data_to_ram   : std_logic_vector(15 downto 0);
  signal disp_data_from_ram : std_logic_vector(15 downto 0);
  signal disp_writestrobe   : std_logic;
  signal inputs             : std_logic_vector(15 downto 0);
  signal inputs_sync        : std_logic_vector(15 downto 0);
  signal inputs_sync2       : std_logic_vector(15 downto 0);
  signal led_data           : std_logic_vector (7 downto 0);

  --
  signal mem_sig   : mem_type_xs;
  signal rdata     : std_logic_vector(15 downto 0);
  signal debugdata : std_logic_vector(15 downto 0);
  signal beepdata  : std_logic_vector(15 downto 0);


  signal bram_address : std_logic_vector(10 downto 0);
  signal wen          : std_logic;


  signal init_address : std_logic_vector(9 downto 0);
  signal init_running : std_logic;

  signal muxed_address : std_logic_vector(9 downto 0);
  signal muxed_data_in : std_logic_vector(15 downto 0);
  signal muxed_wen     : std_logic;

begin



  fsm_init_p : process (clk) is
  begin  -- process fsm_init_p
    if rising_edge(clk) then              -- rising clock edge
      if reset_mem = '1' then             -- synchronous reset (active high)
        init_running <= '1';
        init_address <= (others => '0');  --"00000000";
      elsif init_address /= "1111111111" then
        init_running <= '1';
        init_address <= std_logic_vector(to_unsigned(to_integer(unsigned(init_address)) + 1, 10));
      else
        init_running <= '0';
        init_address <= (others => '1'); --- "1111111111";
      end if;
    end if;
  end process fsm_init_p;

  -- Init running report to reset module
  mem_init_running <= init_running;

  -- Multiplex init/normal run
  muxed_address <= init_address                                       when init_running = '1' else ram_address(9 downto 0);
  muxed_data_in <= mem_init_image(to_integer(unsigned(init_address))) when init_running = '1' else ram_data_in;
  muxed_wen     <= '1'                                                when init_running = '1' else wen;

  wen <= '1' when addrstrb = '1' and wnr = '1' else '0';

  ----------------------------------
  -- Prozess erzeugt BLOCK4K 

  blockmem_infer_p : process(clk)
  begin
    if rising_edge(clk) then
      if muxed_wen = '1' then
        mem_sig(to_integer(unsigned(muxed_address))) <= muxed_data_in;
      end if;
      rdata <= mem_sig(to_integer(unsigned(muxed_address)));
    end if;
  end process blockmem_infer_p;

  ram_data_out <= inputs_sync when (to_integer(unsigned(muxed_address)) = 4) else rdata;


  --------------------------
  -- Speicher für Output Signale
  beep_p : process(clk)
  begin
    if rising_edge(clk) then
      if 7 = to_integer(unsigned(muxed_address)) and muxed_wen = '1' then
        beep <= muxed_data_in(0);
      end if;
      if 6 = to_integer(unsigned(muxed_address)) and muxed_wen = '1' then
        led_data <= muxed_data_in(7 downto 0);
      end if;
      if 5 = to_integer(unsigned(muxed_address)) and muxed_wen = '1' then
        debugdata <= muxed_data_in;
      end if;
    end if;
  end process beep_p;

  PMOD1 <= debugdata(7 downto 0);
  led   <= led_data;

  ----
  -- Inputs einsynchronisieren
  inputs <= "00000000" & sw & '0' & not btn(4) & not btn(3) & not btn(2) & not btn(1) & not btn(0);
  syncinputs_p : process(clk)
  begin
    if rising_edge(clk) then
      inputs_sync2 <= inputs;
      inputs_sync  <= inputs_sync2;
    end if;
  end process syncinputs_p;


  -----
  reset_n          <= not reset_mem;
  ws2812_out       <= std_logic(ws2812_sul);
  disp_address     <= muxed_address(5 downto 0);
  disp_data_to_ram <= muxed_data_in;
  disp_writestrobe <= '1' when (muxed_address(9 downto 6) = "1111" and muxed_wen = '1') else '0';

  display_top_1 : entity work.display_top
    port map (
      reset         => reset_n,
      clk           => clk,
      address       => disp_address,
      data_to_ram   => disp_data_to_ram,
      data_from_ram => disp_data_from_ram,
      writestrobe   => disp_writestrobe,
      ws2812_out    => ws2812_sul);

end behv;
