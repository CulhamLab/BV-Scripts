function CountVolumes

%% Parameters

%path to the directory containing the participant subdirectories
DIRECTORY = 'H:\Lina_Tetris_fMRI_2019\Tetris_fMRI_Culham^RSA';

%regular experession for name of participant subdirectories ("\d" is a digit, "+" means one or more instances)
SUBDIR_NAME_FORMAT = 'P\d+';

%types of files to check
CHECK_VTC = true;
VTC_FORMAT = '*_3DMCTS_MNI_LTR_THP3c.vtc';
CHECK_SDM = true;
SDM_FORMAT = '*_PRT-and-3DMC.sdm';

%% Prepare
%must be checking at least one type of file
if ~CHECK_VTC && ~CHECK_SDM
    error('Must be set to check at least one type of file!')
end

%make sure DIRECTORY ends in file separator
if DIRECTORY(end) ~= filesep, DIRECTORY(end+1) = filesep; end

%DIRECTORY must exist
if ~exist(DIRECTORY, 'dir')
    error('Cannot find directory: %s', DIRECTORY);
end

%get list of potential subdir
list_subdir = dir(DIRECTORY);
list_subdir = list_subdir([list_subdir.isdir]);

%restrict list of subdir
list_subdir = list_subdir(cellfun(@(x) ~isempty(x) && x==1, cellfun(@(x) strcmp(x, regexp(x, SUBDIR_NAME_FORMAT, 'match')), {list_subdir.name}, 'UniformOutput', false)));

%sort
par_nums = cellfun(@(x) str2num(x(2:end)), {list_subdir.name});
[par_nums,order] = sort(par_nums);
subdirs = {list_subdir(order).name};
number_participants = length(subdirs);

%must have at least one subdir
if ~number_participants
    error('No valid participant subdirectories found!')
end

%% Get Volumes per File
xls_vtc = {'ParIndex', 'FileIndex', 'Participant', 'Filename', 'Number Volumes'};
xls_sdm = xls_vtc;
for p = 1:number_participants
    subdir = subdirs{p};
    par_num = par_nums(p);
    fulldir = [DIRECTORY subdir filesep];
    fprintf('Subdirectory %d of %d (%d: %s)\n', p, number_participants, par_num, subdir);
    
    if CHECK_SDM
        list = dir([fulldir SDM_FORMAT]);
        number_files = length(list);
        if number_files
            fprintf('-Found %d SDM files\n', number_files)
            for f = 1:number_files
                fn = list(f).name;
                sdm = xff([fulldir fn]);
                xls_sdm(end+1,:) = {p, f, par_num, fn, sdm.NrOfDataPoints};
                sdm.ClearObject;
                clear sdm;
            end
        else
            warning('No SDM files found!');
            xls_sdm(end+1,:) = {p, '', par_num, 'NO FILES', ''};
        end
    end
    
    if CHECK_VTC
        list = dir([fulldir VTC_FORMAT]);
        number_files = length(list);
        if number_files
            fprintf('-Found %d VTC files\n', number_files)
            for f = 1:number_files
                fn = list(f).name;
                vtc = xff([fulldir fn]);
                xls_vtc(end+1,:) = {p, f, par_num, fn, vtc.NrOfVolumes};
                vtc.ClearObject;
                clear vtc;
            end
        else
            warning('No VTC files found!');
            xls_vtc(end+1,:) = {p, '', par_num, 'NO FILES', ''};
        end
    end
end

%% Write Output
if CHECK_SDM
    fp = [DIRECTORY 'CheckVolumes_SDM.xlsx'];
    fprintf('\nWriting SDM Volumes: %s\n', fp);
    if exist(fp), delete(fp); end
    xlswrite(fp, xls_sdm);
end

if CHECK_VTC
    fp = [DIRECTORY 'CheckVolumes_VTC.xlsx'];
    fprintf('\nWriting VTC Volumes: %s\n', fp);
    if exist(fp), delete(fp); end
    xlswrite(fp, xls_vtc);
end

%% Done
disp Done.