function Flip_LeftRight_VMR

%% Parameters
SUFFIX = '_flipLR';
STOP_IF_OUTPUT_ALREADY_EXISTS = true;
FLIP_CONVENTION_TOO = true;

%% Select file
[filenames,directory,filter] = uigetfile('*.vmr', 'Select VMR(s) to Flip', 'MultiSelect', 'on');

%% Handle no files
if isnumeric(filenames)
    disp('No file select. Script will abort.')
    return;
end

%% Handle invalid selection
if filter ~=1
    error('Invalid file(s) selected!');
end

%% Handle single file
if ~iscell(filenames)
    filenames = {filenames};
end

%% Convention
if FLIP_CONVENTION_TOO
    fprintf('Convention will be flipped as well\n');
else
    fprintf('Convention will NOT be flipped\n');
end

%% Process files
number_files = length(filenames);
for fid = 1:number_files
    %display
    fn = filenames{fid};
    fn_out = [fn(1:end-4) SUFFIX '.vmr'];
    fprintf('File %d of %d: %s\n', fid, number_files, fn);
    
    %already exists?
    if exist([directory fn_out], 'file')
        message = sprintf('Flipped output already exists: %s', [directory fn_out]);
        if STOP_IF_OUTPUT_ALREADY_EXISTS
            error(message);
        else
            warning(message);
        end
    end
    
    %load
    vmr = xff([directory fn]);
    
    %require full cube
    if vmr.OffsetX || vmr.OffsetY || vmr.OffsetZ || any( size(vmr.VMRData) ~= [vmr.DimX vmr.DimY vmr.DimZ] ) || (vmr.DimX ~= vmr.FramingCube)
        error('Unsupported VMR Dimensions')
    end
    
    %flip
    if FLIP_CONVENTION_TOO
        vmr.Convention = mod(vmr.Convention, 2) + 1;
    end
    vmr.VMRData = vmr.VMRData(:, :, end:-1:1);
    
    %save
    vmr.SaveAs([directory fn_out]);
    vmr.ClearObject;
    clear vmr
    
end

%% Done
disp Complete!