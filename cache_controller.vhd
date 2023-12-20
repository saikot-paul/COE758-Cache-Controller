----------------------------------------------------------------------------------
-- Engineer: Saikot Paul 
-- 
-- Create Date:    20:02:31 10/28/2023 
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

entity cache_controller is
    Port ( clk : in  STD_LOGIC);
end cache_controller;

architecture Behavioral of cache_controller is

	-- ICON -- 
	component icon
	PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
	end component;
	
	signal control0 : STD_LOGIC_VECTOR(35 downto 0); 
	signal control1 : STD_LOGIC_VECTOR(35 downto 0); 
	
	-- ILA -- 
	component ila 
	PORT(
		CONTROL : INOUT STD_LOGIC_VECTOR(35 downto 0);
		CLK : IN STD_LOGIC; 
		DATA : IN STD_LOGIC_VECTOR(99 downto 0); 
		TRIG0 : IN STD_LOGIC_VECTOR(0 downto 0)
	);
	end component; 
	
	signal ila_data : STD_LOGIC_VECTOR(99 downto 0); 
	signal trig : STD_LOGIC_VECTOR(0 downto 0); 
	
	-- VIO -- 
	component vio
	PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    ASYNC_OUT : OUT STD_LOGIC_VECTOR(25 DOWNTO 0)
	 );
	end component;
	
	signal vio_sig : STD_LOGIC_VECTOR(25 downto 0); 
	
	-- CACHE MEMORY -- 
	component cache_mem
	  PORT (
		 clka : IN STD_LOGIC;
		 wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		 addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	  );
	end component;
	
	-- SDRAM CONTROLLER -- 
	component sdram_controller
	PORT(
		clk : IN std_logic;
		memstrb : IN std_logic;
		wea : IN std_logic_vector(0 to 0);
		address : IN std_logic_vector(11 downto 0);
		d_in : IN std_logic_vector(7 downto 0);          
		d_out : OUT std_logic_vector(7 downto 0)
		);
	end component;
		
	-- CACHE CONTROLLER REGISTERS -- 
	type tag is array(0 to 7) of STD_LOGIC_VECTOR(3 downto 0); 
	
	signal tag_reg : tag; 
	signal vbit : STD_LOGIC_VECTOR(7 downto 0) := "00000000"; 
	signal dbit : STD_LOGIC_VECTOR(7 downto 0) := "00000000"; 
	
	
	-- CACHE CONTROLLER SIGNALS -- 
	signal clk_counter : STD_LOGIC_VECTOR(7 downto 0); 
	signal state_sig : STD_LOGIC_VECTOR(2 downto 0) := "000"; 
	signal next_state : STD_LOGIC_VECTOR(2 downto 0); 
	signal hit_sig, dirty_sig : STD_LOGIC; 
	signal cache_to_main, main_to_cache : STD_LOGIC; 
	signal offset : STD_LOGIC_VECTOR(4 downto 0) := "00000"; 
	signal counter : integer; 
	
	-- CPU SIGNALS -- 
	signal cpu_address : STD_LOGIC_VECTOR(11 downto 0); 
	signal cpu_tag : STD_LOGIC_VECTOR(3 downto 0); 
	signal cpu_index : STD_LOGIC_VECTOR(2 downto 0); 
	signal index : integer; 
	signal cpu_dout : STD_LOGIC_VECTOR(7 downto 0); 
	signal cpu_din : STD_LOGIC_VECTOR(7 downto 0); 
	signal cpu_rd_wr, cpu_cs, cpu_rdy : STD_LOGIC; 
	
	-- CACHE MEMORY SIGNALS -- 
	signal cache_add_sig : STD_LOGIC_VECTOR(7 downto 0); 
	signal cache_rd_wr : STD_LOGIC_VECTOR(0 downto 0); 
	signal cache_din_sig, cache_dout_sig : STD_LOGIC_VECTOR(7 downto 0); 
	
	-- MAIN MEMORY SIGNALS -- 
	signal main_add_sig : STD_LOGIC_VECTOR(11 downto 0); 
	signal main_din_sig : STD_LOGIC_VECTOR(7 downto 0); 
	signal main_dout_sig : STD_LOGIC_VECTOR(7 downto 0);
	signal main_rd_wr : STD_LOGIC_VECTOR(0 downto 0); 
	signal main_memstrb : STD_LOGIC; 
	
