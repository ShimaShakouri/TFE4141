--------------------------------------------------------------------------------
-- Authors      : Erfan Abdoliniafard - Shima Shakouri - Zahra Jenab Mahabadi
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2021-2022
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose:
--    This module performs modular exponentiation usuing montgomery multiplication algorithm.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity exponentiation is
  generic (
    C_BLOCK_SIZE : integer := 256
  );
  port (
    --input controll
    valid        : in STD_LOGIC;
    ready        : out STD_LOGIC;

    --input data
    message      : in STD_LOGIC_VECTOR ( C_BLOCK_SIZE-1 downto 0 );
    key          : in STD_LOGIC_VECTOR ( C_BLOCK_SIZE-1 downto 0 );
    r_mod        : in std_logic_vector (C_BLOCK_SIZE -1 downto 0);
    r_2_mod      : in std_logic_vector (C_BLOCK_SIZE -1 downto 0);

    --output data
    result      : out STD_LOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);

    --modulus
    modulus     : in STD_LOGIC_VECTOR(C_BLOCK_SIZE-1 downto 0);

    --utility
    clk         : in STD_LOGIC;
    reset_n     : in STD_LOGIC
  );
end exponentiation;


architecture expBehave of exponentiation is

    type state is (IDLE, INIT, CALCULATE_1, CALCULATE_2, FINAL, FINISHED);
    signal current_state, next_state : state;
        
    signal mont_start  : std_logic;
    signal mont_a      : std_logic_vector(C_BLOCK_SIZE -1 downto 0);
    signal mont_b      : std_logic_vector(C_BLOCK_SIZE -1 downto 0);
    signal mont_n      : std_logic_vector(C_BLOCK_SIZE -1 downto 0);
    signal mont_done   : std_logic;
    signal mont_s      : std_logic_vector(C_BLOCK_SIZE -1 downto 0);   
    signal x_h, x_temp : std_logic_vector(C_BLOCK_SIZE -1 downto 0); 
    signal M_h, M_temp : std_logic_vector(C_BLOCK_SIZE -1 downto 0);  
    signal M_en        : std_logic;
    signal x_en        : std_logic;
    signal counter     : integer range 0 to (C_BLOCK_SIZE-1);
    signal enable_c    : std_logic;
    signal reset_c     : std_logic;
 -- *****************************************************************************
 -- Instantiation and Port mapping montgomery multiplication module
 -- *****************************************************************************  
component Mont
Generic(C_BLOCK_SIZE : integer := 4
  );
  Port( A          : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        B          : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        N          : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
        enable     : in std_logic;
        clk        : in std_logic;
        reset      : in std_logic;
        data_ready : out std_logic;
        S          : out std_logic_vector(C_BLOCK_SIZE-1 downto 0));
      
