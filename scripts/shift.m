function [ newbuf, output ] = shift( buffer, input )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    output = buffer(:, end);
    newbuf = circshift(buffer, [0 1]); % shift to right
    newbuf(:, 1) = input;
end

