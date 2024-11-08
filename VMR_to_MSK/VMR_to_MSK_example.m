% Parameters
filepath_input_vmr = 'ICBM452-IN-MNI152-SPACE_BRAIN.vmr';
filepath_output_msk = 'BrainMask.msk';
intensity_threshold = 10;

% Run
VMR_to_MSK(filepath_input_vmr, filepath_output_msk, intensity_threshold=10)

% Output:
%
% VMR_to_MSK_example
% Loading: ICBM452-IN-MNI152-SPACE_BRAIN.vmr
% Initialized msk with resolution 1 and bounding box:
% 	  0   0   0
% 	255 255 255
% Creating mask from vmr with threshold of 10
% Saving: BrainMask.msk
% Done!