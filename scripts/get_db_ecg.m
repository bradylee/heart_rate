close all;

vtol = 0.6;
ttol = 150; %250;
vscale = 1.5;
win_size = 15;
alarm_count = 2;
patient = 'mitdb/101';

%%{
[tstamps, signal, fs] = rdsamp(patient, 1, 2000);
signal = signal';
tstamps = tstamps' * 1000;
disp(tstamps(1));

%{
range = [125, 175];
index = round(range * fs);
signal = signal(index(1):index(2));
tstamps = tstamps(index(1):index(2));
%}

[rpeaks, late, early, added, removed] = qrs_detect(signal, fs, vtol, ...
  ttol, vscale, win_size, alarm_count, patient);

%1.4 on 101 to test change in beating
%102 lots of late beats

%disp(peaks_to_bpm(rpeaks));