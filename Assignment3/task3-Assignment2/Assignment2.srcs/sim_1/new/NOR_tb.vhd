library IEEE;
use IEEE.Std_logic_1164.all;

entity Task_2_tb is
end;

architecture bench of Task_2_tb is


  signal A, B, Q, QN : std_ulogic;
  

begin

  dut: entity work.Task_2(behavior)
  
    port map ( A  => A,
                         B  => B,
                         Q  => Q,
                         QN => QN );

  stimulus: process
  begin
  A <= '1' ; B <= '0' ;
  wait for 10 ns ;
  A <= '0' ;
  wait for 10 ns ;
  B <= '1' ;
  wait for 10 ns ;
  B <= '0' ;
  wait for 10 ns ;
  B <= '1' ; A <= '1' ;
  
   wait;
  
  end process;


end;