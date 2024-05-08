% Summarizes a VMP map across VOIs
%
% Produces a spreadsheet containing the following for each VOI region:
%   1. VOI Name
%   2. VOI Index in File
%   3. % voxels > threshold
%   4. # voxels > threshold
%   5. mean voxel value
%
% Also creates a VOI file with the subset of VOIs with
% PercentVoxelsAboveThreshold > specified threshold (useful for atlases)
%
% The input VOI must use the MNI reference space. VOI_BV2MNI may be needed.

function VMP_VOI_SUMMARY(   VMP_input_filepath, ...
                            VMP_map_num, ...
                            VMP_threshold, ...
                            VOI_input_filepath, ...
                            CSV_output_filepath, ...
                            min_pct_voxels, ...
                            VOI_output_filepath ...
                            )

%% Check Inputs

if ~exist(VMP_input_filepath, 'file')
    error('VMP does not exist: %s', VMP_input_filepath)
else
    fprintf('Loading VMP...\n');
    vmp = xff(VMP_input_filepath);
end

if isempty(VMP_map_num) || length(VMP_map_num)~=1 || ~isnumeric(VMP_map_num)
    VMP_map_num = 1;
    fprintf('Defaulting "VMP_map_num" to %g\n', VMP_map_num);
end

if vmp.NrOfMaps < VMP_map_num
    error('"VMP_map_num" (%d) exceeds vmp.NrOfMaps (%d)', VMP_map_num, vmp.NrOfMaps)
else
    fprintf('Selected VMP map %d: %s\n', VMP_map_num, vmp.Map(VMP_map_num).Name);
end

if isempty(VMP_threshold) || length(VMP_threshold)~=1 || ~isnumeric(VMP_threshold) || VMP_threshold<=0
    fprintf('Defaulting "VMP_threshold" to current threshold (%g)\n', vmp.Map(VMP_map_num).LowerThreshold);
    VMP_threshold = vmp.Map(VMP_map_num).LowerThreshold;
else
    fprintf('Using provided threshold: %g\n', VMP_threshold);
end

if ~exist(VOI_input_filepath, 'file')
    error('VOI does not exist: %s', VOI_input_filepath)
else
    fprintf('Loading VOI...\n');
    voi = xff(VOI_input_filepath);
end

if ~strcmp(voi.ReferenceSpace, 'MNI')
    error('VOI ReferenceSpace (%s) must be MNI. VOI_BV2MNI may help resolve this.', voi.ReferenceSpace)
end

if exist(CSV_output_filepath, 'file')
    fprintf('Deleting prior output: %s', CSV_output_filepath);
    delete(CSV_output_filepath);
end

if exist(VOI_output_filepath, 'file')
    fprintf('Deleting prior output: %s', VOI_output_filepath);
    delete(VOI_output_filepath);
end

if isempty(min_pct_voxels) || length(min_pct_voxels)~=1 || ~isnumeric(min_pct_voxels) || min_pct_voxels<=0
    min_pct_voxels = 10;
    fprintf('Defaulting "min_pct_voxels" to %g\n', min_pct_voxels);
end

%% Run

t = array2table(arrayfun(@(x) x.Name, voi.VOI, 'UniformOutput', false)', 'VariableNames', "RegionName");
t.RegionNumber = (1:voi.NrOfVOIs)';
t.PercentVoxelsAboveThreshold(:) = nan;
t.NumberVoxelsAboveThreshold(:) = nan;
t.MeanVoxelValue(:) = nan;

bb = vmp.BoundingBox;

fprintf('Processing VOIs...\n');
for v = 1:voi.NrOfVOIs
    fprintf('\t%d of %d: %s\n', v, voi.NrOfVOIs, voi.VOI(v).Name);

    %get values
    values = vmp.VoxelStats(VMP_map_num, voi.BVCoords(v, bb) + 1);

    %exclude NaN
    values(isnan(values)) = [];

    %store
    t.NumberVoxelsAboveThreshold(v) = sum(values > VMP_threshold);
    t.PercentVoxelsAboveThreshold(v) = (t.NumberVoxelsAboveThreshold(v) / numel(values)) * 100;
    t.MeanVoxelValue(v) = mean(values);
end

%% Sort

fprintf('Sorting by PercentVoxelsAboveThreshold...\n');
[~,order] = sort(t.PercentVoxelsAboveThreshold, 'descend');
t = t(order,:);

%% Save

%full table
fprintf('Saving: %s\n', CSV_output_filepath)
writetable(t, CSV_output_filepath)

%voi subset
fprintf('Saving: %s\n', VOI_output_filepath)
ind = order(t.PercentVoxelsAboveThreshold >= min_pct_voxels);
voi.VOI = voi.VOI(ind);
voi.SaveAs(VOI_output_filepath);

%% Done

disp Done!
