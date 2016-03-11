function [ avg, inst ] = peaks_to_bpm( rpeaks, fs )

% rpeaks: row 1 signal (millivolts), row 2 samples
d = diff(rpeaks(2, :)) ./ fs;
inst = 60 ./ d;
avg = 60 / mean(d);

end