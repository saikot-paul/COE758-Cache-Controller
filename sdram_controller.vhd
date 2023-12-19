----------------------------------------------------------------------------------
-- Company: 		 Toronto Metropolitan University 
-- Engineer: 		 Saikot Paul, Josh Naraine
-- 
-- Create Date:    01:48:32 10/25/2023 
-- Design Name: 
-- Module Name:    sdram_controller - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sdram_controller is
port (
		clk : in std_logic; 
		address : in std_logic_vector(15 downto 0); 
		wea : in std_logic_vector(0 downto 0); 
		data_in :  in std_logic_vector(7 downto 0); 
		data_out : out std_logic_vector(7 downto 0)
	); 
end sdram_controller;

architecture Behavioral of sdram_controller is

	signal empty : std_logic := '0'; 
	
	type twod_arr is array (7 downto 0, 31 downto 0) of std_logic_vector(7 downto 0); 
	signal x : integer; 
	signal y : integer; 
	signal mem_arr : twod_arr; 

begin
	
		process(clk)
		begin 
			
			if (clk'event and clk='1') then 
			
				x <= to_integer(unsigned(address(15 downto 8))); 
				y <= to_integer(unsigned(address(7 downto 0))); 
				
				if (empty = '0') then 
					for i in 0 to 7 loop 
						for j in 0 to 31 loop 
							mem_arr(i, j) <= "11111111"; 
							data_out <= mem_arr(i, j);
						end loop; 
					end loop; 
					empty <= '1'; 
				end if;
				
				if (wea = "0") then 
					data_out <= mem_arr(x, y); 
				else 
					mem_arr(x,y) <= data_in; 
				end if; 
				
			end if; 
				
		end process; 


end Behavioral;
