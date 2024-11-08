% VMR_to_MSK(filepath_input_vmr, filepath_output_msk, args)
%
% Reads a VMR file, thresholds the intensity with a specified value, and
% writes the result as a MSK file.
%
% Requiered Inputs:
%   filepath_input_vmr      filepath to vmr file (or filename if local)
%
%   filepath_output_msk     filepath to write msk file (or filename if local)
%                           will overwrite existing files 
% 
% Optional Inputs:
%    intensity_threshold    threshold to apply to VMR intensity for
%                           generating mask
%
function VMR_to_MSK(filepath_input_vmr, filepath_output_msk, args)

arguments
    filepath_input_vmr (1,:) char {mustBeFile}
    filepath_output_msk (1,:) char
    args.intensity_threshold (1,1) uint8 = 10
end

% load vmr
fprintf('Loading: %s\n', filepath_input_vmr);
vmr = xff(filepath_input_vmr);

% Initialize msk
msk = xff('msk');
msk.Resolution = vmr.VoxResX;
msk.XStart = vmr.OffsetX;
msk.YStart = vmr.OffsetY;
msk.ZStart = vmr.OffsetZ;
msk.XEnd = vmr.OffsetX + vmr.DimX;
msk.YEnd = vmr.OffsetY + vmr.DimY;
msk.ZEnd = vmr.OffsetZ + vmr.DimZ;
bb = msk.BoundingBox;
bb = bb.BBox' - [0 1];
fprintf('Initialized msk with resolution %d and bounding box:\n\t%3d %3d %3d\n\t%3d %3d %3d\n', msk.Resolution, bb);

% Create Mask
fprintf('Creating mask from vmr with threshold of %d\n', args.intensity_threshold);
msk.Mask = vmr.VMRData >= args.intensity_threshold;

% Save
fprintf('Saving: %s\n', filepath_output_msk);
msk.SaveAs(filepath_output_msk);

% Done
disp Done!