begin
	
	-- PORT MAP -- 

	sys_icon : icon port map(control0, control1); 
	sys_ila : ila port map(control0, clk, ila_data, trig);
	sys_vio : vio port map(control1, vio_sig); 
	sys_cache : cache_mem port map(clk, cache_rd_wr, cache_add_sig, cache_din_sig, cache_dout_sig); 
	sys_sdram : sdram_controller port map(clk, main_memstrb, main_rd_wr, main_add_sig, main_din_sig, main_dout_sig); 
	
	-- ACTUAL PROCESSES -- 
	
	-- CHECK HIT OR MISS -- 
	hit_or_miss : process(cpu_address, tag_reg)
	begin 
		if(tag_reg(index) = cpu_tag and vbit(index) = '1') then 
			hit_sig <= '1'; 
		else 
			hit_sig <= '0'; 
		end if; 
		
	end process; 
	
	-- UPDATE STATE -- 
	update_state : process(clk, state_sig, next_state) 
	begin 
		if (clk'event and clk='1') then 
			state_sig <= next_state; 
		end if; 
	end process; 
	
	-- GENERATE THE NEXT STATE -- 
	fsm : process(clk, cpu_cs, state_sig, cache_to_main, main_to_cache) 
	begin 
		if (clk'event and clk='1') then 
			if (state_sig = "000") then 
			-- IDLE STATE -- 
			-- LET CPU KNOW THAT IT IS READY FOR TRANSACTION -- 
				if (cpu_cs = '1') then 
			-- IF THE CPU TURNS ON CS THEN CHECK READ WRITE -- 
					next_state <= "001"; 
				end if; 
			elsif (state_sig = "001") then 
				-- GO TO: 
				-- 	STATE 2 : READ 
				-- 	STATE 3 : WRITE 
				-- 	STATE 4 : WRITE CACHE TO MAIN 
				-- 	STATE 5 : WRITE MAIN TO CACHE 
				if (hit_sig = '1') then 
					if (cpu_rd_wr = '0') then 
					-- READ -- 
						next_state <= "010"; 
					else 
					-- WRITE -- 
						next_state <= "011"; 
					end if; 
				else 
					if (dbit(index) = '0') then 
					-- CACHE TO MAIN -- 
						next_state <= "100"; 
					else 
					-- MAIN TO CACHE -- 
						next_state <= "101"; 
					end if; 
				end if; 
			elsif (state_sig = "010") then 
			-- IN READ STATE -- 
				next_state <= "000"; 
			elsif (state_sig = "011") then 
			-- IN WRITE STATE -- 
				next_state <= "000"; 
			elsif (state_sig = "100") then 
			-- IN MAIN TO CACHE STATE -- 
				if (main_to_cache = '1') then 
					next_state <= "001"; 
				end if; 
			elsif (state_sig = "101") then 
			-- IN CACHE TO MAIN STATE -- 
				if (cache_to_main = '1') then 
					next_state <= "100"; 
				end if; 
			end if; 
		end if; 
	end process; 
	
	
	-- GENERATE OUTPUT SIGNALS OF STATES -- 
	gen_output : process(clk, state_sig)
	begin 
		if (clk'event and clk='1') then 
			if (state_sig = "000") then 
			-- IDLE STATE -- 
				cpu_rdy <= '1'; 
			elsif (state_sig = "001") then 
			-- TRANSITION STATE -- 
				offset <= "00000"; 
				cache_to_main <= '0'; 
				main_to_cache <= '0'; 
				cpu_rdy <= '0'; 
				counter <= 0; 
			elsif (state_sig = "010") then 
			-- READ STATE -- 
				cache_rd_wr(0) <= '0'; 
				cache_add_sig <= cpu_address(7 downto 0); 
				cpu_din <= cache_dout_sig; 
			elsif (state_sig = "011") then 
			-- WRITE STATE -- 
				cache_rd_wr(0) <= '1'; 
				cache_add_sig <= cpu_address(7 downto 0); 
				cache_din_sig <= cpu_dout; 
				dbit(index) <= '1'; 
			elsif (state_sig = "100") then 
			-- MAIN TO CACHE -- 
				if (counter = 64) then 
					counter <= 0; 
					offset <= "00000"; 
					tag_reg(index) <= cpu_tag; 
					vbit(index) <= '1'; 
					dbit(index) <= '0'; 
					main_to_cache <= '1'; 
				else 
					
					if (counter mod 2 = 1) then 
						main_memstrb <= '0'; 
					else 
						-- MAIN SIGNALS -- 
						main_memstrb <= '1'; 
						main_rd_wr(0) <= '0';
						--main_memstrb <= '1'; 
						main_add_sig(11 downto 8) <= cpu_tag; 
						main_add_sig(7 downto 5) <= cpu_index; 
						main_add_sig(4 downto 0) <= offset; 
						
						
						-- CACHE SIGNALS -- 
						cache_rd_wr(0) <= '1'; 
						cache_add_sig(7 downto 5) <= cpu_address(7 downto 5);
					   cache_add_sig(4 downto 0) <= offset; 

						-- WRITE MAIN DOUT INTO CACHE DIN -- 
						cache_din_sig <= main_dout_sig; 
						
						-- INCREMENT THE OFFSET -- 
						offset <= std_logic_vector(unsigned(offset) + 1); 
					
					end if;
					
					counter <= counter + 1;
				end if; 
					
			elsif (state_sig = "101") then 
				vbit(index) <= '0'; 
			-- CACHE TO MAIN -- 
				if (counter = 64) then 
					counter <= 0; 
					offset <= "00000"; 
					cache_to_main <= '1'; 
				else 
					-- OSCILLATE THE MAIN_MEMSTRB SIGNAL TO ENSURE THAT THE DATA IS STABLE -- 
					if (counter mod 2 = 1) then 
						main_memstrb <= '0'; 
					else 
						-- MAIN SIGNALS -- 
						-- 	WRITE TO MAIN -- 
						main_memstrb <= '1'; 
						main_rd_wr(0) <= '1';
						--main_memstrb <= '1'; 
						main_add_sig(11 downto 8) <= tag_reg(index); 
						main_add_sig(7 downto 5) <= cpu_index; 
						main_add_sig(4 downto 0) <= offset; 
						
						-- CACHE SIGNALS -- 
						cache_rd_wr(0) <= '0'; 
						cache_add_sig(7 downto 5) <= cpu_index;
						cache_add_sig(4 downto 0) <= offset; 
						
						-- WRITE CACHE DOUT TO MAIN DIN -- 
						main_din_sig <= cache_dout_sig; 
						
						-- INCREMENT THE OFFSET -- 
						offset <= std_logic_vector(unsigned(offset) + 1); 
						
					end if; 
					counter <= counter + 1; 
				end if; 
			end if; 
		end if; 
	end process; 
	
	
	
	-- WIRES --
	cpu_tag <= cpu_address(11 downto 8); 
	cpu_index <= cpu_address(7 downto 5); 
	index <= to_integer(unsigned(cpu_index)); 
	
	-- VIO -- 
	cpu_address <= vio_sig(11 downto 0); 
	cpu_dout <= vio_sig(19 downto 12); 
	cpu_cs <= vio_sig(20); 
	cpu_rd_wr <= vio_sig(21); 
	
	-- ILA -- 
	trig(0) <= cpu_cs; 
	
	-- CPU DATA
	ila_data(0) <= cpu_rdy; 
	ila_data(1) <= cpu_cs; 
	ila_data(2) <= cpu_rd_wr; 
	ila_data(14 downto 3) <= cpu_address; 
	ila_data(22 downto 15) <= cpu_din; 
	ila_data(31 downto 24) <= cpu_dout; 
	
	-- CACHE CONTROLLER DATA -- 
	ila_data(32) <= hit_sig; 
	ila_data(33) <= vbit(index); 
	ila_data(34) <= dbit(index); 
	ila_data(37 downto 35) <= state_sig; 
	
	-- CACHE MEMORY DATA -- 
	ila_data(38) <= cache_rd_wr(0); 
	ila_data(46 downto 39) <= cache_add_sig; 
	ila_data(54 downto 47) <= cache_din_sig; 
	ila_data(62 downto 55) <= cache_dout_sig; 
	
	-- MAIN MEMORY DATA -- 
	ila_data(63) <= main_rd_wr(0); 
	ila_data(64) <= main_memstrb; 
	ila_data(76 downto 65) <= main_add_sig; 
	ila_data(84 downto 77) <= main_din_sig; 
	ila_data(92 downto 85) <= main_dout_sig; 
	

end Behavioral;

