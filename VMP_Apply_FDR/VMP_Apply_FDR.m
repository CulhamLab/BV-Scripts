%VMP_Apply_FDR(vmp, q, map_indicies, mode)
%
%Calculate FDR for VMP t-map and set lower threshold. 0s are treated as
%NaNs. Changes are made directly in the passed VMP structure.
%
%Notes:
%-this method uses the DF1/DF2 values in each map
%-setting map FDRThreshold (for applying FDR in BV) does not seem to work
function VMP_Apply_FDR(vmp, q, map_indicies, mode)

ne = neuroelf;

if ~exist('map_indicies', 'var')
    warning('"map_indicies" was not passed. Will attempt all maps.');
    map_indicies = 1:vmp.NrOfMaps;
end

if ~exist('q', 'var') || isempty(q)
    warning('"q" was not passed. Using BV default of 0.05');
    q = 0.05;
end

if ~exist('mode', 'var') || isempty(mode)
    warning('"mode" was not passed. Using default mode 0: c(V)=1. The alternative is 1: c(V)=ln(V)+E');
    mode = 0;
end

switch mode
    case 0
        method_index = 0;
        mode_name = 'c(V)=1';
    case 1
        method_index = 1;
        mode_name = 'c(V)=ln(V)+E';
    otherwise
        error('Unknown mode')
end
        

for m = map_indicies
    %calc threshold
    switch vmp.Map(m).Type
        case 1 %tmap
            threshold = ne.applyfdr(vmp.Map(m).VMPData, 't', q, vmp.Map(m).DF1, vmp.Map(m).DF2, method_index);
            threshold = threshold(end); %support mode 1
        otherwise
            warning('Unsupported map type %d. Cannot apply FDR to map %d "%s".', vmp.Map(m).Type, m, vmp.Map(m).Name);
    end
    
    vmp.Map(m).Name = sprintf('%s [FDR(%g),MODE:%s]=%g', vmp.Map(m).Name, q, mode_name, threshold);
    vmp.Map(m).LowerThreshold = threshold;
    if vmp.Map(m).UpperThreshold < vmp.Map(m).LowerThreshold
        vmp.Map(m).UpperThreshold = threshold + 5;
    end
end