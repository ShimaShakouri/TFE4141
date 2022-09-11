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
--    This module performs modular multiplication algorithm.
--------------------------------------------------------------------------------
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Mont is
  Generic(
  C_BLOCK_SIZE : integer := 256
  );
  port(  
    clk        : in std_logic;
    reset      : in std_logic;
    A          : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    B          : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    N          : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    enable     : in std_logic;
    S          : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    data_ready : out std_logic
  );
end Mont;

architecture Behavioral of Mont is

signal S_temp  : std_logic_vector(C_BLOCK_SIZE+1 downto 0) := (others => '0');
signal B_temp  : std_logic_vector(C_BLOCK_SIZE-1 downto 0) := (others => '0');
signal A_temp  : std_logic_vector(C_BLOCK_SIZE-1 downto 0) := (others => '0');
signal N_temp  : std_logic_vector(C_BLOCK_SIZE-1 downto 0);


type state_type is (IDLE, CALCULATE, FINAL);
signal state : state_type;

begin

 -- *****************************************************************************
 -- FSM 
 -- ***************************************************************************** 
Mont_S : process(clk,enable,reset)
begin

if reset = '1' and rising_edge(clk) then
  case state is
    when IDLE =>
    
      --initializing values   
        data_ready <= '0';
      if enable = '1' then
        S_temp <= (others => '0');
        A_temp <= A;
        B_temp <= B;
        N_temp <= N;
        state <= CALCULATE;
      end if;
      
    when CALCULATE =>  
      if A_temp(0) = '1' then
      
        if (S_temp(0) xor B_temp(0)) = '1' then
          S_temp <= std_logic_vector(shift_right(unsigned (S_temp) + unsigned (B_temp) + unsigned (N), 1));
        else
          S_temp <= std_logic_vector(shift_right(unsigned(S_temp) + unsigned (B_temp), 1));
        end if;
      else
      
          --If the result is less than N (modulus), we need to add N 
        if S_temp(0) = '1' then
          S_temp <= std_logic_vector(shift_right(unsigned(S_temp) + unsigned (N), 1));
        else
          S_temp <= std_logic_vector(shift_right(unsigned(S_temp), 1));
        end if;
      end if;
      
      --Check whether we reached the last bit of N or not. If yes, the calculation is finished
      if N_temp = std_logic_vector(to_unsigned(1, C_BLOCK_SIZE)) then
        state <= FINAL;
      else
        state <= CALCULATE;
      end if;
      
      --Right shifting A and N
      N_temp <= std_logic_vector(shift_right(unsigned(N_temp), 1));
      A_temp <= std_logic_vector(shift_right(unsigned(A_temp), 1));
        
    when FINAL =>
    
        --Finalizing values
      if( S_temp > N) then
        S <= std_logic_vector(unsigned (S_temp(C_BLOCK_SIZE-1 downto 0)) - unsigned (N));
      else
        S <= S_temp(C_BLOCK_SIZE-1 downto 0);
      end if;
      data_ready <= '1';
      state <= IDLE;
    when others =>
      state <= IDLE;
    end case;
end if;
end process;
end Behavioral;