% function Resolve_FMR_Link_Bug

%% parameters
folder_backup = 'PreFix';
make_backup = true;

%% input
[files,filepath] = uigetfile('*.fmr', 'Select FMR(s) to fix');

if isnumeric(files)
    warning('No file selected. Stopping.')
    return
elseif ~iscell(files)
    files = {files};
end

%% prep
number_files = length(files);
folder_backup = [filepath folder_backup filesep];
if ~exist(folder_backup)
    mkdir(folder_backup)
end

%% process
fprintf('\nWorking in directory: %s\n', filepath);
for fid = 1:number_files
    fn = files{fid};
    fp = [filepath fn];
    fprintf('\nProcessing %d of %d (%s)...\n', fid, number_files, fn);
    
    fmr = xff(fp);
    
    %backup
    if make_backup
        fp_backup = [folder_backup fn];
        fprintf('* creating backup: %s\n', fp_backup);
        fmr.SaveAs(fp_backup);
    end
    
    %fix
    %% TO DO HERE
    
    %clear
    fmr.clear;
    
end

%% done
disp Done!