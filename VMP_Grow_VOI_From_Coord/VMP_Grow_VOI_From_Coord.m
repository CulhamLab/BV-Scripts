% function VMP_Grow_VOI_From_Coord
% 
% Create a VOI from VMP by growing out the most significant voxels from a hotspot.
%
% INPUTS:
%   filepath_vmp        filepath to input VMP
%   filepath_voi        filepath to output VOI (will overwrite)
%   mode                which side of zero to select, default "positive"
%   x/y/z               starting coord, defaults to the peak value, defaults to hotspot
%   number_voxels       number of voxels to select (in 1mm), default 200
%   min_threshold       cutoff threshold, automatically inverted for negative search mode (i.e., won't select voxels with this value or less), default 0
%   allow_fewer_voxels  if false: will throw and error if there are not enough voxels to select from, default true
function VMP_Grow_VOI_From_Coord(args)
arguments
    args.filepath_vmp (1,:) {isfile}
    args.filepath_voi (1,:) {mustBeText}
    args.mode {mustBeMember(args.mode,["positive" "negative"])} = "positive"
    args.x (1,1) {isMNIorNaN(args.x)} = nan
    args.y (1,1) {isMNIorNaN(args.y)} = nan
    args.z (1,1) {isMNIorNaN(args.z)} = nan
    args.number_voxels (1,1) {mustBeInteger, mustBePositive} = 200
    args.min_threshold (1,1) {mustBeGreaterThanOrEqual(args.min_threshold,0)} = 0
    args.allow_fewer_voxels (1,1) {mustBeNumericOrLogical} = true
end

%% Common prep
if isempty(regexp(args.filepath_voi, '\d*.voi'))
    args.filepath_voi = [args.filepath_voi '.voi'];
end


%%  Load VMP
fprintf('Reading VMP: %s\n', args.filepath_vmp);
vmp = xff(args.filepath_vmp);


%% Start VOI
voi = xff('voi');
voi.FileVersion = 4;
voi.ReferenceSpace = 'MNI';
voi.NrOfVOIs = vmp.NrOfMaps;
colours = round(jet(vmp.NrOfMaps) * 255);

%% For each map...
fprintf('Search mode: %s\n', args.mode)
for m = 1:vmp.NrOfMaps
    fprintf('Processing map %d of %d: %s\n', m, vmp.NrOfMaps, vmp.Map(m).Name);
    
    %% Prepare map

    %convert to 256^3
    map = zeros(256,256,256,'single');
    map(vmp.XStart:vmp.XEnd-1, vmp.YStart:vmp.YEnd-1, vmp.ZStart:vmp.ZEnd-1) = imresize3(vmp.Map(m).VMPData, vmp.Resolution, 'method', 'nearest');

    %flip if looking for negative
    if strcmp(args.mode, "negative")
        map = map * -1;
    end

    %threshold
    map(map < args.min_threshold) = nan;


    %% Prepare staring coord
    if any(isnan([args.x args.y args.z]))
        [~,ind] = nanmax(map(:));
        [x,y,z] = ind2sub(size(map),ind);
    else
        x = 128 - args.y;
        y = 128 - args.z;
        z = 128 - args.x;

        if isnan(map(x,y,z))
            error('Specified coordinate (%d,%d,%d) does not meet threshold', args.x, args.y, args.z)
        end
    end
    fprintf('\tStarting at (%d,%d,%d), value = %g\n', 128 - [z x y]);

    %% Select
    %initialize
    select = false(size(map));
    select(x,y,z) = true;

    while sum(select(:)) < args.number_voxels
        options = (smooth3(select,'box',3)>0) & ~select;
        options_ind = find(options(:));
        values = map(options);

        mx = nanmax(values);
        if isnan(mx)
            %nothing more to select
            if args.allow_fewer_voxels
                fprintf('\tOnly found %d voxel(s)\n', sum(select(:)));
                break;
            else
                error('Too few voxels meet threshold')
            end
        end

        inds = find(values==mx);

        %if ties and limited voxels, select in order of matrix index
        vox_avail = (args.number_voxels - sum(select(:)));
        if length(inds) > vox_avail
            fprintf('\tDuring the final selection, there were multiple tied voxels. Selection was made in the index order of the 3D matrix.');
            inds = inds(1:vox_avail);
        end

        %add to selection
        select(options_ind(inds)) = true;
    end


    %% Convert to VOI
    [xs,ys,zs] = ind2sub(size(select),find(select(:)));

    xsMNI = 128 - zs;
    ysMNI = 128 - xs;
    zsMNI = 128 - ys;

    voi.VOI(m).Name = vmp.Map(m).Name;
    voi.VOI(m).Color = colours(m,:);
    voi.VOI(m).Voxels = [xsMNI ysMNI zsMNI];
    voi.VOI(m).NrOfVoxels = size(voi.VOI(m).Voxels,1);

    values = map(select(:));
    if strcmp(args.mode, "negative")
        values = values * -1;
    end

    fprintf('\tSelected %d voxels with range %g to %g\n', voi.VOI(m).NrOfVoxels, min(values), max(values));
end


%% Save
fprintf('Writing VOI: %s\n', args.filepath_voi);
voi.SaveAs(args.filepath_voi);


%% Done
voi.ClearObject;
vmp.ClearObject;
disp Done!


%%
function isMNIorNaN(value)
if ~isnan(value) && ~ismember(value,-127:+128)
    eidType = 'isMNIorNaN:notMNIorNaN';
    msgType = 'Input must be a -127 to +128 integer or NaN.';
    throwAsCaller(MException(eidType,msgType))
end