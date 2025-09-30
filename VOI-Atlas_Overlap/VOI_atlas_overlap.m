% VOI_atlas_overlap
%
% Determines the percent overlap of each region in the target VOI with each
% region in an atlas VOI and vice versa. The two VOIs must have the same
% resolution, reference space, and offset (if applicable).
%
% Output is created in the form of two csv files (target x atlas) and
% (atlas x target) containing percentage values 0-100.
%
% Requires the NeuroElf toolbox.
%
% Inputs:
%   filepath_VOI_atlas      filepath to VOI of atlas
%   filepath_VOI_target     filepath to VOI to compare with atlas
%   output_filename_prefix  prefix for output csv files
%
function VOI_atlas_overlap(args)

%% Handle inputs
arguments
    args.filepath_VOI_atlas (1,:) char
    args.filepath_VOI_target (1,:) char
    args.output_filename_prefix (1,:) char
end

%% Load
fprintf("Loading atlas VOI: %s\n", args.filepath_VOI_atlas);
atlas = xff(args.filepath_VOI_atlas);

fprintf("Loading target VOI: %s\n", args.filepath_VOI_target);
target = xff(args.filepath_VOI_target);


%% Compare resolution, offset, and space
for f = ["OriginalVMRResolutionX" "OriginalVMRResolutionY" "OriginalVMRResolutionZ" "OriginalVMROffsetX" "OriginalVMROffsetY" "OriginalVMROffsetZ"]
    if atlas.(f.char) ~= target.(f.char)
        error("Atlas and target VOI have different resolutions and/or offsets")
    end
end
if ~strcmp(atlas.ReferenceSpace, target.ReferenceSpace)
    error("Atlas and target VOI have different reference spaces")
end


%% Prep
atlas_names = arrayfun(@(x) string(x.Name), atlas.VOI);
target_names = arrayfun(@(x) string(x.Name), target.VOI);

pct_atlas_in_target = nan(target.NrOfVOIs, atlas.NrOfVOIs);
pct_target_in_atlas = nan(atlas.NrOfVOIs, target.NrOfVOIs);


%% Find Overlaps
for c = 1:target.NrOfVOIs
    fprintf("Processing target VOI region %d of %d...\n", c, target.NrOfVOIs);

    for a = 1:atlas.NrOfVOIs
        % number of overlap voxels
        overlap = intersect(atlas.VOI(a).Voxels, target.VOI(c).Voxels, "rows");
        overlap_count = size(overlap, 1);

        % atlas in target
        pct_atlas_in_target(c,a) = overlap_count / target.VOI(c).NrOfVoxels * 100;

        % target in atlas
        pct_target_in_atlas(a,c) = overlap_count / atlas.VOI(c).NrOfVoxels * 100;
    end
end


%% Organize and save
filename = args.output_filename_prefix + "_Percent-Atlas-In-Target.csv"; 
fprintf("Writing: %s\n", filename);
tbl = array2table(pct_atlas_in_target, RowNames=target_names, VariableNames=atlas_names);
writetable(tbl, filename, WriteRowNames=true);

filename = args.output_filename_prefix + "_Percent-Target-In-Atlas.csv"; 
fprintf("Writing: %s\n", filename);
tbl = array2table(pct_target_in_atlas, RowNames=atlas_names, VariableNames=target_names);
writetable(tbl, filename, WriteRowNames=true);


%% Done
disp Done!