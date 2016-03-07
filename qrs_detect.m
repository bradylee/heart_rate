% TO DO:
% double checking misses 

function [rpeaks, late_beats, early_beats, discarded_beats] = qrs_detect(signal, tstamps, fs, vtol, ttol, vscale, win_size, unexpected_alarm, patient)

% signal: 
% tstamps:
% fs:
% vtol : tolerance allowed to help differentiate R peaks from other peaks (millivolts)
% ttol : tolerance allowed before considering a beat missed (milliseconds)
% vscale: 
% win_size : (milliseconds)

if size(signal, 1) > size(signal,2)
	signal = signal';
	tstamps = tstamps';
end

win_len = max(3, round(fs * win_size / 1000));
window = signal(1:win_len);
maxs = -inf(2, 3);
mins = inf(2, 3);
% preallocate for 2 beats per second
rpeaks = zeros(2, round(tstamps(end)) * 2);
rcount = 0;

ttol = ttol / 1000;

%close all;
figure; hold on;
plot(tstamps, signal);

midwin = round(length(window)/2);
midmax = round(length(maxs)/2);
midmin = round(length(maxs)/2);

found_min = 1;
found_max = 0;

expected_peak = [0; 0];
prev_expected = [0; 0];
avg_volt = 0;
avg_diff = 0;
rindex = 1;
curr_count = 0;

early_beats = zeros(2, 10);
late_beats = zeros(2, 10);
discarded_beats = zeros(2, 10);

early_count = 0;
late_count = 0;
discarded_count = 0;
unexpected_count = 0;
unexpected_running = 0;
unexpected_flags = [0, 0];

early_event = 0;
late_event = 0;

for ii = length(window):length(signal)
	window = shift(window, signal(ii));
	point = [window(midwin), tstamps(ii - midwin)];

	left = window(1:midwin);
	right = window(midwin:end);
	[lfwd, lrev] = is_sorted(left);
	[rfwd, rrev] = is_sorted(right);

	% check for mins and maxes
	% force alternation but check for improved and replace as needed

	if lfwd && rrev
		% candidate maximum
		if found_min
			% valid maximum
			[maxs, out] = shift(maxs, point);
			plot(out(2), out(1), 'go');
			found_min = 0;
			found_max = 1;

			% check for new R peak
			curmax = maxs(1, midmax);
			prevmax = maxs(1, midmax - 1);
			nextmax = maxs(1, midmax + 1);
			prevmin = mins(1, midmin);
			nextmin = mins(1, midmin + 1);

			if ~isinf(curmax) && all(curmax >= maxs(1, :)) 
				% is candidate for R peak
				curdif = (2 * curmax - prevmin - nextmin) / 2;
				prevdif = prevmax - prevmin;
				nextdif = nextmax - nextmin;

				if curdif >= vtol && all(curdif >= vscale * [prevdif, nextdif])
					% is considered an R peak
					rcount = rcount + 1;
					curr_count = curr_count + 1;
					new_peak = maxs(:, midmax);
					rpeaks(:, rcount) = new_peak;
					
					if rcount > 1
						expecting = 1;
						if curr_count > 2
							new_time = new_peak(2, 1);
							expected_time = expected_peak(2, 1);
							prev_time = prev_expected(2, 1);
							texp = new_time - expected_time;
							tprev = new_time - prev_time;

							if early_event && abs(tprev) <= ttol %&& 0
								% beat is previously expected beat
								% discard early beat and update peaks
								early_event = 0;
								discarded_count = discarded_count + 1;
								discarded = early_beats(:, early_count);
								discarded_beats(:, discarded_count) = discarded; 
								fprintf('Discarded beat %f\n', discarded(2, 1)); 
								plot(expected_peak(2), expected_peak(1), 'kx', 'markers', 11);
								%early_beats = early_beats - 1;
								start = rcount-5;
								term = rcount;
								disp(rpeaks(:, start:term));
								rcount = rcount - 1;
								rpeaks(:, rcount) = new_peak;
								disp(rpeaks(:, start:term));
								unexpected_flags = shift(unexpected_flags, 0);
							elseif abs(texp) > ttol
								% missed or unexpected beat
								early_event = 0;
								late_event = 0;
								if texp > 0
									late_count = late_count + 1;
									late_beats(:, late_count) = new_peak;
									fprintf('Late beat ');
									late_event = 1;
									unexpected_flags = shift(unexpected_flags, 2);
								else
									early_count = early_count + 1;
									early_beats(:, early_count) = new_peak;
									fprintf('Early beat ');
									early_event = 1;
									unexpected_flags = shift(unexpected_flags, 1);
								end
								fprintf('at %f, expected %f\n', new_time, expected_time);
								unexpected_count = unexpected_count + 1;
								if all(unexpected_flags(1) == unexpected_flags)
									% same kind of unexpected beat in a row
									unexpected_running = unexpected_running + 1;
								else
									unexpected_running = 0;
								end

								if unexpected_running >= unexpected_alarm
									% reset streak, assuming new heart rate (need to clear averages)
									fprintf('Unexpected change in beating!\n');
									curr_count = 1;
									rindex = rcount;
									avg_volt = 0;
									avg_diff = 0;
									unexpected_running = 0;
									expecting = 0;
								end
							else
								unexpected_running = 0;
								unexpected_flags = shift(unexpected_flags, 0);
							end
						end
						avg_volt = mean(rpeaks(1, rindex:rcount));
						avg_diff = mean(diff(rpeaks(2, rindex:rcount)));
						if expecting
							prev_expected = expected_peak;
							expected_peak = [avg_volt; avg_diff + rpeaks(2, rcount)];
							plot(expected_peak(2), expected_peak(1), 'm*');
						else
							curr_count = 1;
							rindex = rcount;
							avg_volt = 0;
							avg_diff = 0;
							unexpected_running = 0;
							prev_expected = [0; 0];
						end
					end
				end
			end

		elseif point(1) > maxs(1, 1)
			% replace existing max with greater one
			maxs(:, 1) = point;
		end
	elseif lrev && rfwd
		% candidate minimum
		if found_max
			% valid minimum
			[mins, out] = shift(mins, point);
			plot(out(2), out(1), 'yo');
			found_min = 1;
			found_max = 0;
		elseif point(1) < mins(1, 1)
			% replace existing min with lesser one
			mins(:, 1) = point;
		end
	end
end


if rcount > 0
	rpeaks = rpeaks(:, 1:rcount);
	plot(rpeaks(2, :), rpeaks(1, :), 'ro');

	if early_count > 0
		early_beats = early_beats(:, 1:early_count);
		plot(early_beats(2, :), early_beats(1, :), 'c*');
	end
	if late_count > 0
		late_beats = late_beats(:, 1:late_count);
		plot(late_beats(2, :), late_beats(1, :), '*', 'Color', [1, 0.5, 0.5]);
	end
	if discarded_count > 0
		discarded_beats = discarded_beats(:, 1:discarded_count);
		plot(discarded_beats(2, :), discarded_beats(1, :), 'kx', 'markers', 11);
	end
else
	rpeaks = [];
	unexpected_beats = [];
end


xlabel('Time (s)');
ylabel('Voltage (mv)');
t = sprintf('Electrocardiogram Analysis %s', patient);
title(t);

end
