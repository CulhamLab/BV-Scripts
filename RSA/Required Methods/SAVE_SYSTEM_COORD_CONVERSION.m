%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% NO LONGER SPECIFIC TO TAL!!! %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% [X,Y,Z] = TAL_TO_SAVESYSTEM_COORDS(TAL_MAT)
%
% TAL_MAT must be N-by-3
%
% Converts TAL XYZ to saved BV file XYZ
%
% Coordinates outside the recorded area will return [nan nan nan]
%

function [X,Y,Z] = TAL_to_SAVESYSTEM_coords(TAL_MAT,funcSize,notSys)

if nargin < 2
    error
end

if ~exist('notSys','var')
    notSys = false;
end

% if size(TAL_MAT,1)<1 | size(TAL_MAT,2)~=3
%     error('TAL_MAT must be N-by-3')
% end

%bounds used by everyone (so far)
if ~exist('funcSize','var')
%     funcSize = 3; %assuming iso 3mm^3
    error('Requires functional voxel size.')
end
dims = 256; %assuming 256^3 space

%SPECIFIC TO USER
returnPath = pwd;
try
    cd ..
    [p] = ALL_STEP0_PARAMETERS;
    cd(returnPath)
catch e
    cd(returnPath)
    rethrow(e)
end

boundXs = p.BBOX.XStart : (p.BBOX.XEnd - 1);
boundXs_func = ceil((1:length(boundXs))/funcSize);
boundYs = p.BBOX.YStart : (p.BBOX.YEnd - 1);
boundYs_func = ceil((1:length(boundYs))/funcSize);
boundZs = p.BBOX.ZStart : (p.BBOX.ZEnd - 1);
boundZs_func = ceil((1:length(boundZs))/funcSize);

X = nan(size(TAL_MAT,1),1);
Y = X;
Z = X;

if any(TAL_MAT(:)<1)
    warning('Correcting for non-system coord')
    notSys = true;
end

for i = 1:size(TAL_MAT,1)
    TAL = TAL_MAT(i,:);

    %convert from tal to system
%     sys = (TAL*-1) + (dims/2);

    if notSys
        TAL = (TAL*-1) + (dims/2);
        TAL = TAL([2 3 1]);
    end

    %Sys/TAL [X Y Z] is actually stored (and even named) as [Y Z X]
    %Note: I have no idea why BV creator's chose to do this. It's just
    %something that must be remembered and switched.
    %bvx = saved z
    %bvy = saved x
    %bvz = save y
%     sys_yzx = sys([2 3 1]);
   
    %convert 256^3 coord to bounding box coord
%     xloc = boundXs_func(find(boundXs==sys_yzx(1)));
%     yloc = boundYs_func(find(boundYs==sys_yzx(2)));
%     zloc = boundZs_func(find(boundZs==sys_yzx(3)));
    
    xloc = boundXs_func(find(boundXs==TAL(1)));
    yloc = boundYs_func(find(boundYs==TAL(2)));
    zloc = boundZs_func(find(boundZs==TAL(3)));
    
    if length(xloc) & length(yloc) & length(zloc)
        X(i) = xloc;
        Y(i) = yloc;
        Z(i) = zloc;
    end
end

end