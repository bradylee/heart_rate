library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity hrv_top is
	port
	(
		clk : in std_logic;
		reset : in std_logic;
		din : in std_logic_vector(COMPRESSED_WIDTH - 1 downto 0);
		wr_en : in std_logic;
		full : out std_logic;
		rpeak : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
		early : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
		removed : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
		late : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
		added : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
		alert : out std_logic;
		sample_average : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0)
	);
end entity;

architecture behavioral of hrv_top is
	signal input_dout : std_logic_vector := (others => '0');
	signal input_rd_en : std_logic := '0';
	signal input_empty : std_logic := '0';
	signal parsed_din, parsed : std_logic_vector := (others => '0');
	signal parsed_rd_en, parsed_wr_en : std_logic := '0';
	signal parsed_empty, parsed_full : std_logic := '0';
	signal sample_din, sample : std_logic_vector := (others => '0');
	signal sample_rd_en, sample_wr_en : std_logic := '0';
	signal sample_empty, sample_full : std_logic := '0';
	signal rpeak_din, rpeak : std_logic_vector := (others => '0');
	signal rpeak_rd_en, rpeak_wr_en : std_logic := '0';
	signal rpeak_empty, rpeak_full : std_logic := '0';
	signal early_din, early : std_logic_vector := (others => '0');
	signal early_rd_en, early_wr_en : std_logic := '0';
	signal early_empty, early_full : std_logic := '0';
	signal removed_din, removed : std_logic_vector := (others => '0');
	signal removed_rd_en, removed_wr_en : std_logic := '0';
	signal removed_empty, removed_full : std_logic := '0';
	signal late_din, late : std_logic_vector := (others => '0');
	signal late_rd_en, late_wr_en : std_logic := '0';
	signal late_empty, late_full : std_logic := '0';
	signal added_din, added : std_logic_vector := (others => '0');
	signal added_rd_en, added_wr_en : std_logic := '0';
	signal added_empty, added_full : std_logic := '0';
begin

	negative_clock : process(clk)
	begin
		if (rising_edge(clk)) then
			n_clk <= '0';
		elsif (falling_edge(clk)) then
			n_clk <= '1';
		end if;
	end process;

	input_buffer : fifo
	generic map
	(
		DWIDTH => COMPRESSED_WIDTH,
		BUFFER_SIZE => FIFO_SIZE
	),
	port map
	(
		rd_clk => n_clk,
		wr_clk => n_clk,
		reset => reset,
		rd_en => input_rd_en,
		wr_en => wr_en,
		din => din,
		dout => input_dout,
		full => full,
		empty => input_empty 
	);

	_adc_parse : adc_parse
	port map
	(
		clk => clk,
		reset => reset,
		din => input_dout,
		in_empty => input_empty,
		adc_full => parsed_full,
		sample_full => sample_full,
		in_rd_en => input_rd_en,
		adc_wr_en => parsed_wr_en,
		sample_wr_en => sample_wr_en,
		adc_dout => parsed_din,
		sample_dout => sample_din
	);

	parsed_buffer : fifo
	generic map
	(
		DWIDTH => COMPRESSED_WIDTH,
		BUFFER_SIZE => FIFO_SIZE
	),
	port map
	(
		rd_clk => n_clk,
		wr_clk => n_clk,
		reset => reset,
		rd_en => parsed_rd_en,
		wr_en => parsed_wr_en,
		din => parsed_din,
		dout => parsed,
		full => parsed_full,
		empty => parsed_empty 
	);

	sample_buffer : fifo
	generic map
	(
		DWIDTH => COMPRESSED_WIDTH,
		BUFFER_SIZE => FIFO_SIZE
	),
	port map
	(
		rd_clk => n_clk,
		wr_clk => n_clk,
		reset => reset,
		rd_en => sample_rd_en,
		wr_en => sample_wr_en,
		din => sample_din,
		dout => sample,
		full => sample_full,
		empty => sample_empty 
	);

	_qrs_detect : qrs_detect
	port map
	(
		clk => clk,
		reset => reset,
		adc_din => parsed,
		sample_din => sample,
		adc_empty => parsed_empty,
		sample_empty => sample_empty,
		rpeak_full => rpeak_full,
		early_full => early_full,
		removed_full => removed_full,
		late_full => late_full,
		added_full => added_full,
		adc_rd_en => parsed_rd_en,
		sample_rd_en => sample_rd_en,
		rpeak_dout => rpeak_din,
		early_dout => early_din,
		removed_dout => removed_din,
		late_dout => late_din,
		added_dout => added_din,
		rpeak_wr_en => rpeak_wr_en,
		early_wr_en => early_wr_en,
		removed_wr_en => removed_wr_en,
		late_wr_en => late_wr_en,
		added_wr_en => added_wr_en,
		alert => alert,
		sample_average => sample_average
	);

	rpeak_buffer : fifo
	generic map
	(
		DWIDTH => COMPRESSED_WIDTH,
		BUFFER_SIZE => FIFO_SIZE
	),
	port map
	(
		rd_clk => n_clk,
		wr_clk => n_clk,
		reset => reset,
		rd_en => rpeak_rd_en,
		wr_en => rpeak_wr_en,
		din => rpeak_din,
		dout => rpeak,
		full => rpeak_full,
		empty => rpeak_empty 
	);

	early_buffer : fifo
	generic map
	(
		DWIDTH => COMPRESSED_WIDTH,
		BUFFER_SIZE => FIFO_SIZE
	),
	port map
	(
		rd_clk => n_clk,
		wr_clk => n_clk,
		reset => reset,
		rd_en => early_rd_en,
		wr_en => early_wr_en,
		din => early_din,
		dout => early,
		full => early_full,
		empty => early_empty 
	);

	removed_buffer : fifo
	generic map
	(
		DWIDTH => COMPRESSED_WIDTH,
		BUFFER_SIZE => FIFO_SIZE
	),
	port map
	(
		rd_clk => n_clk,
		wr_clk => n_clk,
		reset => reset,
		rd_en => removed_rd_en,
		wr_en => removed_wr_en,
		din => removed_din,
		dout => removed,
		full => removed_full,
		empty => removed_empty 
	);

	late_buffer : fifo
	generic map
	(
		DWIDTH => COMPRESSED_WIDTH,
		BUFFER_SIZE => FIFO_SIZE
	),
	port map
	(
		rd_clk => n_clk,
		wr_clk => n_clk,
		reset => reset,
		rd_en => late_rd_en,
		wr_en => late_wr_en,
		din => late_din,
		dout => late,
		full => late_full,
		empty => late_empty 
	);

	added_buffer : fifo
	generic map
	(
		DWIDTH => COMPRESSED_WIDTH,
		BUFFER_SIZE => FIFO_SIZE
	),
	port map
	(
		rd_clk => n_clk,
		wr_clk => n_clk,
		reset => reset,
		rd_en => added_rd_en,
		wr_en => added_wr_en,
		din => added_din,
		dout => added,
		full => added_full,
		empty => added_empty 
	);
end architecture;
