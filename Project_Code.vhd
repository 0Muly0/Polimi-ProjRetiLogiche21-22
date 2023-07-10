----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Lucia Famoso
-- 
-- Create Date: 28.07.2022 21:44:00
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: ProgettoRetiLogiche 21/22
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity project_reti_logiche is
    Port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type module_state_type is (IDLING, READ_MEMO, WAIT_R_MEMO, READ_INPUT, CONVOL_COMPUTING, WRITE_MEMO, WAIT_W_MEMO, DONE);
type convol_state_type is (S0, S1, S2, S3);

signal module_current_s, module_next_s : module_state_type;
signal convol_current_s, convol_next_s :convol_state_type;

signal o_address_next : std_logic_vector(15 downto 0) := (others => '0');
signal o_done_next : std_logic := '0';
signal o_en_next : std_logic := '0';
signal o_we_next : std_logic := '0';
signal o_data_next : std_logic_vector(7 downto 0) := (others => '0');

signal tot_cycle, tot_cycle_next: integer := 0;
signal cycle_index, cycle_index_next: integer := 0;
signal i_bit_id, i_bit_id_next: integer := 7;
signal write_count, write_count_next: integer := 0;
signal memo_data, memo_data_next: std_logic_vector(7 downto 0) := (others => '0');
signal elab_out, elab_out_next: std_logic_vector(15 downto 0) := (others => '0');

begin
    
    clock_P : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- Resets MODULE state 
            module_current_s <= IDLING;
            convol_current_s <= S0; 
            
            tot_cycle <= 0;
            cycle_index <= 0;
            
            memo_data <= (others => '0');
            elab_out <= (others => '0');
            i_bit_id <= 7;
            write_count <= 0;
        
        elsif rising_edge(i_clk) then
            -- Outputs
            o_address <= o_address_next;
            o_done <= o_done_next;
            o_en <= o_en_next;
            o_we <= o_we_next;
            o_data <= o_data_next;
            
            -- States update
            module_current_s <= module_next_s;
            convol_current_s <= convol_next_s; 
            
            tot_cycle <= tot_cycle_next;
            cycle_index <= cycle_index_next;
            
            memo_data <= memo_data_next;
            elab_out <= elab_out_next;
            i_bit_id <= i_bit_id_next;
            write_count <= write_count_next;
            
        end if;
    end process;
            
    main_P : process(i_start, i_data, module_current_s, convol_current_s, i_bit_id, memo_data, elab_out, tot_cycle, cycle_index, write_count)
    begin
        -- Default values to avoid inference
        o_en_next <= '0';
        o_we_next <= '0';
        o_done_next <= '0';
        o_data_next <= (others => '0');
        o_address_next <= (others => '0');
        
        module_next_s <= module_current_s;
        convol_next_s <= convol_current_s;
       
        tot_cycle_next <= tot_cycle;
        cycle_index_next <= cycle_index;
        
        i_bit_id_next <= i_bit_id;
        memo_data_next <= memo_data;
        elab_out_next <=  elab_out;
        write_count_next <= write_count;
        
        case module_current_s is
            when IDLING =>
                if i_start = '1' then
                    module_next_s <= READ_MEMO;
                end if;
                
            when READ_MEMO =>
                if (cycle_index = 0) then
                    o_en_next <= '1';
                    o_we_next <= '0';
                
                    o_address_next <= "0000000000000000";
                    module_next_s <= WAIT_R_MEMO;
                    
                elsif (cycle_index /= 0) then
                    o_address_next <= CONV_STD_LOGIC_VECTOR( cycle_index, o_address_next'length);
                    
                    if (cycle_index /= tot_cycle + 1) then
                        o_en_next <= '1';
                        o_we_next <= '0';
                        
                        module_next_s <= WAIT_R_MEMO;
                    else
                        cycle_index_next <= 0;
                        o_done_next <= '1';
                        
                        module_next_s <= DONE;
                    end if;
                end if;
            
            when WAIT_R_MEMO => 
                module_next_s <= READ_INPUT;
                
            when READ_INPUT =>
                if (cycle_index = 0) then
                    tot_cycle_next <= conv_integer(unsigned(i_data));
                    module_next_s <= READ_MEMO;
                    cycle_index_next <= cycle_index + 1;
                else 
                     memo_data_next <= i_data;
                     i_bit_id_next <= 7;
                     module_next_s <= CONVOL_COMPUTING;   
                end if;    
            
            when CONVOL_COMPUTING =>
                case convol_current_s is
                    when S0 =>
                        if (memo_data(i_bit_id) = '0') then
                            elab_out_next(2*i_bit_id + 1) <= '0';
                            elab_out_next(2*i_bit_id) <= '0';
                            convol_next_s <= S0;
                        else
                            elab_out_next(2*i_bit_id + 1) <= '1';
                            elab_out_next(2*i_bit_id) <= '1';
                            convol_next_s <= S2;
                        end if;
                    when S1 =>
                        if (memo_data(i_bit_id) = '0') then
                            elab_out_next(2*i_bit_id + 1) <= '1';
                            elab_out_next(2*i_bit_id) <= '1';
                            convol_next_s <= S0;
                        else
                            elab_out_next(2*i_bit_id + 1) <= '0';
                            elab_out_next(2*i_bit_id) <= '0';
                            convol_next_s <= S2;
                        end if;
                    when S2 =>
                        if (memo_data(i_bit_id) = '0') then
                            elab_out_next(2*i_bit_id + 1) <= '0';
                            elab_out_next(2*i_bit_id) <= '1';
                            convol_next_s <= S1;
                        else
                            elab_out_next(2*i_bit_id + 1) <= '1';
                            elab_out_next(2*i_bit_id) <= '0';
                            convol_next_s <= S3;
                        end if;
                    when S3 =>
                        if (memo_data(i_bit_id) = '0') then
                            elab_out_next(2*i_bit_id + 1) <= '1';
                            elab_out_next(2*i_bit_id) <= '0';
                            convol_next_s <= S1;
                        else
                            elab_out_next(2*i_bit_id + 1) <= '0';
                            elab_out_next(2*i_bit_id) <= '1';
                            convol_next_s <= S3;
                        end if;
                end case;
                
                if(i_bit_id /= 0) then 
                    i_bit_id_next <= i_bit_id - 1;
                    module_next_s <= CONVOL_COMPUTING;
                else
                    i_bit_id_next <= 7;
                    module_next_s <= WRITE_MEMO;
                end if;
                
            when WRITE_MEMO =>
                o_en_next <= '1';
                o_we_next <= '1';
                
                if(write_count = 0) then
                    o_data_next <= elab_out(15 downto 8);
                    o_address_next <= CONV_STD_LOGIC_VECTOR(1000 + (cycle_index*2 - 2), o_address_next'length);
                    write_count_next <= 1;
                else
                    o_data_next <= elab_out(7 downto 0);
                    o_address_next <= CONV_STD_LOGIC_VECTOR(1000 + (cycle_index*2 - 1), o_address_next'length);
                    write_count_next <= 0;
                end if;
                
                module_next_s <= WAIT_W_MEMO;
            
            when WAIT_W_MEMO =>
            
                if(write_count = 0) then
                    module_next_s <= READ_MEMO;
                    cycle_index_next <= cycle_index + 1;
                else
                    module_next_s <= WRITE_MEMO;
                end if;
                    
            when DONE =>                
                if (i_start = '0') then
                    o_done_next <= '0';
                    convol_next_s <= S0;
                    module_next_s <= IDLING;
                else 
                    o_done_next <= '1';
                end if;
                
        end case;        
    end process;
    
    
    
end Behavioral;