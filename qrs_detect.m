% expected peaks
% coalescing peaks

function [rpeaks, miss_count] = qrs_detect(signal, tstamps, fs, vtol, ttol, vscale, win_size, miss_alarm)

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

close all;
figure; hold on;
plot(tstamps, signal);

midwin = round(length(window)/2);
midmax = round(length(maxs)/2);
midmin = round(length(maxs)/2);

found_min = 1;
found_max = 0;

expected_peak = [0; 0];
miss_count = 0;
running_miss = 0;

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
		if found_min
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
				% is candidate for r peak
				curdif = (2 * curmax - prevmin - nextmin) / 2;
				%lcurdif = curmax - prevmin;
				%rcurdif = curmax - nextmin;
				prevdif = prevmax - prevmin;
				nextdif = nextmax - nextmin;
				if curdif >= vtol && all(curdif >= vscale * [prevdif, nextdif])
				%if curdif >= vtol && lcurdif >= vscale * prevdif && rcurdif >= vscale * nextdif
					rcount = rcount + 1;
					new_peak = maxs(:, midmax);
					rpeaks(:, rcount) = new_peak;
					if rcount > 1
						if rcount > 2
							new_time = new_peak(2, 1);
							expected_time = expected_peak(2, 1);
							tdif = new_time - expected_time;
							if abs(tdif) >= ttol
								if tdif > 0
									fprintf('Late beat ');
								else
									fprintf('Early beat ');
								end
								fprintf('at %f, expected %f\n', new_time, expected_time);
								miss_count = miss_count + 1;
								running_miss = running_miss + 1;
								if running_miss >= miss_alarm
									fprintf('ALARM!!!\n');
								end
								plot(expected_time, expected_peak(1, 1), 'k*');
							end
						end
						avg_volt = mean(rpeaks(1, 1:rcount));
						avg_diff = mean(diff(rpeaks(2, 1:rcount)));
						expected_peak = [avg_volt; avg_diff + rpeaks(2, rcount)];
						plot(expected_peak(2), expected_peak(1), 'm*');
					end
				end
			end

		elseif point(1) > maxs(1, 1)
			% replace existing max with greater one
			maxs(:, 1) = point;
		end
	elseif lrev && rfwd
		if found_max
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
else
	rpeaks = [];
end

%plot(maxs(2, :), maxs(1, :), 'go');
%plot(mins(2, :), mins(1, :), 'yo');
end
