close all;
figure;
hold on;

datafile;
fs = 8000;
signal = signal(1000:7000);
tstamps = tstamps(1000:7000);
%plot(tstamps, signal, 'b');

fc = 100;
wn = (2/fs) * fc;
%b = fir1(20, wn, 'low', kaiser(21,3));
b = fir1(20, wn);
y = filter(b, 1, signal);
plot(tstamps, y);

%qrs_detect(signal, tstamps, 800, 0.03, 1.5, 10);
[rpeaks, miss_count] = qrs_detect(y, tstamps, 800, 0.02, 100, 1.5, 10, 2);
disp(peaks_to_bpm(rpeaks));