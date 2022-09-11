----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/03/2021 06:12:01 PM
-- Design Name: 
-- Module Name: Task_2 - Behavioral
-- Project Name: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Task_2 is
    Port ( A : in std_ulogic;
           B : in std_ulogic;
           Q : inout std_ulogic;
           QN : inout std_ulogic);
end Task_2;

architecture behavior of Task_2 is

begin
    Q <= A nor QN;
    QN <= B nor Q;

end behavior;
