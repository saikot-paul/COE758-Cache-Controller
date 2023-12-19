----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		 Saikot Paul, Josh Naraine
-- 
-- Create Date:    21:04:08 10/24/2023 
-- Design Name: 
-- Module Name:    cache_controller - Behavioral 
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

entity cache_controller is
	PORT ( 
		clk : in std_logic; 
		address_in : out std_logic_vector(15 downto 0); 
		state : out std_logic_vector(2 downto 0); 
		cs : out std_logic; 
		rd_wr_in : out std_logic; 
		hit : out std_logic; 
		
		cache_add : out std_logic_vector(7 downto 0) ; 
		cache_din : out std_logic_vector(7 downto 0) ; 
		cache_dout : out std_logic_vector(7 downto 0) ; 
		c_wea : out std_logic_vector(0 downto 0); 
		
		m_wea : out std_logic_vector(0 downto 0); 
		main_add : out std_logic_vector(15 downto 0);
		main_din : out std_logic_vector(7 downto 0); 
		main_dout : out std_logic_vector(7 downto 0)
		
	); 
end cache_controller;

architecture Behavioral of cache_controller is
	-- ICON -- 
	component icon
	  PORT (
		 CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
	end component;
	
	signal control : STD_LOGIC_VECTOR(35 downto 0); 
	-- 
	
	-- ILA -- 
	component ila
	PORT (
		 CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		 CLK : IN STD_LOGIC;
		 DATA : IN STD_LOGIC_VECTOR(99 DOWNTO 0);
		 TRIG0 : IN STD_LOGIC_VECTOR(0 TO 0));
	end component;
	
	signal ila_data : STD_LOGIC_VECTOR(99 downto 0); 
	signal trig : STD_LOGIC_VECTOR(0 downto 0); 
	-- 
	
	-- CPU -- 
	component CPU_gen is
	Port ( 
		clk 		: in  STD_LOGIC;
      rst 		: in  STD_LOGIC;
      trig 		: in  STD_LOGIC;
		-- Interface to the Cache Controller.
      Address 	: out  STD_LOGIC_VECTOR (15 downto 0);
      wr_rd 	: out  STD_LOGIC;
      cs 		: out  STD_LOGIC;
      DOut 		: out  STD_LOGIC_VECTOR (7 downto 0)
	);
	end component;
	
	signal cpu_add : STD_LOGIC_VECTOR(15 downto 0); 
	signal cpu_cs : STD_LOGIC;
	signal cpu_rdy : STD_LOGIC;
	signal cpu_rd_wr : STD_LOGIC;
	signal cpu_din, cpu_dout_sig : STD_LOGIC_VECTOR(7 downto 0); 
	signal cpu_tag : STD_LOGIC_VECTOR(7 downto 0); 
	signal index : integer; 
	signal offset : STD_LOGIC_VECTOR(4 downto 0); 
	-- 
	
	-- CACHE MEMORY -- 
	component cache 
	port ( 
	 clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	); 
	end component; 
	
	signal cache_wea : std_logic_vector(0 downto 0); 
	signal cache_add_sig : std_logic_vector(7 downto 0); 
	signal cache_din_sig : std_logic_vector(7 downto 0); 
	signal cache_dout_sig : std_logic_vector(7 downto 0); 
	--- 
	
	-- SDRAM MEMORY -- 
	component sdram_controller is
	port (
			clk : in std_logic; 
			address : in std_logic_vector(15 downto 0); 
			wea : in std_logic_vector(0 downto 0); 
			data_in :  in std_logic_vector(7 downto 0); 
			data_out : out std_logic_vector(7 downto 0)
		); 
	end component;
	
	signal main_wea : STD_LOGIC_VECTOR(0 downto 0); 
	signal main_add_sig : STD_LOGIC_VECTOR(15 downto 0); 
	signal main_din_sig : STD_LOGIC_VECTOR(7 downto 0); 
	signal main_dout_sig : STD_LOGIC_VECTOR(7 downto 0); 
	
	-- CACHE CONTROLLER -- 
	type tag is array(7 to 0) of STD_LOGIC_VECTOR(7 downto 0); 
	signal dbit_reg :  STD_LOGIC_VECTOR(7 downto 0) := "00000000"; 
	signal vbit_reg :  STD_LOGIC_VECTOR(7 downto 0) := "00000000"; 
	signal tag_reg: tag := ((others => (others => '0'))); 
	signal counter : integer := 0 ; 
	signal cache_offset : STD_LOGIC_VECTOR(4 downto 0) := "00000"; 
	
	-- STATE SIGNALS -- 
	signal state_sig : STD_LOGIC_VECTOR(2 downto 0) := "000"; 
	signal hit_sig, dirty_sig, d_in_mux, d_out_mux : STD_LOGIC; 
	
	

begin

	trig(0) <= '1'; 
	
	sys_cache : cache port map(clk, cache_wea, cache_add_sig, cache_din_sig, cache_dout_sig);  
	sys_sdram : sdram_controller port map(clk, main_add_sig, main_wea, main_din_sig, main_dout_sig); 
	sys_icon : icon port map (control); 
	sys_ila : ila port map (control, clk, ila_data, trig); 
	sys_cpu : CPU_gen port map (clk, '0', cpu_rdy, cpu_add, cpu_rd_wr, cpu_cs, cpu_dout_sig); 
	
	hit_or_miss : process(cpu_add) 
	variable index_binary : STD_LOGIC_VECTOR(2 downto 0); 
	begin 
			cpu_tag <= cpu_add(15 downto 8); 
			index_binary := cpu_add(7 downto 5);
			offset <= cpu_add(4 downto 0);
			
			if index_binary = "000" then 
				index <= 1; 
			elsif index_binary = "001" then 
				index <= 2; 
			elsif index_binary = "010" then 
				index <= 3;
			elsif index_binary = "011" then 
				index <= 4;
			elsif index_binary = "100" then 
				index <= 5;
			elsif index_binary = "101" then 
				index <= 6;
			elsif index_binary = "110" then 
				index <= 7;
			elsif index_binary = "111" then 
				index <= 8;
			end if; 
			
			if (tag_reg(index) = cpu_tag) then 
				hit_sig <= '1'; 
			else
				hit_sig <= '0'; 
				
				if (dbit_reg(index) = '1') then 
					dirty_sig <= '1'; 
				else 
					dirty_sig <= '0'; 
				end if;
		end if; 
	end process; 
			
	
	state_transition: process(clk, cpu_cs) 
	begin
			if (clk'event and clk='1') then  
				case state_sig is 
					when "000" => 
						cpu_rdy <= '1';
						if (cpu_cs = '1') then 
							state_sig <= "001"; 
						end if; 
						
					-- CHECK HIT OR MISS -- 
					when "001" => 
						if (hit_sig = '1') then 
							if (cpu_rd_wr = '0') then 
								state_sig <= "010"; 
							else 
								state_sig <= "011"; 
							end if;
							-- SET THE ADDRESS TO READ/WRITE FROM -- 
							cache_add_sig <= cpu_add(7 downto 0); 
						else 
							state_sig <= "100"; 
						end if; 
					-- READ STATE -- 
					when "010" => 
						cache_wea <= "0"; 
						d_out_mux <= '1'; 
						state_sig <= "000"; 
					when "011" => 
						cache_wea <= "1"; 
						d_in_mux <= '0'; 
						dbit_reg(index) <= '1'; 
						state_sig <= "000"; 
					when "100" => 
						if (dirty_sig = '0') then 
						-- LOAD FROM MAIN MEMORY -- 
							state_sig <= "101"; 
						else 
						-- LOAD TO MAIN MEMORY -- 
							state_sig <= "110"; 
						end if; 
					when "101" => 
					-- LOAD FROM MAIN MEMORY -- 
						if (counter = 32) then 
							counter <= 0; 
							dbit_reg(index) <= '0'; 
							vbit_reg(index) <= '1';  
							tag_reg(index) <= cpu_tag; 
							cache_offset <= "00000";
							state_sig <= "001"; 
						else 
							-- WRITE MAIN TO CACHE -- 
							cache_add_sig(7 downto 5) <= STD_LOGIC_VECTOR(to_unsigned(index, cache_add_sig'length)); 
							cache_add_sig(4 downto 0) <= cache_offset; 
							cache_wea <= "1"; 
							
							-- READ FROM MAIN -- 
							main_add_sig(15 downto 5) <= cpu_add(15 downto 5); 
							main_add_sig(4 downto 0) <= cache_offset; 
							main_wea <= "0"; 
							
							d_in_mux <= '1'; 
							
							cache_offset <= STD_LOGIC_VECTOR(unsigned(cache_offset) + 1); 
							counter <= counter + 1; 
						end if; 
					when "110" =>
					-- WRITE CACHE TO MAIN -- 
						if (counter = 32) then 
							counter <= 0; 
							vbit_reg(index) <= '0';
							cache_offset <= "00000";
							state_sig <= "101"; 
						else 
							-- READ FROM CACHE -- 
							cache_add_sig(7 downto 5) <= STD_LOGIC_VECTOR(to_unsigned(index, cache_add_sig'length)); 
							cache_add_sig(4 downto 0) <= cache_offset; 
							cache_wea <= "0"; 
							
							-- WRITE TO MAIN -- 
							main_add_sig(15 downto 8) <= tag_reg(index); 
							main_add_sig(7 downto 5) <= STD_LOGIC_VECTOR(to_unsigned(index, cache_add_sig'length)); 
							main_add_sig(4 downto 0) <= cache_offset; 
							main_wea <= "1"; 
							
							d_out_mux <= '0'; 
							
							cache_offset <= STD_LOGIC_VECTOR(unsigned(cache_offset) + 1); 
							counter <= counter + 1; 
							
						end if; 
					when others => 
						state_sig <= "000"; 
			end case; 
		end if; 
	end process; 
	
	d_out : process(d_out_mux)
	begin 
		if (d_out_mux = '0') then 
			main_din_sig <= cache_dout_sig; 
		else 
			cpu_din <= cache_dout_sig; 
		end if; 
	end process; 
	
	d_in : process(d_in_mux) 
	begin 
		if (d_in_mux = '0') then 
			cache_din_sig <= cpu_dout_sig; 
		else 
			cache_din_sig <= main_dout_sig; 
		end if; 
	end process; 
	
	address_in <= cpu_add; 
	state <= state_sig; 
	cs <= cpu_cs; 
	hit <= hit_sig; 
	
	cache_add <= cache_add_sig; 
	cache_din <= cache_din_sig;
	cache_dout <= cache_dout_sig; 
	c_wea <= cache_wea; 
	
	m_wea <= main_wea; 
	main_add <= main_add_sig; 
	main_din <= main_din_sig; 
	main_dout <= main_dout_sig; 

end Behavioral;
