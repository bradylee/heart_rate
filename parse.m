SAMPLES = 650000;
DWIDTH = 3; % data stored as 12 bits per sample

MASK1 = 240;    % 0x0f0
MASK2 = 3840;   % 0xf00

fd = fopen('mitdb/101.dat');
adc1 = zeros(1, SAMPLES);
adc2 = zeros(1, SAMPLES);

for ii = 1 : SAMPLES
    data = fread(fd, DWIDTH);
    samp1_low = uint16(data(1));
    samp2_low = uint16(data(3));
    mid = uint16(bitshift(data(2), 4));
    
    adc1(ii) = bitor(bitshift(bitand(mid, MASK1), 4), samp1_low);
    adc2(ii) = bitor(bitand(mid, MASK2), samp2_low);
end