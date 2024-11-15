library ieee;
use ieee.std_logic_1164.all;

entity single_step is
    port (
        i_run            : in  std_logic;
        i_cpu_step_fin   : in  std_logic;
        o_cpu_en         : out std_logic
    );
end entity single_step;

architecture Behavioral of single_step is
    type State is (IDLE, RUNNING, WAIT_FOR_FINISH);
    signal state_machine : State := IDLE;
    signal internal_cpu_en : std_logic := '0';
begin
    process(i_run, i_cpu_step_fin)
    begin
        case state_machine is
            when IDLE =>
                if i_run = '1' then
                    -- Start single-step mode
                    internal_cpu_en <= '1';
                    state_machine <= RUNNING;
                end if;
                
            when RUNNING =>
                -- Continue running until i_cpu_step_fin is asserted
                if i_cpu_step_fin = '1' then
                    state_machine <= WAIT_FOR_FINISH;
                end if;
                
            when WAIT_FOR_FINISH =>
                -- Wait for i_cpu_step_fin to go low
                if i_cpu_step_fin = '0' then
                    internal_cpu_en <= '0';
                    state_machine <= IDLE;
                end if;
        end case;
    end process;

    -- Output the internal_cpu_en signal
    o_cpu_en <= internal_cpu_en;

end architecture Behavioral;
