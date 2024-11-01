% Function VOI_Mask_With_VMP(filepath_in_voi, filepath_in_vmp, filepath_out_voi, threshold)
%
% For each VMP map, for each VOI region: masks the VOI region with 
% VMP map >= specified threshold. Then, saves a new VOI with Map-by-Region
% masked regions.
%
% Inputs:
%   filepath_in_voi     Filepath to input VOI (or filename if local)
%   filepath_in_vmp     Filepath to input VMP (or filename if local)
%   filepath_out_voi    Filepath to output VOI, will overwrite
%   threshold           Positive VMP Threshold (selects value >= threshold)
%
function VOI_Mask_With_VMP(filepath_in_voi, ...
                           filepath_in_vmp, ...
                           filepath_out_voi, ...
                           threshold)
arguments
    filepath_in_voi (1,:) char {mustBeFile}
    filepath_in_vmp (1,:) char {mustBeFile}
    filepath_out_voi (1,:) char
    threshold (1,1) double {mustBePositive}
end

%% Load

fprintf('Loading VOI: %s\n', filepath_in_voi);
voi_base = xff(filepath_in_voi);

fprintf('Loading VMP: %s\n', filepath_in_vmp);
vmp = xff(filepath_in_vmp);

%% Initialize

voi = voi_base.CopyObject();
voi.VOI = voi.VOI(1);
c = 0;

%% Run

fprintf('Masking with a threshold of +%f...\n', threshold);

for mid = 1:vmp.NrOfMaps
    fprintf('Processing map %03d of %03d: %s\n', mid, vmp.NrOfMaps, vmp.Map(mid).Name);
    for vid = 1:voi_base.NrOfVOIs
        fprintf('\tCalculating overlap with voi %03d of %03d: %s\n', vid, voi_base.NrOfVOIs, voi_base.VOI(vid).Name);
        c = c + 1;
        
        % start with base values
        voi.VOI(c) = voi_base.VOI(vid);

        % overlap
        values = vmp.VoxelStats(mid, voi.VOI(c).Voxels, voi.ReferenceSpace);
        select = values >= threshold;
        voi.VOI(c).Voxels = voi.VOI(c).Voxels(select, :);

        % name
        voi.VOI(c).Name = sprintf('%s %s (%d voxels)', vmp.Map(mid).Name, voi.VOI(c).Name, size(voi.VOI(c).Voxels, 1));
        fprintf('\tCreated voi %d: %s\n', c, voi.VOI(c).Name);
    end
end

%% Save

if c < 1
    error('No maps and/or regions were found!')
end

fprintf('Saving Map-by-Region: %s\n', filepath_out_voi);
voi.SaveAs(filepath_out_voi);

%% DOne

disp Done!