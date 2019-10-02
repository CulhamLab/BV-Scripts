%WARNING: THIS SCRIPT IS INCOMPLETE
warning('THIS SCRIPT IS INCOMPLETE')

% % % function aux_SearchlightNoiseCeilingMap

%% Load Parameters

fprintf('Loading parameters...\n');
%remember where to come back to
return_path = pwd;
try
    %move to main folder
    cd ..

    %get params
    p = ALL_STEP0_PARAMETERS;
    
    %return to aux folder
    cd(return_path);
catch err
    cd(return_path);
    rethrow(err);
end

%% Directories

DIR_IN = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '6. 3D Matrices of RSMs' filesep];
DIR_OUT = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep 'aux_SearchlightNoiseCeilingMap' filesep];

if ~exist(DIR_IN, 'dir')
    error('Cannot located input directory: %s', DIR_IN);
end

if ~exist(DIR_OUT, 'dir')
    mkdir(DIR_OUT);
end

fprintf('Input Directory:\t%s\n', DIR_IN);
fprintf('Output Directory:\t%s\n', DIR_OUT);

%% Check Files

%load first file to get expected number of parts
filename_first = sprintf('step4_RSMs_%s_PART01.mat', p.FILELIST_PAR_ID{1});
fprintf('Loading first file to check number of parts: %s\n', filename_first);
filepath_first = [DIR_IN filename_first];
if ~exist(filepath_first, 'file')
    error('Cannot located file: %s', filepath_first);
end
file = load([DIR_IN filename_first]);
number_parts = file.number_parts;
ss_ref = file.ss_ref;
fprintf('Number of parts: %d\n', number_parts);
clear file;

%check that all expected files are present
fprintf('Checking files...');
any_missing = false;
number_participants = length(p.FILELIST_PAR_ID);
for sub = 1:number_participants
    for part = 1:number_parts
        filename{sub,part} = sprintf('step4_RSMs_%s_PART%02d.mat', p.FILELIST_PAR_ID{sub}, part);
        filepath = [DIR_IN filename{sub,part}];
        if ~exist(filepath, 'file')
            warning('Missing file: %s', filename{sub,part})
            any_missing = true;
        end
    end
    filename_too_many_parts = sprintf('step4_RSMs_%s_PART%02d.mat', p.FILELIST_PAR_ID{sub}, number_parts+1);
    if exist([DIR_IN filename_too_many_parts], 'file')
        error('Participant %d (%s) may have too many parts', sub, p.FILELIST_PAR_ID{sub})
    end
end
if any_missing
    error('One or more expected files are missing (see warnings above)')
else
    fprintf('all expected files were found\n');
end

%% Run

%init
map_ceiling_lower = nan(ss_ref);
map_ceiling_upper = nan(ss_ref);
map_leave_one_out_correlations = cell(ss_ref);

% TEMP ~~~~~~~~~~~~~~~~~~~~~
number_participants = 3
% TEMP ~~~~~~~~~~~~~~~~~~~~~

for part = 1:number_parts
    fprintf('\nRunning part %d of %d...\n', part, number_parts);
    
    %loading (and checking)
    fprintf('Loading data...\n');
    files = cell(1, number_participants);
    clear part_min part_max
    for sub = 1:number_participants
        fprintf('\tLoading %d of %d: %s\n', sub,  number_participants, filename{sub,part});
        files{sub} = load([DIR_IN filename{sub,part}]);
        
        %check part_min and part_max
        if sub==1
            %set during first load of part
            part_min = files{sub}.part_min;
            part_max = files{sub}.part_max;
            fprintf('Part %02d spans voxel indices %d to %d\n', part, part_min, part_max);
        else
            if files{sub}.part_min ~= part_min
                error('First voxel index mismatch! Expected %d but found %d for file: %s', part_min, files{sub}.part_min, filename{sub,part})
            elseif files{sub}.part_max ~= part_max
                error('Last voxel index mismatch! Expected %d but found %d for file: %s', part_max, files{sub}.part_max, filename{sub,part})
            end
        end
        
        %check number_parts
        if files{sub}.number_parts ~= number_parts
            error('Number of parts expected (%d) does not match number of parts in fileset (%d): %s', number_parts, files{sub}.number_parts, filename{sub,part});
        end
        
        %check ss_ref (and actual size of RSMs just to be safe)
        if any(files{sub}.ss_ref ~= ss_ref) || any(size(files{sub}.RSMs) ~= ss_ref)
            error('Data matrix size is incorrect in file: %s', filename{sub,part})
        end
    end
    fprintf('Loading complete.\n');
    
    %calculate for RSM at each index
    for ind_voxel = part_min:part_max
% % %         cellfun(@(x) isempty(x.RSMs(ind_voxel)), files)
    end
    error
end