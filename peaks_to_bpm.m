function [ avg, inst ] = peaks_to_bpm( rpeaks )

rpeaks = rpeaks(2, :);
d = diff(rpeaks);
inst = 60 ./ d;
avg = 60 / mean(d);

end