function aux_SearchlightNoiseCeilingMap

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

%% Split Type
if p.SEARCHLIGHT_USE_SPLIT
    suffix = 'SPLIT';
    cell_selection = true(p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_CONDITIONS);
else
    suffix = 'NONSPLIT';
    cell_selection = false(p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_CONDITIONS);
    for i = 1:p.NUMBER_OF_CONDITIONS
        cell_selection(i,(i+1):end) = true;
    end
end
split = p.SEARCHLIGHT_USE_SPLIT;

%% Check Files

%load first file to get expected number of parts
filename_first = sprintf('step6_RSMs_%s_PART01_%s.mat', p.FILELIST_PAR_ID{1},suffix);
fprintf('Loading first file to check number of parts: %s\n', filename_first);
filepath_first = [DIR_IN filename_first];
if ~exist(filepath_first, 'file')
    error('Cannot located file: %s', filepath_first);
end
file = load([DIR_IN filename_first]);
number_parts = file.number_parts;
ss_ref = file.ss_ref;
vtcRes = file.vtcRes;
fprintf('Number of parts: %d\n', number_parts);

%determine if conversion from squareform rdm is needed
convert_sf_rdms = false;
if ~file.usedSplit
    ind_first = find(~cellfun(@isempty, file.RSMs), 1, 'first');
    if size(file.RSMs{ind_first},1) == 1
        convert_sf_rdms = true;
    end
end

%clear first file
clear file;

%check that all expected files are present
fprintf('Checking files...');
any_missing = false;
number_participants = length(p.FILELIST_PAR_ID);
for sub = 1:number_participants
    for part = 1:number_parts
        filename{sub,part} = sprintf('step6_RSMs_%s_PART%02d_%s.mat', p.FILELIST_PAR_ID{sub}, part, suffix);
        filepath = [DIR_IN filename{sub,part}];
        if ~exist(filepath, 'file')
            warning('Missing file: %s', filename{sub,part})
            any_missing = true;
        end
    end
    filename_too_many_parts = sprintf('step6_RSMs_%s_PART%02d_%s.mat', p.FILELIST_PAR_ID{sub}, number_parts+1, suffix);
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
tic
for part = 1:number_parts
    fprintf('\nRunning part %d of %d...\n', part, number_parts);
    
    fp_out = sprintf('%sPart%02d_%s.mat',DIR_OUT,part,suffix);
    if exist(fp_out,'file')
        fprintf('Output file already exists. This part will be skipped: %s\n', fp_out);
        continue;
    end
    
    %init
    map_ceiling_lower = nan(ss_ref);
    map_ceiling_upper = nan(ss_ref);
    map_leave_one_out_correlations = nan([ss_ref p.NUMBER_OF_PARTICIPANTS]);
    
    %loading (and checking)
    fprintf('\tLoading data...\n');
    files = cell(1, number_participants);
    clear part_min part_max part_max_actual
    for sub = 1:number_participants
        fprintf('\t\tLoading %d of %d: %s\n', sub,  number_participants, filename{sub,part});
        files{sub} = load([DIR_IN filename{sub,part}]);
        
        %check part_min and part_max
        if sub==1
            %set during first load of part
            part_min = files{sub}.part_min;
            part_max = files{sub}.part_max;
            part_max_actual = min(numel(files{sub}.RSMs) , part_max);
            fprintf('\t\t\tPart %02d spans voxel indices %d to %d\n', part, part_min, part_max);
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
        
        %check vtcRes
        if files{sub}.vtcRes ~= vtcRes
            error('VTC resolution is inconsistent in file: %s', filename{sub,part})
        end
        
        %convert from squareform rdm if needed
        if convert_sf_rdms
            ind = find(~cellfun(@isempty, files{sub}.RSMs));
            files{sub}.RSMs(ind) = cellfun(@(x) 1 - squareform(x), files{sub}.RSMs(ind), 'UniformOutput', false);
        end
    end
    fprintf('\tLoading completed at %g seconds\n', toc);
    
    %calculate for RSM for each sphere in the part
    fprintf('\tCalculating noise ceiling for each contained sphere');
    for ind_voxel = part_min:part_max_actual
        if ~mod(ind_voxel, 1000)
            fprintf('.');
        end
        
        ind_sub_with_data = find(cellfun(@(x) ~isempty(x.RSMs{ind_voxel}), files));
        number_subs_with_data = length(ind_sub_with_data);
        
        if number_subs_with_data > 1 %needs at least 2 subs with data
            [x,y,z] = ind2sub(ss_ref, ind_voxel);
            RSMs = reshape(cell2mat(cellfun(@(x) x.RSMs{ind_voxel}, files(ind_sub_with_data), 'UniformOutput', false)), [p.NUMBER_OF_CONDITIONS p.NUMBER_OF_CONDITIONS number_subs_with_data]);
            [upper, lower, map_leave_one_out_correlations(x,y,z,ind_sub_with_data)] = compute_rsm_noise_ceiling(RSMs, cell_selection);
            
            if number_subs_with_data == number_participants
                %store upper/lower only if no missing data
                map_ceiling_upper(x,y,z) = upper;
                map_ceiling_lower(x,y,z) = lower;
            end
        end
        
    end
    fprintf('\n\tCalculations completed at %g seconds\n', toc);
    
    %save
    fprintf('\tSaving to: %s\n',fp_out)
    save(fp_out,'map_ceiling_lower','map_ceiling_upper','map_leave_one_out_correlations','part_min','part_max','part_max_actual','number_parts','ss_ref','split');
    fprintf('\tSave completed at %g seconds\n', toc);
