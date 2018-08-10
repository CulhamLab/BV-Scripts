%[k] = calc_cluster_thresh(vmpPath,mapNum,criticalValue,tails,numIterations,FWHM,useDataDist)
%
%Tested with t-maps. Should work for F-maps, but this is untested. Should
%also work for r-maps.
%
%Assumes that functional voxels are isotropic.
%
%REQUIREMENTS:
%-NeuroElf toolbox must be installed
%
%INPUTS:
%-vmpPath: path to vmp to use
%-mapNum: map number in the vmp to use
%-criticalValue: t-stat threshold to use
%-tails: 2of2 (t stat, using both tails),
%        1of2 (t stat, using only 1 tail), or
%        1of1 (F stat)
%-numIterations: BV suggests 1000 but you could go higher
%-FWHM: set as NaN if you wish to use the estimated smoothness, otherwise,
%       enter the number of FUNCTIONAL voxels for FWHM (the BV plugin's
%       default is 1, neuroelf's default is 2).
%-useDataDist: set true to use a z-distribution based on the VMP data (both
%              BV plugin and neuroelf do NOT do this by default) or false
%              to use a normal distribution
%
%OUTPUTS:
%-k: estimated cluster threshold
%
%
function [k] = calc_cluster_thresh(vmpPath,mapNum,criticalValue,tails,numIterations,FWHM,useDataDist)

%% Testing values (using BV defaults)
% vmpPath = [pwd filesep 'VMPs_Grasps_NumberofDigits_ALL.vmp'];
% mapNum = 1;
% criticalValue = 2.2010;
% tails = '2of2';
% numIterations = 1000;
% FWHM = 1;
% useDataDist = false;
% nargin = 7;

%% Parameters/Constants
%cluster significance is based on this FWE-corrected p-value
FWE_CRITICAL_P = 0.05; 

%for our purposes, number of test conjunctions will always be 1
NUMBER_CONJUNCTIONS = 1;

%% Check inputs and load VMP/map
%all present
if nargin<7
    error([mfilename '(vmpPath,mapNum,criticalValue,tails,numIterations,FWHM,useDataDist)'])
end

%vmpPath
if ~exist(vmpPath,'file') | ~length(strfind(vmpPath,'.vmp'))
    error(sprintf('VMP file not found: %s',vmpPath))
end
vmp = xff(vmpPath);

%mapNum
if mapNum<1 | mapNum>length(vmp.Map)
    error(sprintf('Map number not found in VMP: %s',mapNum))
end
map = vmp.Map(mapNum);

%criticalValue - If this is an r-map, values must be -1 to +1. If this is a
%t-map than any value could be valid.
if map.Type==2 & abs(criticalValue)>1
    error(sprintf('criticalValue must be -1 to +1 in r-maps: %f',criticalValue))
end

%tails -  could be "one", "two", "upper" or "lower"
switch tails
    case '1of1' %include 1 of 1 tails (F stat)
        tailNum = 1;
    case '2of2' %include 2 of 2 tails (t stat)
        tailNum = 2;
    case '1of2' %include 1 of 2 tails (t stat)
        tailNum = [1 2];
    otherwise
        error(sprintf('tails must be 1of1, 2of2, or 1of2: %s',tails))
end

%numIterations - anything >0 is fine
if numIterations<1
    error(sprintf('numIterations must be >0: %d',numIterations))
end

%useDataDist
if ischar(useDataDist)
    error('useDataDist must be true or false (without quotes)')
end

%% Prep NeurlElf Script Library
netools = neuroelf;

%% calculate base null-distribution shift (used for simulating data)
zshift = 0;
if useDataDist
    mstat = double(map.VMPData(:));
    mstat(isinf(mstat) | isnan(mstat) | mstat == 0) = [];
    switch map.Type
        case {1} % t-Map
            % compute z-stat
            z = -sign(mstat) .* netools.sdist('norminv', netools.sdist('tcdf', -abs(mstat), map.DF1), 0, 1);

        case {2} % r-Map
            % compute z-stat
            z = -sign(mstat) .* netools.sdist('norminv', correlpvalue(abs(mstat), map.DF1 + 2), 0, 1);
        otherwise
            error('Unknown stat type.')
    end

    % remove voxels that are probably artifacts
    z(abs(z) > 5) = [];

    % detect shift
    zsiter = 0;
    zlshift = 0;
    zshift = median(z(z > (zlshift - 1) & z < (zlshift + 1)));
    while zsiter < 20 && ...
        abs(zlshift - zshift) > 0.01
        zsiter = zsiter + 1;
        zlshift = zshift;
        zshift = median(z(z > (zlshift - 1) & z < (zlshift + 1)));
    end
end

%% Smooth estimate
if ~isnan(FWHM)
    FWHM = FWHM([1 1 1]);
else
    res = vmp.Resolution;
    dmap = double(map.VMPData);
    dmap(isinf(dmap) | isnan(dmap)) = 0;
    fprintf('Estimating smoothness...');
    FWHM = netools.mapestsmooth(dmap, res) / res;
    map.RunTimeVars.FWHMMapEst = FWHM;
    fprintf('done.\n');
end

%% Dimensions
dim = size(map.VMPData);

%% Mask
mask = (map.VMPData ~= 0 & ~netools.isinfnan(map.VMPData));

%% Calculate threshold alpha from critical t
switch map.Type
    case {1} % t-Map
        alphasthr = tpdf(criticalValue,map.DF1);
    otherwise
        error('This stat is not implimented.')
end

%% Run Monte Carlo
fprintf('Running Monte Carlo simulations...')
alphasout = netools.alphasim(dim, struct('conj', NUMBER_CONJUNCTIONS, 'mask', mask, ...
    'fwhm', FWHM, 'niter', numIterations, 'stype', tailNum, 'thr', alphasthr, ...
    'zshift', zshift));
fprintf('done.\n')

%% k threshold
k = netools.findfirst(alphasout(:,end) < FWE_CRITICAL_P);
if ~length(k)
    warning('No clusters!')
end

%% Report
%name of vmp file
vmpName = vmpPath(find(vmpPath(1:end-1)==filesep,1,'last')+1:end);
if vmpName(end)==filesep
    vmpName = vmpName(1:end-1);
end

%type of stat
switch map.Type
    case {1} % t-Map
        statType = 't';
    case {2} % r-Map
        statType = 'r';
    otherwise
        statType = 'unknown';
end

fprintf('---------------------------------------------------------------------\n');
fprintf('VMP Path: %s\n',vmpPath);
fprintf('VMP Name: %s\n',vmpName);
fprintf('Map Name: %s\n',map.Name);
fprintf('Map Size: %dx%dx%d\n',dim);
fprintf('Number of voxels used: %d\n',sum(mask(:)));
fprintf('Stat used: %s\n',statType);
fprintf('FWHM size in function voxels: [%g %g %g]\n',FWHM);
fprintf('Number of iterations: %d\n',numIterations);
fprintf('Tails used: %s\n',tails);
fprintf('Stat threshold: %s=%g (p=%g)\n',statType,criticalValue,alphasthr);
fprintf('Base null-distribution shift applied: %g\n',zshift);
fprintf('Degrees of freedom: %d\n',map.DF1);
fprintf('\nEstimated Cluster Threshold: %d\n',k);
fprintf('---------------------------------------------------------------------\n');

%% Close all
close all

end