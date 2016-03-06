SAMPLES = 10000;
WIN_SIZE = 10; % milliseconds
SCALE = 2;
TOL = 0.2; % millivolts

[tstamps, signal, fs] = rdsamp('mitdb/101', 1, SAMPLES);
tstamps = tstamps';
signal = signal';

window = signal(1:round(fs * WIN_SIZE / 1000));
maxs = -inf(2, 3);
mins = inf(2, 3);
% preallocate for 2 beats per second
rpeaks = zeros(2, round(tstamps(end)) * 2);
rcount = 0;

close all;
figure; hold on;
plot(tstamps, signal);

midwin = round(length(window)/2);
midmax = round(length(maxs)/2);
midmin = round(length(maxs)/2);

found_min = 1;
found_max = 0;

for ii = length(window):length(signal)
	window = shift(window, signal(ii));
	point = [window(midwin), tstamps(ii - midwin)];

	[lfwd, lrev] = is_sorted(window(1:midwin)); % left
	[rfwd, rrev] = is_sorted(window(midwin:end)); % right

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
			curmin = mins(1, midmin);
			if ~isinf(curmax) && all(curmax >= maxs(1, :)) 
				curdif = curmax - curmin;
				prevdif = prevmax - curmin;
				if curdif >= TOL && curdif >= SCALE * prevdif
					rcount = rcount + 1;
					%plot(maxs(2, midmax), maxs(1, midmax), 'ro');
					rpeaks(:, rcount) = maxs(:, midmax);
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
	disp(rcount);
else
	rpeaks = [];
end

%plot(maxs(2, :), maxs(1, :), 'go');
%plot(mins(2, :), mins(1, :), 'yo');
