library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is
	
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

	constant EXPECTED_PEAK : std_logic_vector := "00";
	constant EARLY_PEAK : std_logic_vector := "01";
	constant LATE_PEAK : std_logic_vector := "10";

	type qrs_state is (idle, init, detect, max, min, unexpected, peak, early, remove, late, expect, full);
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

end package;
