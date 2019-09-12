%This script does NOT convert TAL -> MNI or anything of that sort
%What it does is convert an MNI voi from "BV" reference space to "MNI" reference space
function VOI_BV2MNI

%% Select VOI file
[filename, directory, filter] = uigetfile('*.voi', 'Select VOI File(s)','MultiSelect', 'off');

%% Check inputs
if filter ~= 1
    error('Invalid selection.')
end

%% Output is valid?
us = find(filename=='.',1,'last');
filepath_out = [directory filename(1:us-1) '_BV2MNI' filename(us:end)];
if exist(filepath_out, 'file')
    error('Output file already exists and will not be overwritten!')
end

%% Load

filepath = [directory filename];
fprintf('Loading: %s\n', filepath);
voi = xff(filepath);

%% Checks

fprintf('Checking voi...\n');

%check res
res = arrayfun(@(x) getfield(voi, ['OriginalVMRResolution' x]), 'XYZ');
if any(res) ~= 1
    error('Requires 1x1x1 resolution')
end

%check offset
offset = arrayfun(@(x) getfield(voi, ['OriginalVMROffset' x]), 'XYZ');
if any(offset) ~= 0
    error('Requires no offset')
end

%check box
if voi.OriginalVMRFramingCubeDim ~= 256
    error('Requires 256 framing cube')
end

%is BV ref space
if ~strcmp(upper(voi.ReferenceSpace), 'BV')
    error('VOI reference space is %s (not BV)', voi.ReferenceSpace)
end

%% Convert

fprintf('Converting reference space...\n');

%convert VOIs
for v = 1:voi.NrOfVOIs
    voi.VOI(v).Voxels = (voi.VOI(v).Voxels(:,[3 1 2]) - 128) * -1;
end

%update ReferenceSpace label
voi.ReferenceSpace = 'MNI';

%% Save
fprintf('Saving: %s\n', filepath_out);
voi.SaveAs(filepath_out);

%% Cleanup
voi.ClearObject;
fprintf('Complete!\n');
