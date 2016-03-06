[tstamps, signal, fs] = rdsamp('mitdb/101', 1, 100000);
[rpeaks, miss_count] = qrs_detect(signal, tstamps, fs, 0.4, 200, 1.5, 10, 2);
disp(peaks_to_bpm(rpeaks));