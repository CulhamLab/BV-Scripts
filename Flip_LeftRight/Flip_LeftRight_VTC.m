function Flip_LeftRight_VMR

%% Parameters
SUFFIX = '_flipLR';
STOP_IF_OUTPUT_ALREADY_EXISTS = true;
FLIP_CONVENTION_TOO = true;

%% Select file
[filenames,directory,filter] = uigetfile('*.vtc', 'Select VTC(s) to Flip', 'MultiSelect', 'on');

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
    fn_out = [fn(1:end-4) SUFFIX '.vtc'];
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
    vtc = xff([directory fn]);
    
    %flip
    if FLIP_CONVENTION_TOO
        vtc.Convention = mod(vtc.Convention, 2) + 1;
    end
    vtc.VTCData = vtc.VTCData(:, :, :, end:-1:1);
    
    %save
    vtc.SaveAs([directory fn_out]);
    vtc.ClearObject;
    clear vtc
    
end

%% Done
disp Complete!