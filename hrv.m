function [ avnn, sdnn, sdann, sdnnidx, rmssd, pnn50 ] = hrv( rpeaks, partition, early, late, removed, added )
%%% https://physionet.org/tutorials/hrv-toolkit/
% rpeaks: R to R intervals to analyze
% * row 1 should be voltage values in millivolts
% * row 2 should be time values in seconds
% partition: segment size for SDANN and SDNNIDX in seconds

  intervals = diff(rpeaks(2, :));
  fs = rpeaks(2, end) / size(rpeaks, 2);
  seglen = round(partition * fs);
  disp(seglen);
  segnum = floor(length(intervals) / seglen);
  segments = reshape(intervals(1:segnum*seglen), segnum, seglen);
  
  % average of NN intervals
  avnn = mean(intervals);
  
  % standard deviation of NN intervals
  sdnn = std(intervals);
  
  % standard deviation of averages of intervals in segments
  sdann = std(mean(segments, 2));
  
  % mean of standard deviations of intervals in segments
  sdnnidx = mean(std(segments, 2));
  
  % square root of mean of squares of NN intervals
  rmssd = sqrt(mean(intervals .^ 2));
  
  % percentage of diffs between adjacent NN greater than 50 ms
  pnn50 = sum(diff(intervals) > 0.05) / length(intervals);





	% power statistics
	% error and correction statistics
  
end
