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
--    This is the testbench for montgomery exponentiation.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity exponentiation_tb is
    end exponentiation_tb;

architecture Behavioral of exponentiation_tb is
    constant C_BLOCK_SIZE   : integer := 256;
    CONSTANT clk_period     : time := 14 ns;

    signal clk          : std_logic := '0';
    signal reset_n      : std_logic := '0';
    signal valid        : std_logic;
    signal ready        : std_logic;
    signal message      : std_logic_vector(C_BLOCK_SIZE -1 downto 0);
    signal key          : std_logic_vector(C_BLOCK_SIZE -1 downto 0);
    signal modulus      : std_logic_vector(C_BLOCK_SIZE -1 downto 0);
    signal r_mod            : std_logic_vector(C_BLOCK_SIZE -1 downto 0);
    signal r_2_mod        : std_logic_vector(C_BLOCK_SIZE -1 downto 0);
    signal result       : std_logic_vector(C_BLOCK_SIZE -1 downto 0);
    
    
    
    
 	function str_to_stdvec(inp: string) return std_logic_vector is
		variable temp: std_logic_vector(4*inp'length-1 downto 0) := (others => 'X');
		variable temp1 : std_logic_vector(3 downto 0);
	begin
		for i in inp'range loop
			case inp(i) is
				 when '0' =>	 temp1 := x"0";
				 when '1' =>	 temp1 := x"1";
				 when '2' =>	 temp1 := x"2";
				 when '3' =>	 temp1 := x"3";
				 when '4' =>	 temp1 := x"4";
				 when '5' =>	 temp1 := x"5";
				 when '6' =>	 temp1 := x"6";
				 when '7' =>	 temp1 := x"7";
				 when '8' =>	 temp1 := x"8";
				 when '9' =>	 temp1 := x"9";
				 when 'A'|'a' => temp1 := x"a";
				 when 'B'|'b' => temp1 := x"b";
				 when 'C'|'c' => temp1 := x"c";
				 when 'D'|'d' => temp1 := x"d";
				 when 'E'|'e' => temp1 := x"e";
				 when 'F'|'f' => temp1 := x"f";
				 when others =>  temp1 := "XXXX";
			end case;
			temp(4*(i-1)+3 downto 4*(i-1)) := temp1;
		end loop;
		return temp;
	end function str_to_stdvec;
	
begin


  dut : entity work.exponentiation
    port map (
                 clk        => clk,          
                 reset_n    => reset_n,       
                 valid      => valid,
                 ready      => ready,        
                 message    => message,     
                 key        => key,     
                 modulus    => modulus,     
                 r_mod      => r_mod,     
                 r_2_mod    => r_2_mod,   
                 result     => result   
             );
             
     clk_process : Process
     Begin
	   clk <= '0';
	   wait for clk_period/2;
	   clk <= '1';
	   wait for clk_period/2;
    end process;
    
     reset_process : Process
     Begin
       wait for clk_period;
	   reset_n <= '1';
	   wait;
    end process;
    

    
    stimuli_proc: process
    
    begin
        
        valid <= '0';
        
        wait for clk_period;
        
        message <=   x"0a2320202020202020202020203336203a2020544e554f43204547415353454d";
        key     <=   x"0000000000000000000000000000000000000000000000000000000000010001";
        modulus <=   x"99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d";
        r_mod   <=   x"666DAE8C529A9798EAC7A157FF32D7EDFD77038F56436722B36F298907008973";
        r_2_mod <=   x"56DDF8B43061AD3DBCD1757244D1A19E2E8C849DDE4817E55BB29D1C20C06364";
        
                
        wait for clk_period;
        valid <= '1';
       
        wait for clk_period;
        wait until ready = '1';
        
    end process;
    
end Behavioral;
