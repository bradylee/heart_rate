% TO DO:
% * fix unexpected buffer
% * reorganize to smaller functions
% * prev expected buffer - allow adding and removing to check back farther

function [rpeaks, late_beats, early_beats, added_beats, removed_beats] = qrs_detect(signal, fs, vtol, ttol, vscale, win_size, alarm_count, patient)

% signal			: array of samples (millivolts)
% //tstamps			: timestamps corresponding to samples (milliseconds)
% fs					: sampling frequency (hertz)
% vtol				: tolerance allowed to help differentiate R peaks from other peaks (millivolts)
% ttol				: tolerance allowed before considering a beat missed (milliseconds)
% vscale			: lower threshold on peak scale to separate local max from R peak (ratio)
% win_size		: subset of signal used to find local max and min (milliseconds)
% alarm_count :
% patient			:

% must be >= 3 for late beat correction
PEAK_BUFF_SIZE = 3;

if size(signal, 1) > size(signal,2)
  signal = signal';
  %tstamps = tstamps';
end

samples = 1:length(signal);
% adjust ttol to samples
ttol = max(1, ttol / 1000 * fs);

close all;
figure; hold on;
%plot(tstamps, signal);
plot(samples, signal);
xlabel('Sample');
ylabel('Voltage (mv)');
t = sprintf('Electrocardiogram Analysis %s', patient);
title(t);

% must be >= 3 samples to find peaks
win_len = max(3, round(fs * win_size / 1000));
window = signal(1:win_len);

maxs = -inf(2, PEAK_BUFF_SIZE);
mins = inf(2, PEAK_BUFF_SIZE);

midwin = round(length(window)/2);
midmax = round(length(maxs)/2);
midmin = round(length(maxs)/2);

% preallocate for 2 beats per second, faster execution
%rpeaks = zeros(2, round(tstamps(end)) * 2);
rpeaks = zeros(2, round(length(signal) * fs * 2));
rcount = 0;

rindex = 1;
curr_count = 0;

% must be >= 2 to properly adjust after change in beating
alarm_count = max(2, alarm_count);

expected_peak = [0; 0];
prev_expected_peak = [0; 0];
prev_possible_peak = [0; 0];

% track unexpected beats (early, late)
unexpected_flags = zeros(1, alarm_count);

UNEXPECTED_LENGTH = 10;
early_beats = zeros(3, UNEXPECTED_LENGTH);
late_beats = zeros(3, UNEXPECTED_LENGTH);
removed_beats = zeros(3, UNEXPECTED_LENGTH);
added_beats = zeros(3, UNEXPECTED_LENGTH);

early_count = 0;
late_count = 0;
removed_count = 0;
added_count = 0;

found_min = 1;
found_max = 0;
early_event = 0;

