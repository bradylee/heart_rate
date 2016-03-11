library ieee;
use ieee.std_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity shift_register is
	generic
	(
		LENGTH : in natural := 3, -- minimum 3
		DWIDTH : in natural := 32
	);
	port
	(
		clk : in std_logic,
		reset : in std_logic,
		wr_en : in std_logic,
		din : in std_logic_vector(DWIDTH - 1 downto 0)
	);
end entity;

architecture behavioral of shift_register is
	type shift_array is array (LENGTH - 1 downto 0) of std_logic-vector(DWIDTH - 1 downto 0);
	buff, buff_c : shift_array := (others => (others => '0'))
begin

	shift_process : process(din, wr_en)
	begin
	end process;

	clock_process : process(clock, reset)
	begin
		if (reset = '1') then
			buff <= (others => (others => '0'));
		elsif (rising_edge(clock) and wr_en = '1') then
			buff(LENGTH - 1 downto 1) <= buff(LENGTH - 2 downto 0);
			buff(0) <= din;
		end if;
	end process;


end architecture;
