% Filepath to input VOI (or filename if local)
filepath_in_voi = 'GSS.voi';

% Filepath to input VMP (or filename if local)
filepath_in_vmp = 'sub-01_task-3DReach_motion-static.vmp';

% VMP Threshold (selects value >= threshold)
threshold = 1.0;

% Filepath to output VOI (will contain map-by-region)
filepath_out_voi = 'VOI_Mask_With_VMP_Example.voi';

% Run
VOI_Mask_With_VMP(filepath_in_voi, ...
                  filepath_in_vmp, ...
                  filepath_out_voi, ...
                  threshold)