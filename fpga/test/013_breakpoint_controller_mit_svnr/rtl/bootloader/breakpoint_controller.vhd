library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Breakpoint_Controller is
    -- TODO: evtl breakout controller mit single step funktionalität erweitern?!
    Port ( 
           i_clk                   : in STD_LOGIC;
           i_program_counter       : in std_logic_vector(15 downto 0);
           i_breakpoint_add        : in STD_LOGIC;
           i_breakpoint_delete     : in STD_LOGIC;
           i_breakpoint_value      : in std_logic_vector(15 downto 0);
           i_breakpoint_enable     : in std_logic;
           i_run                   : in std_logic;
           o_cpu_en                : out STD_LOGIC := '0';
           o_cpu_halt              : out std_logic;
           o_edit_done             : out STD_LOGIC
           -- Other ports as needed
           );
end Breakpoint_Controller;

architecture Behavioral of Breakpoint_Controller is
    constant ARRAY_LENGTH : INTEGER := 15;  -- Maximum number of breakpoints!
    type BreakpointArray is array (0 to ARRAY_LENGTH) of std_logic_vector(15 downto 0);
    signal number_breakpoints : INTEGER:= 0;

    signal PC                   : std_logic_vector(15 downto 0) := (others => '0');
    signal breakpoints          : BreakpointArray := (others => (others => '1')); -- Initialize with zeros
    signal breakpoint_enable    : boolean := true;
    signal breakpoint_found     : boolean := false;
    signal edit_done            : std_logic := '0';
    signal s_empty_index        : integer;
    signal s_last_halt          : std_logic_vector(15 downto 0) := (others => '0');


    -- running/halt states
    type STATE is (
        z_RUNNING,
        z_HALT
    );

    signal fsm_state_bp_controller: STATE := z_HALT;
    
begin
    generate_cpu_en: process(i_clk)
    begin
        PC <= i_program_counter;
        
        if rising_edge(i_clk) then
            CASE fsm_state_bp_controller is
                WHEN z_RUNNING => 
                    if i_run = '1' then
                        for i in 0 to ARRAY_LENGTH loop
                            if PC = breakpoints(i) then
                                breakpoint_found <= true;
                                exit;  -- Exit the loop if a breakpoint is found
                            end if;
                        end loop;  -- End of the loop
                        
                        if breakpoint_enable and breakpoint_found then
                            -- Halt the processor when the breakpoint is reached
                            s_last_halt <= PC; 
                            o_cpu_halt <= '1';
                            o_cpu_en <= '0';
                            breakpoint_found <= false;
                            fsm_state_bp_controller <= z_HALT;
                        else
                            -- Allow normal processor operation
                            o_cpu_en <= '1';
                        end if;
                    else
                        o_cpu_en <= '0';
                    end if;
                
                WHEN z_HALT =>
                    o_cpu_halt <= '0';
                    if i_run = '1' then
                        o_cpu_en <= '1';
                        -- let cpu run until the program counter changes, then jump into bp check routine again
                        if s_last_halt /= PC then
                            fsm_state_bp_controller <= z_RUNNING; 
                        end if;
                    end if;

            END CASE;    
            
        end if;

    end process;

    edit_breakpoints: process(i_clk)
    variable empty_index : integer := 0;
    begin
        o_edit_done <= edit_done;

        if rising_edge(i_clk) then
            -- Delete breakpoint if the control signal is asserted
            edit_done <= '0';
            s_empty_index <=  empty_index;
            if i_breakpoint_delete = '1' then
                -- empty_index := -1;
                edit_done <= '1';
                for i in 0 to ARRAY_LENGTH loop
                    if breakpoints(i) = i_breakpoint_value and i_breakpoint_value /= X"FFFF" then
                        breakpoints(i) <= (others => '1');
                        number_breakpoints <=  number_breakpoints -1;
                        empty_index := i;
                        exit;
                    end if;
                end loop;
            end if;

            -- Add breakpoint if the control signal is asserted
            if i_breakpoint_add = '1' and number_breakpoints <= ARRAY_LENGTH + 1 then
                edit_done <= '0';
                if empty_index >= 0 then
                    breakpoints(empty_index) <= i_breakpoint_value;
                    number_breakpoints <= number_breakpoints + 1;
                    edit_done <= '1';
                    -- find next empty index after inserting the new bp
                    if empty_index >= 0 then
                        for i in 0 to ARRAY_LENGTH loop
                            if breakpoints(i) = X"FFFF" then
                                empty_index := i;
                                exit;
                            end if;
                        end loop;
                    end if;

                end if;
            end if;

        end if;
    end process;

end Behavioral;
