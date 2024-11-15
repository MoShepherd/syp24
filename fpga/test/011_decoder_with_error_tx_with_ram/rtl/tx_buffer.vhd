library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tx_buffer is
    Port ( clk              : in  STD_LOGIC;      -- Clock input
           wen              : in  STD_LOGIC;      -- Write enable
           data_in          : in  STD_LOGIC_VECTOR (23 downto 0); -- Input data
           data_out         : out STD_LOGIC_VECTOR (23 downto 0);  -- Output data
           o_rdy_to_fetch   : out std_logic
        );
end tx_buffer;

architecture Behavioral of tx_buffer is
    signal tx_buffer_reg : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');  -- Internal tx_buffer register
	signal w_rdy_to_fetch 	: std_logic := '0';
begin


    process(clk)
    begin

        o_rdy_to_fetch <=  w_rdy_to_fetch;

        if rising_edge(clk) then
            if wen = '1' then
                tx_buffer_reg <= data_in;  -- Update tx_buffer only when write enable is active
                w_rdy_to_fetch <= '1';
            else
                w_rdy_to_fetch <= '0';
            end if;
        end if;
    end process;
    data_out <= tx_buffer_reg;
      -- Output the tx_buffered data

end Behavioral;