end

%% Create VMP

fprintf('\nCombining noise ceiling parts...\n');

%init
map_ceiling_lower = nan(ss_ref);
map_ceiling_upper = nan(ss_ref);
map_leave_one_out_correlations = nan([ss_ref p.NUMBER_OF_PARTICIPANTS]);

%combine
for part = 1:number_parts
    fp_load = sprintf('%sPart%02d_%s.mat',DIR_OUT,part,suffix);
    fprintf('\tAdding part %d of %d: %s\n', part, number_parts, fp_load);
    
    file = load(fp_load);
    map_ceiling_lower(file.part_min:file.part_max_actual) = file.map_ceiling_lower(file.part_min:file.part_max_actual);
    map_ceiling_upper(file.part_min:file.part_max_actual) = file.map_ceiling_upper(file.part_min:file.part_max_actual);
    
    for ind = file.part_min : file.part_max_actual
        [x,y,z] = ind2sub(ss_ref, ind);
        map_leave_one_out_correlations(x,y,z,:) = file.map_leave_one_out_correlations(x,y,z,:);
    end
    
    clear file;
end

%set nan to 0 for vmp
map_ceiling_lower(isnan(map_ceiling_lower)) = 0;
map_ceiling_upper(isnan(map_ceiling_upper)) = 0;
map_leave_one_out_correlations(isnan(map_leave_one_out_correlations)) = 0;

%prepare vmp struct
clear vmp
vmp = xff('vmp');

%bounding box (defined from params)
for f = fields(p.BBOX)'
    eval(['vmp.' f{1} ' = p.BBOX.' f{1} ';'])
end

%resolution (changing this SHOULD work)
vmp.Resolution = vtcRes;

%optional workaround
if p.LAST_DITCH_EFFORT_VMP_FIX
    vmp.XEnd = vmp.XEnd+vmp.Resolution;
    vmp.YEnd = vmp.YEnd+vmp.Resolution;
    vmp.ZEnd = vmp.ZEnd+vmp.Resolution;
end

mid = 1;
vmp.Map(mid).Name = 'Upper Bound';
vmp.Map(mid).LowerThreshold = 0.3;
vmp.Map(mid).UpperThreshold = 1.0;
vmp.Map(mid).VMPData = map_ceiling_upper;
vmp.Map(mid).ShowPositiveNegativeFlag = 3;
vmp.Map(mid).BonferroniValue = 0;
vmp.Map(mid).DF1 = 0;
vmp.Map(mid).DF2 = 0;

