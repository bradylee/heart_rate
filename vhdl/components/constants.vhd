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
	constant UNEXPECT_FLAG_SIZE : natural := 2;
	constant UNEXPECT_BUFF_SIZE : natural := 5; -- can be any size > 0
	constant RPEAK_BUFF_SIZE : natural := 10;
	constant VTOL in : integer := 0;
	constant TTOL in : integer := 0
	constant FIFO_SIZE : natural := 512;

	constant EXPECTED_PEAK : std_logic_vector := "00";
	constant EARLY_PEAK : std_logic_vector := "01";
	constant LATE_PEAK : std_logic_vector := "10";

	type qrs_state is (idle, init, detect, max, min, unexpected, peak, early, remove, late, expect, full);
	type parse_state is (init, exec);

	type adc_array is array (natural range<>) of std_logic_vector(ADC_SIZE - 1 downto 0);
	type sample_array is array (natural range<>) of std_logic_vector(SAMPLE_SIZE - 1 downto 0);
	type unexpected_array is array (natural range<>) of std_logic_vector(UNEXPECT_WIDTH - 1 downto 0);

	procedure SHIFT_ADC_BUFF 
	( src : in adc_array; 
	din : in std_logic_vector;
	dst : out adc_array; );
	begin
		dst(ADC_WIDTH - 1 downto 1) <= src(ADC_WIDTH - 2 downto 0);
		dst(0) <= din;
	end procedure;

	procedure SHIFT_SAMPLE_BUFF 
	( src : in sample_array; 
	din : in std_logic_vector;
	dst : out sample_array; );
	begin
		dst(SAMPLE_WIDTH - 1 downto 1) <= src(SAMPLE_WIDTH - 2 downto 0);
		dst(0) <= din;
	end procedure;

	procedure VSHIFT_SAMPLE_BUFF 
	( src : in sample_array; 
	din : in std_logic_vector;
	dst : out sample_array; );
	begin
		dst(SAMPLE_WIDTH - 1 downto 1) := src(SAMPLE_WIDTH - 2 downto 0);
		dst(0) <= din;
	end procedure;

	procedure SHIFT_UNEXPECT_BUFF 
	( src : in unexpected_array; 
	din : in std_logic_vector;
	dst : out unexpected_array; );
	begin
		dst(SAMPLE_WIDTH - 1 downto 1) <= src(SAMPLE_WIDTH - 2 downto 0);
		dst(0) <= din;
	end procedure;

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

end package;
