close all;

%%{
clear;
patient = 'mitdb/104';
[tstamps, signal, fs] = rdsamp(patient, 1, 100000);
signal = signal';
tstamps = tstamps';
range = [125, 175];
index = round(range * fs);
signal = signal(index(1):index(2));
tstamps = tstamps(index(1):index(2));
%}

[rpeaks, late, early, discarded] = qrs_detect(signal, tstamps, fs, 0.6, 250, 1.5, 10, 2, patient);
%1.4 on 101 to test change in beating
%102 lots of late beats

%disp(peaks_to_bpm(rpeaks));