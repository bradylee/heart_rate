function [ fwd, rev ] = is_sorted( buffer )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

fwd = 1;
rev = 1;

len = length(buffer);
if len > 1
    prev = buffer(1);
    for ii = 2:len
        cur = buffer(ii);
        if cur > prev
            rev = 0;
        elseif cur < prev
            fwd = 0;
        end
        prev = cur;
    end
end    

end

