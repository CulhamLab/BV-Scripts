function FMR_to_NII

%% Parameters
folder = 'D:\Culham Lab\Pacman\derivatives\sub-01\ses-01\func';
search_term = '*.fmr';
overwrite = true;

%% Find Files
fprintf('Looking for "%s" in: %s\n', search_term, folder);
list = dir(fullfile(folder, '**', search_term));
number_files = length(list);
fprintf('\tFound %d file(s)\n', number_files);

%% No Files?
if isempty(list)
    fprintf('No files to process.\n')
    return
end

%% Process files
fprintf('Processing files...\n')
for i = 1:number_files
    file = list(i);
    fp_in = [file.folder filesep file.name];
    fprintf('%d of %d: %s\n', i, number_files, fp_in);

    [fol,name,~] = fileparts(fp_in);
    fp_out = [fol filesep name '.nii'];

    if ~exist(fp_out, 'file') || overwrite
        %convert
        fprintf('\tConverting...');
        fmr = xff(fp_in);
        fmr.ExportNifti(fp_out);
        fmr.ClearObject;
        fprintf('complete!\n');

    else
        %skip
        fprintf('\tOutput file already exists and "overwrite" if false. Skipping...\n');
    end

end

%% Done
disp Done!