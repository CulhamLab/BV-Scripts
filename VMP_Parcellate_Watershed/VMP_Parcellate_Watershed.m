% VMP_Parcellate_Watershed
%
% Creates a parcellated copy of a VMP using the watershed algorithm. For
% best results, VMP maps should contain continuous values. Works better on
% maps with only positive (or negative) values.
%
% Requires NeuroElf. Does not require SPM.
%
% The output VMP can be converted into VOIs in BrainVoyager:
%   1. Select map and note the number of parcels (max colour scaling will be set to this)
%   2. Volume Maps -> Advanced -> VOI Per Winner
%   3. Set the number of bins to the number of parcels
%   4. Click GO
%
% Methods:
%   MATLAB      In my testing, this was the most consistent and reliable method.
%   MATLAB2     Uses "watershed_old". Output is extremely similar to the default method above. Try this as a backup if the first method doesn't work well.
%   SPM         Tends to produce more/smaller parcels compared to the MATLAB methods.
%
% Inputs:
%   filepath_vmp            Path to the VMP. Output will be in the same folder as *_watershed.vmp
%   use_map_thresholds      If true, then the lower thresholds set in the VMP maps will be used. Otherwise, maps will not be thresholded. (default: true)    
%   polarity                Use only the postive, negative, or all values. (default: all)
%   method                  Watershed algorithm to use. May be MATLAB, MATLAB2, or SPM. (default: MATLAB)
%   max_depth_reduction     Increasing this value will decrease the number of parcels formed. Set 0 to disable. (default: 0)
%   voxel_adjacencies       When using either MATLAB method, this value (6, 18, or 26) sets the voxel adjacency rule. (default: 26)
%                               See: https://www.mathworks.com/help/images/ref/watershed.html#bupehwf-1-conn
%
function VMP_Parcellate_Watershed(args)

arguments
    args.filepath_vmp (1,1) string
    args.use_map_thresholds (1,1) logical = true
    args.polarity (1,1) string {mustBeMember(args.polarity,["positive" "negative" "all"])} = "all"; 
    args.method (1,1) string {mustBeMember(args.method,["SPM","MATLAB","MATLAB2"])} = "MATLAB"
    args.max_depth_reduction (1,1) double = 10;
    args.voxel_adjacencies (1,1) double {mustBeMember(args.voxel_adjacencies,[6, 18, 26])} = 26
end

%% Inputs
if ~isfield(args, "filepath_vmp")
    error("You must provide a filepath to the VMP (filepath_vmp)")
end


%% Load VMP
fprintf("Loading: %s\n", args.filepath_vmp);
vmp = xff(args.filepath_vmp.char);


%% Process each map
for m = 1:vmp.NrOfMaps
    fprintf("Processing map %d of %d: %s\n", m, vmp.NrOfMaps, vmp.Map(m).Name);

    % initialize label to append to name
    label = "";

    % get map
    map = vmp.Map(m).VMPData;

    % select values
    if label.strlength, label = label + ","; end
    label = label + sprintf("polarity=%s", args.polarity);
    switch args.polarity
        case "positive"
            map(map<0) = 0;
        case "negative"
            map(map>0) = 0;
        case "all"
            % no action needed
        otherwise
            error("Unsupported args.polarity: %s", args.polarity)
    end

    % threshold the map?
    if args.use_map_thresholds
        if label.strlength, label = label + ","; end
        label = label + sprintf("thresh=%g", vmp.Map(m).LowerThreshold);
        map(abs(map) < vmp.Map(m).LowerThreshold) = 0;
    end

    % empty map?
    if ~any(map(:))
        error("After selecting polarity and apply any thresholds, the map is empty!")
    end

    % convert to depth map
    map = abs(map) * -1;

    % flag voxels to mask out
    mask_out = ~map;

    % reduce depth?
    if args.max_depth_reduction > 0
        if label.strlength, label = label + ","; end
        label = label + sprintf("maxdepthreduction=%g", args.max_depth_reduction);
        map = imhmin(map, args.max_depth_reduction);
    end

    % watershed
    if label.strlength, label = label + ","; end
    label = label + sprintf("method=%s", args.method);
    switch args.method
        case "MATLAB"
            if label.strlength, label = label + ","; end
            label = label + sprintf("voxeladjacencies=%g", args.voxel_adjacencies);
            map = watershed(map, args.voxel_adjacencies);
        case "MATLAB2"
            if label.strlength, label = label + ","; end
            label = label + sprintf("voxeladjacencies=%g", args.voxel_adjacencies);
            map = watershed_old(map, args.voxel_adjacencies);
        case "SPM"
            map = spm_ss_watershed(map);
        otherwise
            error("Unsupported args.method: %s", args.method)
    end

    % make out voxels that had value=0
    map(mask_out) = 0;

    % store
    vmp.Map(m).VMPData = map;
    vmp.Map(m).LowerThreshold = min(map(:));
    vmp.Map(m).UpperThreshold = max(map(:));

    % number of parcels
    fprintf("\tFound %d parcels\n", vmp.Map(m).UpperThreshold);

    % append label
    vmp.Map(m).Name = [vmp.Map(m).Name ' watershed(' label.char ')'];

    % done
    fprintf("\tCreated: %s\n", vmp.Map(m).Name);
end


%% Save output VMP
[fol, name, ext] = fileparts(args.filepath_vmp);
filepath = fol + filesep + name + "_watershed" + ext;
fprintf("Writing: %s\n", filepath);
vmp.SaveAs(filepath.char);


%% Done
disp Done!








%% SPM Watershed Function
function [D] = spm_ss_watershed(A,IDX)
% SPM_SS_WATERSHED watershed segmentation
%
% C=spm_ss_watershed(A);
% C=spm_ss_watershed(A,idx);
%

% note: assumes continuous volume data (this implementation does not work well with discrete data). In practice this means having sufficiently-smoothed volume data
%

sA=size(A);

%zero-pad&sort
if nargin<2, IDX=find(~isnan(A)); IDX=IDX(:); else IDX=IDX(:); end
[a,idx]=sort(A(IDX)); idx=IDX(idx); 
[pidx{1:numel(sA)}]=ind2sub(sA,idx(:));
pidx=mat2cell(1+cat(2,pidx{:}),numel(pidx{1}),ones(1,numel(sA)));
eidx=sub2ind(sA+2,pidx{:});
sA=sA+2;
N=numel(eidx);

%neighbours (max-connected; i.e. 26-connected for 3d)
[dd{1:numel(sA)}]=ndgrid(1:3);
d=sub2ind(sA,dd{:});
d=d-d((numel(d)+1)/2);d(~d)=[];

%assigns labels
C=zeros(sA);
m=1;
for n1=1:N,
    c=C(eidx(n1)+d);
    c=c(c>0);
    if isempty(c),
        C(eidx(n1))=m;m=m+1;
    elseif ~any(diff(c))
        C(eidx(n1))=c(1);
    end
end
D=zeros(size(A));D(idx)=C(eidx);
