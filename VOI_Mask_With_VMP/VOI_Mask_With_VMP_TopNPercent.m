% Function VOI_Mask_With_VMP_TopNPercent(filepath_in_voi, filepath_in_vmp, filepath_out_voi, percent_select)
%
% For each VMP map, for each VOI region: masks the VOI region with 
% VMP map selecting the top "percent_select" percentage of voxels. Then, 
% saves a new VOI with Map-by-Region masked regions.
%
% Note: If voxels have IDENTICAL values and "percent_select" is set such 
% that a subset of these voxels should be selected, then the selection will
% be determined by their order in the VMP map (i.e., by coordinates).
%
% Inputs:
%   filepath_in_voi     Filepath to input VOI (or filename if local)
%   filepath_in_vmp     Filepath to input VMP (or filename if local)
%   filepath_out_voi    Filepath to output VOI, will overwrite
%   percent_select      Percent of top voxels to select (0 < pct <= 100)
%
function VOI_Mask_With_VMP_TopNPercent(filepath_in_voi, ...
                                        filepath_in_vmp, ...
                                        filepath_out_voi, ...
                                        percent_select)
arguments
    filepath_in_voi (1,:) char {mustBeFile}
    filepath_in_vmp (1,:) char {mustBeFile}
    filepath_out_voi (1,:) char
    percent_select (1,1) double {mustBeInRange(percent_select,0,100,"exclude-lower")}
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

fprintf('Masking with the top %g%% of voxels...\n', percent_select);

for mid = 1:vmp.NrOfMaps
    fprintf('Processing map %03d of %03d: %s\n', mid, vmp.NrOfMaps, vmp.Map(mid).Name);
    for vid = 1:voi_base.NrOfVOIs
        fprintf('\tCalculating overlap with voi %03d of %03d: %s\n', vid, voi_base.NrOfVOIs, voi_base.VOI(vid).Name);
        c = c + 1;
        
        % start with base values
        voi.VOI(c) = voi_base.VOI(vid);

        % extract VMP values
        values = vmp.VoxelStats(mid, voi.VOI(c).Voxels, voi.ReferenceSpace);

        % counts
        values_count = length(values);
        num_to_select = round(values_count * percent_select / 100);

        % select voxels
        fprintf("\t\tSelecting top %d of %d voxels...\n", num_to_select, values_count);
        [~,order] = sort(values, "descend");
        select = sort(order(1:num_to_select));

        % apply selection
        voi.VOI(c).Voxels = voi.VOI(c).Voxels(select, :);

        % name
        voi.VOI(c).Name = sprintf('%s %s (%d voxels)', vmp.Map(mid).Name, voi.VOI(c).Name, size(voi.VOI(c).Voxels, 1));
        fprintf('\t\t\tCreated voi %d: %s\n', c, voi.VOI(c).Name);
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