end component;      
begin
  Mont_multiplier: Mont
  generic map(C_BLOCK_SIZE => C_BLOCK_SIZE)
  port map(
    A          => mont_a, 
    B          => mont_b, 
    N          => mont_n,
    enable     => mont_start, 
    clk        => clk, 
    reset      => reset_n,
    data_ready => mont_done, 
    S          => mont_s 
    );    
 -- *****************************************************************************
 -- Counter Process (to be able to perform for loop)
 -- *****************************************************************************    
     counter_proc : process (clk, reset_n, enable_c, reset_c) is
         begin
             if rising_edge(clk) then
                if reset_n = '0' then
                    counter <= C_BLOCK_SIZE-1;
                elsif reset_c = '1' then
                    counter <= C_BLOCK_SIZE-1;
                    elsif enable_c = '1' then
                        counter <= counter - 1;
                 end if;
              end if;
     end process counter_proc;                 
 -- *****************************************************************************
 -- Process for passing M temp value to M_h
 -- *****************************************************************************              
     m_proc: process(clk, reset_n)
     begin
         if reset_n = '0' then
             M_h <= (others => '0');
         elsif rising_edge(clk) then
             if M_en = '1' then
                 M_h <= M_temp;
             end if;
         end if;
     end process;   
 -- *****************************************************************************
 -- Process for passing x temp value to x_h
 -- *****************************************************************************      
     x_proc: process(clk, reset_n)
     begin
         if reset_n = '0' then
             x_h <= (others => '0');
         elsif rising_edge(clk) then
             if x_en = '1' then
                 x_h <= x_temp;
             end if;
         end if;
     end process;     
     
  --***********FSM**************
  -- ***************************
  -- Sequential
  -- ***************************
    Sequential : process (reset_n, clk)
    begin
        if (reset_n = '0') then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
  -- ***************************
  -- Combinatial
  -- ***************************         
    Combinatial : process (current_state, valid, mont_done, message, modulus, key, r_mod, r_2_mod, M_h, x_h, mont_s, counter)
    begin

        mont_a <= (others => '0');
        mont_b <= (others => '0');
        mont_n <= (others => '0');
        result <= (others => '0');
        x_temp <= (others => '0');
        M_temp <= (others => '0');
        enable_c <= '0';
        x_en <= '0';
        M_en <= '0';
        mont_start <= '0';
        ready <= '0';
        reset_c <= '0';
        
        
        case (current_state) is
        
        when IDLE => 
            reset_c <= '1';
            if valid = '1' then
                x_en <= '1';
                x_temp <= r_mod;
                mont_a <= message;
                mont_b <= r_2_mod;
                mont_n <= modulus;
                mont_start <= '1';
                next_state <= INIT;
            else
                next_state <= IDLE;
            end if;
        
        when INIT => -- This state perfroms step 2 and 3 of the pseudo code
            x_temp <= r_mod;
            mont_a <= message;
            mont_b <= r_2_mod;
            mont_n <= modulus;
            if mont_done = '1' then
                M_en <= '1';
                M_temp <= mont_s;
                mont_a <= x_h;
                mont_b <= x_h;
                mont_start <= '1';
                next_state <= CALCULATE_1;
            else
                next_state <= INIT;
            end if;
        
        when CALCULATE_1 => -- This state perfroms step 4 and 5 of the pseudo code (for loop)
            mont_a <= x_h;
            mont_b <= x_h;
            mont_n <= modulus;
            if mont_done = '1' then 
                    x_en <= '1';            
                    x_temp <= mont_s;
                    
                if (key(counter) = '1') then
                    mont_a <= M_h;
                    mont_b <= mont_s;
                    mont_n <= modulus;
                    mont_start <= '1';
                    next_state <= CALCULATE_2;         
                elsif counter = 0 then
                    mont_a <= mont_s;             
                    mont_b <= (C_BLOCK_SIZE-1 downto 1 => '0') & '1';          
                    mont_n <= modulus;               
                    mont_start <= '1';         
                    next_state <= FINAL;     
                else 
                    mont_a <= mont_s;
                    mont_b <= mont_s;
                    mont_n <= modulus;
                    mont_start <= '1';
                    enable_c <=  '1';
                    next_state <= CALCULATE_1;
                end if;
            else
                next_state <= CALCULATE_1;
            end if;
        
        when CALCULATE_2 => -- This state perfroms step 6 of the pseudo code (If statement) 
            mont_a <= M_h;
            mont_b <= x_h;
            mont_n <= modulus;
            if mont_done = '1' then
                x_en <= '1';
                x_temp <= mont_s;
                mont_a <= mont_s;
                mont_b <= mont_s;
                mont_n <= modulus;
                mont_start <= '1';
                enable_c <=  '1';
                next_state <= CALCULATE_1;
                if counter = 0 then       
                    mont_a <= mont_s;             
                    mont_b <= (C_BLOCK_SIZE-1 downto 1 => '0') & '1';                       
                    mont_start <= '1';
                    next_state <= FINAL;     
                    enable_c <= '0';
                end if;
            else
                next_state <= CALCULATE_2 ;     
                end if;
        
        when FINAL => --This state performs step 7 of the pseudo code
            mont_a <= x_h;
            mont_b <= (C_BLOCK_SIZE-1 downto 1 => '0') & '1';
            mont_n <= modulus;
            if mont_done = '1' then
                x_en <= '1';
                x_temp <= mont_s;
                result <= mont_s;
                next_state <= FINISHED;
            else
                next_state <= FINAL;
        end if;
        
        when FINISHED => --This state performs step 8 of the pseudo code
            result <= x_h;
            ready <= '1';
            next_state <= IDLE;
        when others  => 
            next_state <= IDLE;
        end case;        
    end process;
end expBehave;