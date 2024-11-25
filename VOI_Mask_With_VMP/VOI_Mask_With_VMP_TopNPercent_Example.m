% Filepath to input VOI (or filename if local)
filepath_in_voi = 'GSS.voi';

% Filepath to input VMP (or filename if local)
filepath_in_vmp = 'sub-01_task-3DReach_motion-static.vmp';

% Percent of voxels to select based on VMP map values (0 < pct <= 100)
percent_select = 50; % 50%

% Filepath to output VOI (will contain map-by-region)
filepath_out_voi = 'VOI_Mask_With_VMP_TopNPercent_Example.voi';

% Run
VOI_Mask_With_VMP_TopNPercent(  filepath_in_voi, ...
                                filepath_in_vmp, ...
                                filepath_out_voi, ...
                                percent_select )