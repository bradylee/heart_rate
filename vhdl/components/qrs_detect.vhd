library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity qrs_detect is
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
		sample_average : out std_logic_vector(SAMPLE_WIDTH - 1 downto 0);
	);
end entity;

architecture behavioral of qrs_detect is
	signal state, next_state : qrs_state := init;
	signal return_state, return_state_c : qrs_state := init;
	signal maxs_adc, maxs_adc_c : adc_array(PEAK_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
	signal maxs_sample, maxs_sample_c : sample_array(PEAK_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
	signal mins_adc, mins_adc_c : adc_array(PEAK_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
	signal mins_sample, mins_sample_c : sample_array(PEAK_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
	signal window_adc, window_adc_c : sample_array(WIN_SIZE - 1 downto 0) := (others => (others => '0')); 
	signal window_sample, window_sample_c : sample_array(WIN_SIZE - 1 downto 0) := (others => (others => '0')); 
	signal rcount, rcount_c : natural := 0;
	signal expected_peak, expected_peak_c : std_logic_vector(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
	signal prev_expected_peak, prev_expected_peak_c : std_logic_vector(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
	signal possible_peak, possible_peak_c : std_logic_vector(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
	signal found_max, found_max_c : std_logic := '0';
	signal found_min, found_min_c : std_logic := '1'; -- need to pretend found min else loop infinitely
	signal early_event, early_event_c : std_logic := '0';
	signal remove_event, remove_event_c : std_logic := '0';
	signal cycle_count, cycle_count_c : natural := 0;
	signal unexpected_flags, unexpected_flags_c : unexpected_array(ALERT_COUNT - 1 downto 0) := (others => (others => '0'));
	signal sample_sum, sample_sum_c : std_logic_vector(DOUBLE_SAMPLE_WIDTH - 1 downto 0) := (others => '0');
	signal quotient, quotient_c : std_logic_vector(DOUBLE_SAMPLE_WIDTH - 1 downto 0) := (others => '0'); 
	signal rpeak_buff, rpeak_buff_c : sample_array(RPEAK_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
	signal early_buff, early_buff_c : sample_array(UNEXPECT_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
	signal removed_buff, removed_buff_c : sample_array(UNEXPECT_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
	signal late_buff, late_buff_c : sample_array(UNEXPECT_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
	signal added_buff, added_buff_c : sample_array(UNEXPECT_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
	signal rpeak_index, rpeak_index_c : natural := 0;
	signal early_index, early_index_c : natural := 0;
	signal removed_index, removed_index_c : natural := 0;
	signal late_index, late_index_c : natural := 0;
	signal added_index, added_index_c : natural := 0;
	signal rpeak_buff_full : std_logic := '0';
	signal early_buff_full : std_logic := '0';
	signal removed_buff_full : std_logic := '0';
	signal late_buff_full : std_logic := '0';
	signal added_buff_full : std_logic := '0';
	signal rpeak_o, early_o, removed_o, late_o, added_o : std_logic_vector(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
	signal alert_o : std_logic := '0';
	--signal adc_average, adc_average_c : std_logic_vector(DOUBLE_ADC_WIDTH - 1 downto 0);
	signal sample_average_o, sample_average_c : std_logic_vector(DOUBLE_SAMPLE_WIDTH - 1 downto 0);
begin

	signal_process : process (state, adc_din, sample_din, adc_empty, sample_empty, cycle_count, window_adc, window_sample, maxs_adc, maxs_sample, mins_adc, mins_sample, found_min, found_max, rcount, possible_peak, expected_peak, prev_expected_peak, early_event, remove_event, cycle_count, adc_average, unexpected_flags, rpeak_full, early_full, removed_full, late_full, added_full, rpeak_index, early_index, removed_index, late_index, added_index, return_state, rpeak_o, early_o, removed_o, late_o, added_o, alert_o, sample_average_o)

		variable lfwd, lrev, rfwd, rrev : std_logic := '0';
		variable is_candidate, is_possible, is_probable : std_logic := '0';
		variable is_possible_left, is_possible_right : std_logic := '0';
		variable curr_max, prev_max, next_max, prev_min, next_min := std_logic_vector(DOUBLE_ADC_WIDTH - 1 downto 0);
		variable curr_diff, prev_diff, next_diff := std_logic_vector(DOUBLE_ADC_WIDTH - 1 downto 0);
		variable expect_diff, prev_expect_diff := std_logic_vector(DOUBLE_ADC_WIDTH - 1 downto 0);
		variable possible_diff := std_logic_vector(DOUBLE_ADC_WIDTH - 1 downto 0);
		variable rcount_v : natural := 0;
		variable is_unexpected : std_logic := '0';
		variable rpeak_buff_v : sample_array(RPEAK_BUFF_SIZE - 1 downto 0) := (others => (others => '0'));
		variable adc_average_v : std_logic_vector(DOUBLE_ADC_WIDTH - 1 downto 0);
		variable sample_average_v : std_logic_vector(DOUBLE_SAMPLE_WIDTH - 1 downto 0);
		variable div_temp : integer := 0;

	begin

		-- clocked
		next_state <= state;
		return_state_c <= return_state;
		maxs_adc_c <= maxs_adc;
		maxs_sample_c <= maxs_sample;
		mins_adc_c <= mins_adc;
		mins_sample_c <= mins_sample;
		window_adc_c <= window_adc;
		window_sample_c <= window_sample;
		rcount_c <= rcount;
		expected_peak_c <= expected_peak;
		prev_expected_peak_c <= prev_expected_peak;
		possible_peak_c <= possible_peak;
		found_min_c <= found_min;
		found_max_c <= found_max;
		early_event_c <= early_event;
		remove_event_c <= remove_event;
		cycle_count_c <= cycle_count;
		adc_average_c <= adc_average;
		unexpected_flags_c <= unexpected_flags;
		rpeak_buff_c <= rpeak_buff; 
		early_buff_c <= early_buff;
		removed_buff_c <= removed_buff;
		late_buff_c <= late_buff;
		added_buff_c <= added_buff;
		rpeak_index_c <= rpeak_index;
		early_index_c <= early_index;
		removed_index_c <= removed_index;
		late_index_c <= late_index;
		added_index_c <= added_index;
		rpeak_c <= rpeak_o;
		early_c <= early_o;
		removed_c <= removed_o;
		late_c <= late_o;
		added_c <= added_o;
		alert_c <= '0'; -- only hold for 1 cycle
		sample_average_c <= sample_average_o;

		-- async
		adc_rd_en <= '0';
		sample_rd_en <= '0';
		rpeak_wr_en <= '0'; 
		early_wr_en <= '0';
		added_wr_en <= '0'; 
		late_wr_en <= '0'; 
		removed_wr_en <= '0'; 
		rpeak_buff_full <= '0';
		early_buff_full <= '0';
		removed_buff_full <= '0';
		late_buff_full <= '0';
		added_buff_full <= '0';

		-- variables
		lfwd := '0';
		lrev := '0';
		rfwd := '0';
		rrev := '0';
		is_candidate := '0';
		is_possible_left := '0';
		is_possible_right := '0';
		is_possible := '0';
		is_probable := '0';
		curr_max := (others => '0');
		prev_max := (others => '0');
		next_max := (others => '0');
		prev_min := (others => '0');
		next_min := (others => '0');
		curr_diff := (others => '0');
		prev_diff := (others => '0');
		next_diff := (others => '0');
		expect_diff := (others => '0');
		prev_expect_diff := (others => '0');
		possible_diff := (others => '0');
		is_unexpected := '0';
		rcount_v := 0;
		rpeak_buff_v := (others => (others => '0'));

		if (rpeak_index = UNEXPECT_BUFF_SIZE - 1) then
			rpeak_buff_full <= '1';
		end if;
		if (early_index = UNEXPECT_BUFF_SIZE - 1) then
			early_buff_full <= '1';
		end if;
		if (removed_index = UNEXPECT_BUFF_SIZE - 1) then
			removed_buff_full <= '1';
		end if;
		if (late_index = UNEXPECT_BUFF_SIZE - 1) then
			late_buff_full <= '1';
		end if;
		if (added_index = UNEXPECT_BUFF_SIZE - 1) then
			added_buff_full <= '1';
		end if;

		case(state) is
			when idle =>
				if (adc_empty = '0' and sample_empty = '0') then
					next_state <= init;
					cycle_count_c <= 0;
				else
					next_state <= idle;
				end if;

			when init =>
				if (cycle_count = WIN_SIZE) then
					next_state <= detect;
				elsif (adc_empty = '0' and sample_empty = '0') then
					adc_rd_en <= '1';
					sample_rd_en <= '1';
					SHIFT_ADC_BUFF(window_adc, adc_din, window_adc_c);
					SHIFT_SAMPLE_BUFF(window_sample, sample_din, window_sample_c);
					cycle_count_c <= cycle_count + 1;
				else
					next_state <= init;
				end if;

			when detect =>
				lrev := '1';
				lfwd := '1';
				rrev := '1';
				rfwd := '1';

				for ii in 0 to MID_WIN - 1 loop
					if unsigned(window_adc(MID_WIN)) > unsigned(window_adc(ii)) then
						lrev := '0';
					elsif unsigned(window_adc(MID_WIN) < unsigned(window_adc(ii)) then
						lfwd := '0';
					end if;
					if unsigned(window_adc(MID_WIN)) > unsigned(window_adc(WIN_SIZE - ii - 1)) then
						rfwd := '0';
					elsif unsigned(window_adc(MID_WIN)) < unsigned(window_adc(WIN_SIZE - ii - 1)) then
						rrev := '0';
					end if;
				end loop;

				if (lfwd = '1' and rrev = '1') then
					next_state <= max;
				elsif (lrev = '1' and rfwd = '1') then
					next_state <= min;
				elsif (adc_empty = '0' and sample_empty = '0') then
					adc_rd_en <= '1';
					sample_rd_en <= '1';
					SHIFT_ADC_BUFF(window_adc, adc_din, window_adc_c);
					SHIFT_SAMPLE_BUFF(window_sample, sample_din, window_sample_c);
				else
					next_state <= detect;
				end if;

			when max =>
				next_state <= detect;
				if (found_min = '1') then
					-- new max
					SHIFT_ADC_BUFF(maxs_adc, window_adc(MID_WIN), maxs_adc_c);
					SHIFT_SAMPLE_BUFF(maxs_sample, window_sample(MID_WIN), maxs_sample_c);
					found_min_c <= '0';
					found_max_c <= '1';

					curr_max := maxs_adc(MID_PEAK_BUFF);

					is_candidate := '1';
					for ii in 0 to PEAK_BUFF_SIZE loop
						if unsigned(curr_max) < unsigned(maxs_adc(ii)) then
							is_candidate := '0';
						end if;
					end loop;

					if (is_candidate = '1') then
						prev_max := maxs_adc(MID_PEAK_BUFF - 1);
						next_max := maxs_adc(MID_PEAK_BUFF + 1);
						prev_min := mins_adc(MID_PEAK_BUFF);
						next_min := mins_adc(MID_PEAK_BUFF + 1);

						-- curdiff = (2 * curmax - prevmin - nextmin) / 2
						curr_diff := std_logic_vector(shift_right(shift_left(unsigned(curr_max), 1) - unsigned(prev_min) - unsigned(next_min), 1));

						if (unsigned(curr_diff) >= VTOL) then
							prev_diff := std_logic_vector(unsigned(prev_max) - unsigned(prev_min));
							prev_diff := std_logic_vector(shift_left(unsigned(prev_diff), VSCALE_SHIFT));
							next_diff := std_logic_vector(unsigned(next_max) - unsigned(next_min));
							next_diff := std_logic_vector(shift_left(unsigned(next_diff), VSCALE_SHIFT));
							is_possible_left := '0';
							is_possible_right := '0';
							is_possible := '0';
							is_probable := '0';

							if (unsigned(curr_diff) >= prev_diff) then
								is_possible_left := '1';
							else
								is_possible_left := '0';
							end if;

							if (unsigned(curr_diff) >= next_diff) then
								is_possible_right := '1';
							else
								is_possible_right := '0';
							end if;

							if (is_possible_left = '1' or is_possible_right = '1') then
								is_possible := '1';
								if (is_possible_left = '1' and is_possible_right = '1') then
									is_probable := '1';
								end if;
							end if;

							if (is_possible = '1') then
								possible_peak_c <= maxs_sample(MID_PEAK_BUFF);
							end if;

							if (is_probable = '1') then
								next_state <= unexpected;
								new_peak_c <= maxs_sample(MID_PEAK_BUFF);
							else
								next_state <= detect;
							end if;
						end if;
					end if;

				elsif (unsigned(window_adc(MID_WIN)) > unsigned(maxs_adc(0))) then
					-- replace current max
					maxs_adc_c(0) <= window_adc(MID_WIN);
					maxs_sample_c(0) <= window_sample(MID_WIN);
				else
					next_state <= detect;
				end if;

			when min =>
				next_state <= detect;
				if (found_min = '1') then
					-- new max
					SHIFT_ADC_BUFF(mins_adc, window_adc(MID_WIN), mins_adc_c);
					SHIFT_SAMPLE_BUFF(mins_sample, window_sample(MID_WIN), mins_sample_c);
					found_min_c <= '0';
					found_max_c <= '1';
				elsif (unsigned(window_adc(MID_WIN)) < unsigned(mins_adc(0))) then
					-- replace current max
					mins_adc_c(0) <= window_adc(MID_WIN);
					mins_sample_c(0) <= window_sample(MID_WIN);
				else
					next_state <= detect;
				end if;
			
			when unexpected =>
					is_unexpected := '1';
					if (early_event = '0' and unexpected_flags(0) /= "00") then
						for ii in 1 to ALERT_COUNT - 1 loop
							if (unexpected_flags(ii-1) /= unexpected_flags(ii)) then 
								is_unexpected := '0';
							end if;
						end loop;
					end if;

					if (is_unexpected = '1') then
						rcount_v := ALERT_COUNT;
						rcount_c <= rcount_v;
						--adc_average_v := std_logic_vector(shift_right(unsigned(rpeak_buff(0)) + unsigned(rpeak_buff(1)), 1));
						sample_average_c <= unsigned(rpeak_buff(1)) - unsigned(rpeak_buff(0));
						alert_c <= '1';
						unexpected_flags_c <= (others => others => '0');
					end if;

					next_state <= peak;

			when peak =>
				rcount_v := rcount + 1;
				rcount_c <= rcount_v;

				if (unsigned(rcount) >= 2) then
					expect_diff := std_logic_vector(signed(new_peak) - signed(expected_peak));
					prev_expect_diff := std_logic_vector(signed(new_peak) - signed(prev_expected_peak));

					early_event_c <= '0';
					next_state <= full;

					if (early_event = '1' and abs(signed(prev_expect_diff)) <= TTOL) then 
						return_state <= remove;
					elsif (abs(signed(expect_diff)) > TTOL) then 
						if (signed(expect_diff) > 0) then
							return_state <= late;
						else
							return_state <= early;
						end if;
					else
						SHIFT_UNEXPECT_BUFF(unexpected_flags, EXPECTED_PEAK, unexpected_flags_c);
						return_state <= expect;
					end if;
				else
					next_state <= detect;
				end if;

			when early =>
				early_event_c <= '1';
				SHIFT_SAMPLE_BUFF(early_buff, new_peak, early_buff_c);
				SHIFT_UNEXPECT_BUFF(unexpected_flags, EARLY_PEAK, unexpected_flags_c);
				next_state <= expect;

			when remove =>
				remove_event_c <= '1';
				SHIFT_SAMPLE_BUFF(removed_buff, early_buff(0), removed_buff_c);
				SHIFT_UNEXPECT_BUFF(unexpected_flags, EXPECTED_PEAK, unexpected_flags_c);
				next_state <= expect;

			when late =>
				SHIFT_SAMPLE_BUFF(late_buff, new_peak, late_buff_c);
				possible_diff := std_logic_vector(signed(new_peak) - signed(possible_peak));
				if (abs(signed(possible_diff)) <= TTOL) then
					-- insert new peak
					SHIFT_SAMPLE_BUFF(added_buff, possible_peak, added_buff_c);
					VSHIFT_SAMPLE_BUFF(rpeak_buff, possible_peak, rpeak_buff_v);
					rpeak_buff_v(0) := rpeak_buff_v(1);
					rpeak_buff_v(1) := possible_peak;
					rpeak_buff_c <= rpeak_buff_v;
				end if;
				next_state <= expect;

			when expect =>
				sample_sum_c <= unsigned(sample_average) * (rcount - 1) + unsigned(rpeak_buff(0));

			when divide =>
				-- dividend is sum
				-- divisor is rcount

				if (rcount = 1) then
					quotient_c <= sample_sum;
					sample_sum_c <= (others => '0');
				end if;

				next_state <= divide;
				if (unsigned(sample_sum) >= rcount) then
					div_temp := GET_MSB(sample_sum) - GET_MSB(rcount);
					if ((rcount sll div_temp) > unsigned(sample_sum)) then
						div_temp := div_temp - 1;
					end if;
					quotient_c <= quotient + (to_signed(1, DOUBLE_SAMPLE_WIDTH) sll div_temp);
					sample_sum_c <= unsigned(sample_sum) - (rcount sll div_temp);
				else
					sample_averge_c <= quotient;
					next_state <= detect;
				end if;
			
			when full =>
				-- rpeak buffer can be modified and must maintain a minimum number of elements until the end
				if (rpeak_full = '0' and rpeak_index >= RPEAK_HISTORY) then
					rpeak_wr_en = '1';
					rpeak <= rpeak_buff(rpeak_index);
				end if;

				if (early_full = '0') then
					early_wr_en = '1';
					early <= early_buff(early_index);
				end if;

				if (removed_full = '0') then
					removed_wr_en = '1';
					removed <= removed_buff(removed_index);
				end if;

				if (late_full = '0') then
					late_wr_en = '1';
					late <= late_buff(late_index);
				end if;

				if (added_full = '0') then
					added_wr_en = '1';
					added <= added_buff(added_index);
				end if;

				if (rpeak_buff_full = '1' or empty_buff_full = '1' or removed_buff_full = '1' or late_buff_full = '1' or added_buff_full = '1') then
					next_state <= full;
				else
					next_state <= return_state;
				end if;

			when others =>
				next_state <= idle;

		end case;
	end process;

	clock_process : process (clk, reset)
	begin
		if (reset = '1') then
			state <= init;
			return_state <= init;
			maxs_adc <= (others => (others => '0'));
			maxs_sample <= (others => (others => '0'));
			mins_adc <= (others => (others => '0'));
			mins_sample <= (others => (others => '0'));
			window_adc <= (others => (others => '0')); 
			window_sample <= (others => (others => '0')); 
			rcount <= 0;
			expected_peak <= (others => '0');
			prev_expected_peak <= (others => '0');
			possible_peak <= (others => '0');
			found_max <= '0';
			found_min <= '1';
			early_event <= '0';
			remove_event <= '0';
			cycle_count <= 0;
			--adc_average <= (others => '0'); 
			sample_average_o <= (others => '0');
			unexpected_flags <= (others => (others => '0'));
			sample_sum <= (others => '0');
			quotient <= (others => '0');
			rpeak_buff <= (others => (others => '0'));
			early_buff <= (others => (others => '0'));
			removed_buff <= (others => (others => '0'));
			late_buff <= (others => (others => '0'));
			added_buff <= (others => (others => '0'));
			rpeak_o <= (others => '0'); 
			early_o <= (others => '0'); 
			removed_o <= (others => '0');  
			late_o <= (others => '0');  
			added_o <= (others => '0');  
			alert_o <= '0'; 
		elsif (rising_edge(clk)) then
			state <= next_state;
			return_state <= return_state_c;
			maxs_adc <= maxs_adc_c;
			maxs_sample <= maxs_sample_c;
			mins_adc <= mins_adc_c;
			mins_sample <= mins_sample_c;
			window_adc <= window_adc_c;
			window_sample <= window_sample_c;
			rcount <= rcount_c;
			expected_peak <= expected_peak_c;
			prev_expected_peak <= prev_expected_peak_c;
			possible_peak <= prev_possible_peak_c;
			found_max <= found_max_c;
			found_min <= found_min_c;
			early_event <= early_event_c; 
			remove_event <= remove_event_c; 
			cycle_count <= cycle_count_c;
			--adc_average <= adc_average_c;
			sample_average_o <= sample_average_c;
			unexpected_flags <= unexpected_flags_c;
			sample_sum <= sample_sum_c;
			quotient <= quotient_c; 
			rpeak_buff <= rpeak_buff_c; 
			early_buff <= early_buff_c;
			removed_buff <= removed_buff_c;
			late_buff <= late_buff_c;
			added_buff <= added_buff_c;
			rpeak_index <= rpeak_index_c;
			early_index <= early_index_c;
			removed_index <= removed_index;
			late_index <= late_index_c;
			added_index <= added_index_c;
			rpeak_o <= rpeak_c; 
			early_o <= early_c;
			removed_o <= removed_c;
			late_o <= late_c;
			added_o <= added_c;
			alert_o <= alert_c;
		end if;
	end process;

	rpeak_dout <= rpeak_o; 
	early_dout <= early_o;
	removed_dout <= removed_o;
	late_dout <= late_o;
	added_dout <= added_o;
	alert <= alert_o;
	sample_average <= sample_average_o(SAMPLE_WIDTH - 1 downto 0);

end architecture;
