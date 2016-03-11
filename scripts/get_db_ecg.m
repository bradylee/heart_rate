close all;

vtol = 0.6;
ttol = 150;
vscale = 1.5;
win_size = 15;
alarm_count = 2;
patient = 'mitdb/101';
samples = 100000;
match_tol = [0, 1, 3, 5, 10, 25, 50];
% tol in terms of ms
%disp(match_tol ./ fs * 1000);
plot_en = 0; % executes much faster without plotting

[tstamps, signal, fs] = rdsamp(patient, 1, samples);
signal = signal';

%{
range = [125, 175];
index = round(range * fs);
signal = signal(index(1):index(2));
tstamps = tstamps(index(1):index(2));
%}

[rpeaks, late, early, added, removed] = qrs_detect(signal, fs, vtol, ...
  ttol, vscale, win_size, alarm_count, patient, plot_en);

[rr, samp_ann] = ann2rr(patient, 'atr', samples);
samp_ann = samp_ann';

% for some reason ann2rr does not return the full range
samp_measure = rpeaks(2, 1:length(samp_ann));

% within tolerance ... not an effective method because this assumes exact alignments (no missed
% or late beats)
for tol = match_tol
  perf = sum(abs(samp_measure - samp_ann) <= tol) / length(samp_ann);
  fprintf('Performance for tol %d is %f\n', tol, perf);
end

fprintf('Average heart rate of %f\n', peaks_to_bpm(rpeaks, fs));