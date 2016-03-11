library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is

	constant COMPRESSED_WIDTH : natural := 24;
	constant ADC_WIDTH : natural := 12; -- 1 extra bit to indicate inf
	constant DOUBLE_ADC_WIDTH : natural := ADC_WIDTH * 2; 
	constant SAMPLE_WIDTH : natural := 32;
	constant DOUBLE_SAMPLE_WIDTH : natural := SAMPLE_WIDTH * 2;
	constant PEAK_BUFF_SIZE : natural := 3;
	constant MID_PEAK_BUFF : natural := PEAK_BUFF_SIZE / 2; -- center index
	constant WIN_SIZE : natural := 5;
	constant MID_WIN : natural := WIN_SIZE / 2;
	constant VSCALE_SHIFT : natural := 1; -- scale by 2
	constant ALERT_COUNT : natural := 2; -- must stay 2 for now
	constant UNEXPECT_WIDTH : natural := 2;
	constant UNEXPECT_FLAG_SIZE : natural := 2;
	constant UNEXPECT_BUFF_SIZE : natural := 5; -- can be any size > 0
	constant RPEAK_BUFF_SIZE : natural := 10;
	constant VTOL : integer := 1;
	constant TTOL : integer := 1;
	constant FIFO_SIZE : natural := 512;

	constant EXPECT_PEAK : std_logic_vector := "00";
	constant EARLY_PEAK : std_logic_vector := "01";
	constant LATE_PEAK : std_logic_vector := "10";

	type qrs_state is (idle, init, detect, max_peak, min_peak, unexpected, rpeak, early, remove, late, expect, divide, full);
	type parse_state is (init, exec);

	type adc_array is array (natural range<>) of std_logic_vector(ADC_WIDTH - 1 downto 0);
	type sample_array is array (natural range<>) of std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
	type unexpected_array is array (natural range<>) of std_logic_vector(UNEXPECT_WIDTH - 1 downto 0);

	procedure SHIFT_ADC_BUFF 
	( signal src : in adc_array; 
	signal din : in std_logic_vector;
	signal dst : out adc_array );

	procedure SHIFT_SAMPLE_BUFF 
	( signal src : in sample_array; 
	signal din : in std_logic_vector;
	signal dst : out sample_array );

	procedure VSHIFT_SAMPLE_BUFF 
	( signal src : in sample_array; 
	signal din : in std_logic_vector;
	variable dst : out sample_array );

	-- hardcoded as 2 length for now
	procedure SHIFT_UNEXPECT_BUFF 
	( signal src : in unexpected_array; 
	constant din : in std_logic_vector;
	signal dst : out unexpected_array );

	function GET_MSB (n : integer) return natural;
	function GET_MSB (n : std_logic_vector) return natural;
	function GET_MSB (n : unsigned) return natural;

	component adc_parse is
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
	end component;

	component qrs_detect is
		port 
		(
			clk : in std_logic;
			reset : in std_logic;
			adc_din : in std_logic_vector(ADC_WIDTH - 1 downto 0);
			sample_din : in std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
			adc_empty : in std_logic;
			sample_empty: in std_logic;
			rpeak_full : in std_logic;
			early_full : in std_logic;
			removed_full : in std_logic;
			late_full : in std_logic;
			added_full : in std_logic;
			adc_rd_en : out std_logic;
			sample_rd_en : out std_logic;
			rpeak_dout : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
			early_dout : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
			removed_dout : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
			late_dout : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
			added_dout : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
			rpeak_wr_en : out std_logic;
			early_wr_en : out std_logic;
			removed_wr_en : out std_logic;
			late_wr_en : out std_logic;
			added_wr_en : out std_logic;
			alert : out std_logic;
			sample_average : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0)
		);
	end component;
	
	component fifo is
		generic
		(
			constant DWIDTH : integer := 32;
			constant BUFFER_SIZE : integer := 32
		);
		port
		(
			signal rd_clk : in std_logic;
			signal wr_clk : in std_logic;
			signal reset : in std_logic;
			signal rd_en : in std_logic;
			signal wr_en : in std_logic;
			signal din : in std_logic_vector ((DWIDTH - 1) downto 0);
			signal dout : out std_logic_vector ((DWIDTH - 1) downto 0);
			signal full : out std_logic;
			signal empty : out std_logic
		);
	end component fifo;

end package;

package body constants is

	procedure SHIFT_ADC_BUFF 
	( signal src : in adc_array; 
	signal din : in std_logic_vector;
	signal dst : out adc_array ) is
	begin
		dst(dst'length - 1 downto 1) <= src(src'length - 2 downto 0);
		--dst(ADC_WIDTH - 1 downto 1) <= src(ADC_WIDTH - 2 downto 0);
		dst(0) <= din;
	end procedure;

	procedure SHIFT_SAMPLE_BUFF 
	( signal src : in sample_array; 
	signal din : in std_logic_vector;
	signal dst : out sample_array ) is
	begin
		dst(dst'length - 1 downto 1) <= src(src'length - 2 downto 0);
		--dst(SAMPLE_WIDTH - 1 downto 1) <= src(SAMPLE_WIDTH - 2 downto 0);
		dst(0) <= din;
	end procedure;

	procedure VSHIFT_SAMPLE_BUFF 
	( signal src : in sample_array; 
	signal din : in std_logic_vector;
	variable dst : out sample_array ) is
	begin
		dst(dst'length - 1 downto 1) := src(src'length - 2 downto 0);
		--dst(SAMPLE_WIDTH - 1 downto 1) := src(SAMPLE_WIDTH - 2 downto 0);
		dst(0) := din;
	end procedure;

	procedure SHIFT_UNEXPECT_BUFF 
	( signal src : in unexpected_array; 
	constant din : in std_logic_vector;
	signal dst : out unexpected_array ) is
	begin
		dst(1) <= src(0);
		dst(0) <= din;
	end procedure;

	function GET_MSB (n : integer) return natural is
	begin
			return GET_MSB(to_unsigned(n, 32));
	end function;

	function GET_MSB (n : std_logic_vector) return natural is
	begin
			return GET_MSB(unsigned(n));
	end function;

	function GET_MSB (n : unsigned) return natural is
	begin
			for i in n'length - 1 downto 0 loop
					if (n(i) = '1') then
							return i;
					end if;
			end loop;
			return 0;
	end function;

end package body;
