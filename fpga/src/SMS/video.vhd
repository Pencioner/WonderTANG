--
-- Multicore 2 / Multicore 2+
--
-- Copyright (c) 2017-2020 - Victor Trucco
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
		
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity video is
	Port (
		clk:				in  std_logic;
		ce_pix:			in  std_logic;
		pal:				in  std_logic;
		gg:				in  std_logic;
		border:        in  std_logic := '1';
		mask_column:	in  std_logic := '0';
		smode_M1:		in	 std_logic;
		smode_M3:		in	 std_logic;
		
		x: 				out std_logic_vector(8 downto 0);
		y:					out std_logic_vector(8 downto 0);
		hsync:			out std_logic;
		vsync:			out std_logic;
		hblank:			out std_logic;
		vblank:			out std_logic;
        reset_n:         in std_logic);
end video;

architecture Behavioral of video is

	signal hcount:			std_logic_vector(8 downto 0) := (others => '0');
	signal vcount:			std_logic_vector(8 downto 0) := (others => '0');

	signal vbl_st,vbl_end: std_logic_vector(8 downto 0);
	signal hbl_st,hbl_end: std_logic_vector(8 downto 0);
begin

	process (clk, reset_n)
	begin
        if reset_n = '0' then
            vsync <= '0';
            hsync <= '0';
		elsif rising_edge(clk) then
			if ce_pix = '1' then
				if hcount=487	then
					vcount <= vcount + 1;
					if pal = '1' then
						-- VCounter: 0-258, 458-511 = 313 steps
						if smode_M1='1' then
							if vcount = 258 then
								vcount <= conv_std_logic_vector(458,9); 
							elsif vcount = 461 then
								vsync <= '1';
							elsif vcount = 464 then
								vsync <= '0';
							end if;
						elsif smode_M3='1' then
							if vcount = 266 then
								vcount <= conv_std_logic_vector(482,9);
							elsif vcount = 482 then
								vsync <= '1';
							elsif vcount = 485 then
								vsync <= '0';
							end if;
						else
						-- VCounter: 0-242, 442-511 = 313 steps
							if vcount = 242 then
								vcount <= conv_std_logic_vector(442,9);
							elsif vcount = 442 then
								vsync <= '1';
							elsif vcount = 445 then
								vsync <= '0';
							end if;
						end if;
					else
					-- NTSC mode 224 lines ...
						if smode_M1='1' then
							if vcount = 234 then 
								vcount <= conv_std_logic_vector(485,9);
							elsif vcount = 487 then
								vsync <= '1';
							elsif vcount = 490 then
								vsync <= '0';
							end if;
					-- NTSC mode 240 lines -- this mode is not suposed to work anyway
						elsif smode_M3='1' then 
							if vcount = 261 then -- needs to be > 240 to generate an IRQ
								vcount <= conv_std_logic_vector(0,9);
							elsif vcount = 257 then
								vsync <= '1';
							elsif vcount = 260 then
								vsync <= '0';
							end if;
						else
						-- VCounter: 0-218, 469-511 = 262 steps
							if vcount = 218 then
								vcount <= conv_std_logic_vector(469,9);
							elsif vcount = 471 then
								vsync <= '1';
							elsif vcount = 474 then
								vsync <= '0';
							end if;
						end if;
					end if;
				end if;

				hcount <= hcount + 1;
				-- HCounter: 0-295, 466-511 = 342 steps
				if hcount = 295 then
					hcount <= conv_std_logic_vector(466,9);
				end if;
				if hcount = 280 then
					hsync <= '1';
				elsif hcount = 474 then
					hsync <= '0';
				end if;
			end if;
		end if;
	end process;

	x	<= hcount;
	y	<= vcount;

	vbl_st  <= conv_std_logic_vector(184,9) when (smode_M1='1' and gg='1' and border='0')
			else conv_std_logic_vector(224,9) when smode_M1 = '1'
			else conv_std_logic_vector(240,9) when smode_M3 = '1'
			else conv_std_logic_vector(215,9) when border = '1' and gg = '0'
			else conv_std_logic_vector(192,9) when (border xor gg) = '0'
			else conv_std_logic_vector(168,9);
			
	vbl_end <= conv_std_logic_vector(40,9)  when (smode_M1='1' and gg='1' and border='0')
			else conv_std_logic_vector(000,9) when smode_M1 = '1' or smode_M3 = '1' 
			else conv_std_logic_vector(488,9) when border = '1' and gg = '0'
			else conv_std_logic_vector(000,9) when (border xor gg) = '0'
			else conv_std_logic_vector(024,9);

	hbl_st  <= conv_std_logic_vector(270,9) when border = '1' and gg = '0'
			else conv_std_logic_vector(256,9) when (border xor gg) = '0'
			else conv_std_logic_vector(208,9);

	hbl_end <= conv_std_logic_vector(500,9) when border = '1' and gg = '0'
			else conv_std_logic_vector(008,9) when (border xor gg) = '0' and mask_column = '1'
			else conv_std_logic_vector(000,9) when (border xor gg) = '0'
			else conv_std_logic_vector(048,9);

	process (clk)
	begin
		if rising_edge(clk) then
			if ce_pix = '1' then
				if (hcount=hbl_end) then
					hblank <= '0';
				elsif (hcount=hbl_st) then
					hblank <= '1';
				end if;
				
				if (vcount=vbl_end) then
					vblank <= '0';
				elsif (vcount=vbl_st) then
					vblank <= '1';
				end if;
			end if;
		end if;
	end process;

end Behavioral;
