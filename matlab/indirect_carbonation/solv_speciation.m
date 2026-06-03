function Z = solv_speciation(y,C)
%SOLV_SPECIATION Summary of this function goes here
%   Detailed explanation goes here

H1 = y(1);
OH1 = y(2);

Z = [(log10(H1)+log10(OH1)+14);
    (1-OH1/H1+C/H1)];
end