mid = 2;
vmp.Map(mid) = vmp.Map(1);
vmp.Map(mid).Name = 'Lower Bound';
vmp.Map(mid).LowerThreshold = 0.3;
vmp.Map(mid).UpperThreshold = 1.0;
vmp.Map(mid).VMPData = map_ceiling_lower;
vmp.Map(mid).ShowPositiveNegativeFlag = 3;
vmp.Map(mid).BonferroniValue = 0;
vmp.Map(mid).DF1 = 0;
vmp.Map(mid).DF2 = 0;

for pid = 1:p.NUMBER_OF_PARTICIPANTS
    mid = 2+pid;
    vmp.Map(mid) = vmp.Map(1);
    vmp.Map(mid).Name = sprintf('PAR%02d leave one out correlation', pid);
    vmp.Map(mid).LowerThreshold = 0.3;
    vmp.Map(mid).UpperThreshold = 1.0;
    vmp.Map(mid).VMPData = map_leave_one_out_correlations(:,:,:,pid);
    vmp.Map(mid).ShowPositiveNegativeFlag = 3;
    vmp.Map(mid).BonferroniValue = 0;
    vmp.Map(mid).DF1 = 0;
    vmp.Map(mid).DF2 = 0;
end

vmp.NrOfMaps = mid;

fp_vmp = sprintf('%sSearchlight_Noise_Ceiling_%s.vmp', DIR_OUT, suffix);
fprintf('Saving VMP: %s\n', fp_vmp);
vmp.SaveAs(fp_vmp);

%% Done
disp Complete!

%RSMs is Cond-by-Cond-by-Particpants, expected range -1 to +1
%(optional) selection is Cond-by-Cond logical where true indicates cells to include and false indicates cells to exclude
function [upper,lower,corrs_leave_one_out] = compute_rsm_noise_ceiling(RSMs, selection)
%checks and prep
if ndims(RSMs) ~= 3
    error('Requires 3D matrix.')
end
if any(isnan(RSMs(:)))
    error('Cannot have nan.')
end
if any(RSMs(:)==0)
    warning('Detected zeros. These are very likely to be unintended!')
end
[dim1, dim2, dim3] = size(RSMs);
n = dim1 * dim2;
if dim1 ~= dim2
    error('Requires square matrices.')
end

%0. reshape from n-by-n matrix to n^2-by-1 array
RSMs_array = cell2mat(arrayfun(@(x) reshape(RSMs(:,:,x), n, 1), 1:dim3, 'UniformOutput', false));

%apply selection
if exist('selection', 'var')
    if any(size(selection) ~= [dim1 dim2])
        error('Selection matrix must be #Cond-by#Cond')
    elseif ~islogical(selection)
        error('Selection matrix must be logical')
    end
    
    selection_index = find(selection(:));
    RSMs_array = RSMs_array(selection_index, :);
end

%convert to RDM (0=similar to 1=different)
RDMs = (1 - RSMs_array)/2;

% fisher z transform
RDMs_z = atanh(RDMs);

%calculate upper bound (mean correlation of each matrix to the mean matrix)
avg = nanmean(RDMs_z, 2);
corrs_full_average = arrayfun(@(x) corr(RDMs_z(:,x), avg, 'Type', 'Pearson'), 1:dim3);
upper = mean(corrs_full_average);

%calculate upper bound (mean correlation of each matrix to the leave-this-one-out matrix)
d3s = 1:dim3;
selections = arrayfun(@(x) d3s(d3s~=x), d3s, 'UniformOutput', false);
corrs_leave_one_out = arrayfun(@(x) corr(RDMs_z(:,x), nanmean(RDMs_z(:,selections{x}),2), 'Type', 'Pearson'), 1:dim3);
lower = mean(corrs_leave_one_out);