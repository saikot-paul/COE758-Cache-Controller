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
		memstrb : in std_logic; 
		wea : in std_logic_vector(0 downto 0); 
		address : in std_logic_vector(11 downto 0); 
		d_in :  in std_logic_vector(7 downto 0); 
		d_out : out std_logic_vector(7 downto 0)
	); 
end sdram_controller;

architecture Behavioral of sdram_controller is

	signal sdram_rd_wr : STD_LOGIC_VECTOR(0 downto 0);  
	signal sdram_add_sig : STD_LOGIC_VECTOR(11 downto 0);  
	signal sdram_din_sig :  in std_logic_vector(7 downto 0); 
	signal sdram_dout_sig : out std_logic_vector(7 downto 0); 

	signal empty : STD_LOGIC := '0'; 
	signal counter : STD_LOGIC_VECTOR(11 downto 0) := "000000000000";
	
	component sdram 
	PORT ( 
		clka : IN STD_LOGIC; 
		wea : IN STD_LOGIC_VECTOR(0 downto 0); 
		addra : in std_logic_vector(11 downto 0); 
		dina :  in std_logic_vector(7 downto 0); 
		douta : out std_logic_vector(7 downto 0)
	); 
	END component; 

begin
	

	sys_sdram : sdram port map (clk, sdram_rd_wr, sdram_add_sig, sdram_din_sig, sdram_dout_sig); 

	main_process : process(clk)
	begin 
		if (clk'event and clk='1') then 
			sdram_add_sig <= address; 
		
			if (memstrb = '1') then 
	
				if (wea(0) = '0') then 
					sdram_rd_wr(0) <= '0'; 
					d_out <= sdram_dout_sig; 
				else 
					sdram_rd_wr(0) <= '1'; 
					sdram_din_sig <= d_in; 
				end if; 
			end if; 
		
		end if;
	end process; 
				



end Behavioral;
