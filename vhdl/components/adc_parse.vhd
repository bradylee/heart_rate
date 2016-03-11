library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity adc_parse is
	port 
	(
		clk : in std_logic;
		reset : in std_logic;
		din : in std_logic_vector(COMPRESSED_WIDTH - 1 downto 0);
		in_empty : in std_logic;
		adc_full : in std_logic;
		sample_full : in std_logic;
		in_rd_en : out std_logic;
		adc_wr_en : out std_logic;
		sample_wr_en : out std_logic;
		adc_dout : out std_logic_vector(ADC_WIDTH - 1 downto 0);
		sample_dout : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0)
	);
end entity;

architecture behavioral of adc_parse is
	signal state, next_state : parse_state := init;
	--signal adc_buffer, adc_buffer_c : adc_array(ADC_COUNT - 1 downto 0) := (others => (others => '0'));
	signal adc_buffer, adc_buffer_c : std_logic_vector(ADC_WIDTH - 1 downto 0) := (others => '0');
	signal sample_count, sample_count_c : std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
	signal count, count_c : integer := 0;
begin

	parse_process : process (state, din, in_empty, adc_full, sample_full, adc_buffer, count) is
	begin
		next_state <= state;
		adc_buffer_c <= adc_buffer;
		sample_count_c <= sample_count;
		count_c <= count;
		in_rd_en <= '0';
		adc_wr_en <= '0';
		sample_wr_en <= '0';
		dout <= (others => '0');

		case(state) is 
			when init =>
				next_state <= init;
				if (in_empty = '0' and adc_full = '0' and sample_full = '0') then
					in_rd_en <= '1';
					adc_buffer_c <= din;
					sample_count_c <= unsigned(sample_count) + 1;
					next_state <= exec;
				end if;

			when exec =>
				next_state <= exec;
				if (in_empty = '0' and adc_full = '0' and sample_full = '0') then
					adc_wr_en <= '1';
					sample_wr_en <= '1';
					count_c <= count + 1;
					sample_count_c <= unsigned(sample_count) + 1;
					sample_dout <= sample_count;
					if (count = 0) then
						in_rd_en <= '1';
						adc_buffer_c <= din;
					elsif (count = 1) then
						adc_dout(7 downto 0) <= adc_buffer(7 downto 0);
						adc_dout(11 downto 8) <= adc_buffer(11 downto 8);
					elsif (count = 2) then
						adc_dout(7 downto 0) <= adc_buffer(23 downto 16);
						adc_dout(11 downto 8) <= adc_buffer(15 downto 12);
						count_c <= 0;
					end if;
				end if;

			when others =>
				next_state <= init;

		end case;
	end process;

	clock_process : process (clk, reset)
	begin
		if (reset = '1') then
			state <= init;
			adc_buffer <= (others => (others => '0'));
			sample_count <= (others => '0');
		elsif (rising_edge(clk)) then
			state <= next_state;
			adc_buffer <= adc_buffer_c;
			sample_count <= sample_count_c;
		end if;
	end process;

end architecture;

