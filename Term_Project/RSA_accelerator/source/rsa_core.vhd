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
--   RSA encryption core. This core implements the function
--   C = M**key_e mod key_n.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rsa_core is
	generic (
		C_BLOCK_SIZE          : integer := 256
	);
	port (
		-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid            : out std_logic;
		-- Slave ready to accept a new message
		msgout_ready            :  in std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last             : out std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                 : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   : in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_r_mod               : in std_logic_vector(C_block_size -1 downto 0);
        key_r_2_mod             : in std_logic_vector(C_block_size -1 downto 0);
		rsa_status              : out std_logic_vector(31 downto 0)

	);
end rsa_core;

architecture rtl of rsa_core is

    -- Control data
    type state is (INIT, LOADMSG, CALC, FINAL);
    signal current_state  : state;
    signal next_state     : state;
    -- Config registers                                       
    signal key_n_temp     : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal key_e_d_temp   : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal modulus_temp   : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal r_mod_temp     : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal r_2_mod_temp   : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    -- Message register
    signal msg_in_en      : std_logic;
    signal msgin_temp     : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    -- Output register
    signal msgout_temp    : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal msg_out_en     : std_logic;
    signal msgout_temp_en : std_logic ;
    
    signal valid          : std_logic ;
    signal ready          : std_logic ;
    signal result         : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    
    
begin
  -- *****************************************************************************
  -- Registers for configuration: key_n_temp, key_e_d_temp, r_mod_temp and r_2_mod_temp
  -- *****************************************************************************
    process (clk, reset_n) begin
        if(reset_n = '0') then
            r_mod_temp <= (others => '0');
            r_2_mod_temp <= (others => '0');
            key_n_temp <= (others => '0');
            key_e_d_temp <= (others => '0');
        elsif rising_edge(clk) then
            r_2_mod_temp <= key_r_2_mod ;
            r_mod_temp <= key_r_mod; 
            key_n_temp <= key_n ;
            key_e_d_temp <= key_e_d;
        end if;
     end process;
     
 -- *****************************************************************************
 -- Registers for configuration: msgin_temp and msgout_temp
 -- *****************************************************************************    
     process (clk, reset_n) begin
        if(reset_n = '0') then
            msgin_temp <= (others => '0');
        elsif rising_edge(clk) then
            if (msg_in_en = '1') then
                msgin_temp <= msgin_data;
            end if;
        end if;
     end process;
    
 -- *****************************************************************************
 -- Instantiation and Port mapping exponentiation module
 -- *****************************************************************************                      
	i_exponentiation : entity work.exponentiation
		generic map (
			C_block_size => C_BLOCK_SIZE
		)
		port map (
			message   => msgin_data  ,
			key       => key_e_d     ,
			r_mod     => key_r_mod,
		    r_2_mod   => key_r_2_mod,
			valid     => valid,
			ready     => ready,
			result    => result ,
			modulus   => key_n       ,
			clk       => clk         ,
			reset_n   => reset_n
		);

	rsa_status   <= (others => '0');
     
  -- ***************************
  -- input and output message handshaking
  -- *************************
     inputhandshake: process (clk,reset_n)
        begin
           if rising_edge (clk)then
                if reset_n = '1' then
                    msg_in_en <= msgin_valid and msgin_ready;
                else
                    msg_in_en <= '0';
                end if;
           end if;
        end process;      

     outputhandshake: process (clk,reset_n)
        begin
             if (reset_n = '0') then
                 msg_out_en <= '0'; 
             elsif rising_edge(clk) then
                 msg_out_en <= msgout_valid and msgout_ready;
             end if;
     end process;  
                    
  -- ***************************
  -- message_out_temp enabling
  -- *************************               
     messageout_temp_en: process(clk, reset_n)
     begin
         if reset_n = '0' then
             msgout_temp <= (others => '0');
         elsif rising_edge(clk) then
             if msgout_temp_en = '1' then
                 msgout_temp <= result;
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
                 current_state <= INIT;
             elsif rising_edge(clk) then
                 current_state <= next_state;
             end if;
     end process;                                   
  -- ***************************
  -- Combinatial
  -- ***************************        
     Combinatial : process (current_state, msgout_temp, msgin_last, msg_in_en, ready, msg_out_en, result)
         begin
              valid <= '0';
              msgout_temp_en <= '0';
              msgin_ready <= '0';
              msgout_valid <= '0';
              
              msgout_last <= '0';
              msgout_data <= (others => '0');
              next_state <= current_state;
              
              case (current_state) is
                 when INIT  =>
                    msgin_ready <= '1';
                    msgout_last <= '0';  
                    if msg_in_en = '1' then
                        next_state <= LOADMSG;
                    else
                        next_state <= INIT;
                    end if;
                                        
                 when LOADMSG =>     
                    if msgin_last = '1' then
                        valid <= '1';
                        next_state <= CALC;
                    else
                        next_state <= LOADMSG;
                    end if;
                                        
                  when CALC =>
                    msgin_ready <= '0';
                    if ready = '1' then
                        msgout_valid <= '1';
                        msgout_temp_en <= '1';
                        next_state <= FINAL;
                    else
                        next_state <= CALC;
                    end if;
                      
                  when FINAL =>
                     msgout_last <= '1';
                     msgout_valid <= '1';
                     if msg_out_en = '1' then
                        msgout_data <= msgout_temp;                      
                        next_state <= INIT;
                    else
                        next_state <= FINAL;
                    end if;
                    
                when others =>
                    next_state <= INIT;
       end case;	  
	 end process;
end rtl;