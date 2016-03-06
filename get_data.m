datafile;
signal = signal(1000:7000);
tstamps = tstamps(1000:7000);
SAMPLES = length(signal);
fs = 800;

figure; hold on;
plot(tstamps, signal);