for ii = length(window):length(signal)
  window = shift(window, signal(ii));
  %point = [window(midwin), tstamps(ii - midwin)];
  point = [window(midwin), samples(ii - midwin)];
  
  left = window(1:midwin);
  right = window(midwin:end);
  [lfwd, lrev] = is_sorted(left);
  [rfwd, rrev] = is_sorted(right);
  
  % check for mins and maxes ...
  
  if lfwd && rrev
    % candidate maximum
    if found_min
      % valid maximum
      
      [maxs, out] = shift(maxs, point);
      % plot max removed from buffer
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
        % candidate R peak
        curdif = (2 * curmax - prevmin - nextmin) / 2;
        prevdif = prevmax - prevmin;
        nextdif = nextmax - nextmin;
        peak_check = curdif >= vscale * [prevdif, nextdif];
        
        if curdif >= vtol && any(peak_check)
          % likely R peak
          possible_peak = maxs(:, midmax);
          
          if all(peak_check)
            % definite R peak
            rcount = rcount + 1;
            curr_count = curr_count + 1;
            new_peak = possible_peak;
            rpeaks(:, rcount) = new_peak;
            
            if curr_count > 2
              % check detected value against expectation
              plot(expected_peak(2), expected_peak(1), 'm*');
              new_time = new_peak(2, 1);
              expected_time = expected_peak(2, 1);
              prev_time = prev_expected_peak(2, 1);
              tdiff_expected = new_time - expected_time;
              tdiff_prev = new_time - prev_time;
              
              if ~early_event && unexpected_flags(1) && all(unexpected_flags(1) == unexpected_flags)
                % too many unexpected beats, actual rate must have changed
                fprintf('Change in beating!\n');
                curr_count = alarm_count;
                rindex = rcount - curr_count + 1;
                unexpected_flags = zeros(size(unexpected_flags));
              end
              
              % ensure flag only lasts one iteration regardless of path
              ee = early_event;
              early_event = 0;
              
              if ee && abs(tdiff_prev) <= ttol
                % new beat is previously expected beat
                % discard early beat and update rpeaks
                removed_count = removed_count + 1;
                removed_beat = early_beats(:, early_count);
                removed_beats(:, removed_count) = removed_beat;
                rcount = rcount - 1;
                rpeaks(:, rcount) = new_peak;
                unexpected_flags = shift(unexpected_flags, 0);
                early_event = 0;
                fprintf('Removed beat at %d\n', removed_beat(2, 1));
                plot(expected_peak(2), expected_peak(1), 'kx', 'markers', 11);
              elseif abs(tdiff_expected) > ttol
                % unexpected beat
                if tdiff_expected > 0
                  % late beat
                  late_count = late_count + 1;
                  late_beats(:, late_count) = [new_peak; rcount];
                  prev_possible_time = prev_possible_peak(2, 1);
                  tdiff_possible = prev_possible_time - expected_time;
                  fprintf('Late beat at %d, expected %d\n', new_time, expected_time);
                  
                  if abs(tdiff_possible) <= ttol
                    % add beat that was skipped
                    added_count = added_count + 1;
                    added_beats(:, added_count) = [prev_possible_peak; rcount];
                    rpeaks(:, rcount + 1) = rpeaks(:, rcount);
                    rpeaks(:, rcount) = prev_possible_peak;
                    rcount = rcount + 1;
                    late_beats(3, late_count) = rcount;
                    plot(new_peak(2), new_peak(1), 'ko', 'markers', 11);
                    fprintf('Added beat at %d\n', added_beats(2, added_count));
                    unexpected_flags = shift(unexpected_flags, 0);
                  else
                    % actual late beat
                    unexpected_flags = shift(unexpected_flags, 2);
                  end
                  
                else
                  % early beat
                  early_event = 1;
                  early_count = early_count + 1;
                  early_beats(:, early_count) = [new_peak; rcount];
                  unexpected_flags = shift(unexpected_flags, 1);
                  fprintf('Early beat at %d, expected %d\n', new_time, expected_time);
                  plot(expected_peak(2, :), expected_peak(1, :), 'co', 'markers', 11);
                end
                
                %{
                if unexpected_flags(1) && all(unexpected_flags(1) == unexpected_flags)
                  % too many unexpected beats, actual rate must have changed
                  fprintf('Change in beating!\n');
                  curr_count = alarm_count;
                  rindex = rcount - curr_count + 1;
                  unexpected_flags = zeros(size(unexpected_flags));
                end
                %}
                
              else
                % expected beat
                unexpected_flags = shift(unexpected_flags, 0);
              end % end check event type
            end % end check current count
            
            avg_volt = mean(rpeaks(1, rindex:rcount));
            avg_diff = mean(diff(rpeaks(2, rindex:rcount)));
            prev_expected_peak = expected_peak;
            expected_peak = [avg_volt; round(avg_diff + rpeaks(2, rcount))];
            
          end % end check definite R peak
         prev_possible_peak = possible_peak;
        end % end check likely R peak
      end % end check new max
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
  % adjust array and plot
  rpeaks = rpeaks(:, 1:rcount);
  plot(rpeaks(2, :), rpeaks(1, :), 'ro');
  disp(rcount);
  
  if early_count > 0
    early_beats = early_beats(:, 1:early_count);
    plot(early_beats(2, :), early_beats(1, :), 'c*');
  else
    early_beats = [];
  end
  if late_count > 0
    late_beats = late_beats(:, 1:late_count);
    plot(late_beats(2, :), late_beats(1, :), '*', 'Color', [1, 0.5, 0.5]);
  else
    late_beats = [];
  end
  if removed_count > 0
    removed_beats = removed_beats(:, 1:removed_count);
    plot(removed_beats(2, :), removed_beats(1, :), 'kx', 'markers', 11);
  else
    removed_beats = [];
  end
  if added_count > 0
    added_beats = added_beats(:, 1:added_count);
    plot(added_beats(2, :), added_beats(1, :), 'ro', 'markers', 11);
  else
    added_beats = [];
  end
  
else
  rpeaks = [];
end

%{
disp(rpeaks(2,:));
disp(early_beats);
disp(late_beats);
disp(removed_beats);
disp(added_beats);
%}

end
