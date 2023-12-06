! BHANDHLYP def2-SVP TightSCF

%CPCM
end

%tddft
NRoots 5
IRoot 1
end

#  4 
* xyz 0 1
 C 0.000000    0.000000    0.000000
 O 0.000000    0.000000    1.500000
 O 0.000000    0.000000   -1.159076
*
