% BIDSRename(folder_input, folder_output, name_prior, name_new)
%
% Creates a copy of a BIDS subject folder with renamed code. Specificially:
%   1. filenames are adjusted to use the new code
%   2. *.nii.gz are adjusted to contain files with the new code
%   3. *.json and *.tsv files have the codes adjusted
%
% INPUTS:
%
%   folder_input      char        Path to the root bids folder (contains sub-CODE subfolders)
%
%   folder_output     char        Path to create renamed duplicate in
%
%   name_prior        char        Include sub- (e.g., sub-AB12)
%
%   name_new          char        Include sub- (e.g., sub-01)
%
function BIDSRename(folder_input, folder_output, name_prior, name_new)

%% Prep

%folders end with filesep
if folder_input(end) ~= filesep
    folder_input = [folder_input filesep];
end
if folder_output(end) ~= filesep
    folder_output = [folder_output filesep];
end

%add subid to folder paths
folder_input = [folder_input name_prior filesep];
folder_output = [folder_output name_new filesep];

%input folder exists
if ~exist(folder_input, 'dir')
    error('Source folder does not exist: %s', folder_input);
end

%make output folder
if ~exist(folder_output, 'dir')
    fprintf('Creating output folder: %s\n', folder_output);
    mkdir(folder_output);
end

%% Step 1 - Copy Files With Rename

fprintf('Step 1: Copying files with renaming...\n');

%find all files
list = dir(fullfile(folder_input, '**', '*.*'));

%exclude folders
list = list(~[list.isdir]);

%copy each file with renaming
number_files = length(list);
for f = 1:number_files
    list(f).folder = [list(f).folder filesep];
    
    name = strrep(list(f).name, name_prior, name_new);
    fol = strrep(list(f).folder, folder_input, folder_output);
    fprintf('\tCopying file %d of %d:\n\t\tSource Folder: %s\n\t\tTarget Folder: %s\n\t\tSource Name: %s\n\t\tTarget Name: %s\n', f, number_files, list(f).folder, fol, list(f).name, name);
    
    if ~exist(fol, 'dir')
        mkdir(fol);
    end
    
    fp_out = [fol name];
    if exist(fp_out, 'file')
        fprintf('\t\t\tFile already exists. Skipping!\n');
    else
        copyfile([list(f).folder filesep list(f).name], fp_out);
    end
end

%% Step 2 - Correct Filenames Stored In .gz

fprintf('Step 2: Correcting names stored in .nii.gz files...\n');

%find all nii.gz
list = dir(fullfile(folder_output, '**', '*.nii.gz'));

%extract and recompress with renaming
number_files = length(list);
for f = 1:number_files
    fprintf('\tProcessing file %d of %d:\n\t\tFolder: %s\n\t\tName: %s\n', f, number_files, list(f).folder, list(f).name);
    
    fp = [list(f).folder filesep list(f).name];
    
    fid = fopen(fp, 'r');
    contents = char(fread(fid)');
    fclose(fid);
    
    if isempty(strfind(contents, name_prior))
        fprintf('\t\t\tDoes not contain prior subject name. Skipping!\n');
    else
        gunzip(fp);
        fp_nii = fp(1:end-3);
        gzip(fp_nii);
        delete(fp_nii);
    end
end

%% Step 3 - Rename inside json files

fprintf('Step 3: Correcting names stored in .json and .tsv files...\n');

%find all nii.gz
list_json = dir(fullfile(folder_output, '**', '*.json'));
list_tsv = dir(fullfile(folder_output, '**', '*.tsv'));
list = [list_json;list_tsv];

%extract and recompress with renaming
number_files = length(list);
for f = 1:number_files
    fprintf('\tProcessing file %d of %d:\n\t\tFolder: %s\n\t\tName: %s\n', f, number_files, list(f).folder, list(f).name);
    
    fp = [list(f).folder filesep list(f).name];
    
    fid = fopen(fp, 'r');
    contents = char(fread(fid)');
    fclose(fid);
    
    if isempty(strfind(contents, name_prior))
        fprintf('\t\t\tDoes not contain prior subject name. Skipping!\n');
    else
        contents = strrep(contents, name_prior, name_new);
        fid = fopen(fp, 'w');
        fprintf(fid, '%s', contents);
        fclose(fid);
    end
end

%% Done
disp Done.

