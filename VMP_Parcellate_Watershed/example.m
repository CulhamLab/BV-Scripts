% filepath_vmp            Path to the VMP. Output will be in the same folder as *_watershed.vmp
filepath_vmp = "C:\Data\test.vmp";

% use_map_thresholds      If true, then the lower thresholds set in the VMP maps will be used. Otherwise, maps will not be thresholded. (default: true)       
use_map_thresholds = true;

% polarity                Use only the postive, negative, or all values. (default: all)
polarity = "all";

% method                  Watershed algorithm to use. May be MATLAB, MATLAB2, or SPM. (default: MATLAB)
method = "MATLAB";

% max_depth_reduction     Increasing this value will decrease the number of parcels formed. Set 0 to disable. (default: 0)
max_depth_reduction = 5;

% voxel_adjacencies       When using either MATLAB method, this value (6, 18, or 26) sets the voxel adjacency rule. (default: 26)
%                               See: https://www.mathworks.com/help/images/ref/watershed.html#bupehwf-1-conn
voxel_adjacencies = 26;

% run
VMP_Parcellate_Watershed(filepath_vmp=filepath_vmp, ...
                         use_map_thresholds=use_map_thresholds, ...
                         polarity=polarity, ...
                         method=method, ...
                         max_depth_reduction=max_depth_reduction, ...
                         voxel_adjacencies=voxel_adjacencies);