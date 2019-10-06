%tests the RSM of each voxel produced by step6 again each model defined in here
%saves a matrix of rvalues (X-Y-Z-model)
function SEARCHLIGHT_STEP07_correlateModelsNEW

%params
[p] = ALL_STEP0_PARAMETERS;

%paths
inputFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '6. 3D Matrices of RSMs' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '7. 3D Matrices of Model RValues' filesep];
if ~exist(saveFol,'dir')
    mkdir(saveFol);
end

%warn that p.USE_PARALLEL_POOLS is no longer used
if isfield(p, 'USE_PARALLEL_POOLS') && p.USE_PARALLEL_POOLS 
    warning('USE_PARALLEL_POOLS is no longer supported. Standard processing will be used.')
end

%% determine load prefix/suffix

prefix = 'step6';
if isempty(dir([inputFol prefix '*']))
    prefix = 'step4';
end

%test new suffix
if p.SEARCHLIGHT_USE_SPLIT
    suffix = '_SPLIT';
else
    suffix = '_NONSPLIT';
end
suffix_save = suffix;
fp_p1 = sprintf('%s%s_RSMs_%s_PART01%s.mat',inputFol, prefix, p.FILELIST_PAR_ID{1}, suffix);
if ~exist(fp_p1, 'file')
    %new suffix not present, try no suffix
    suffix = '';
    fp_p1 = sprintf('%s%s_RSMs_%s_PART01%s.mat',inputFol, prefix, p.FILELIST_PAR_ID{1}, suffix);
    if ~exist(fp_p1, 'file')
        %neither suffix present, cannot find first file
        error('Cannot find the first RSM file part of the first participant')
    end
end

%% load part 1 for info
fprintf('-Loading participant 1, part 1 and initializing...\n');
step6 = load(sprintf('%s%s_RSMs_%s_PART%02d%s.mat',inputFol, prefix, p.FILELIST_PAR_ID{1}, 1, suffix));
ss_ref = step6.ss_ref;
vtcRes = step6.vtcRes;
number_parts = step6.number_parts;

convert_sf_rdms = false;
if ~step6.usedSplit
    ind_first = find(~cellfun(@isempty, step6.RSMs), 1, 'first');
    if size(step6.RSMs{ind_first},1) == 1
        convert_sf_rdms = true;
    end
end

%% try
try %if anything goes wrong, close the parallel workers
tic
for par = 1:p.NUMBER_OF_PARTICIPANTS
fprintf('\nRunning participant %g of %g...\n',par,p.NUMBER_OF_PARTICIPANTS)
clearvars -except par p inputFol saveFol useParfor ss_ref vtcRes suffix prefix suffix_save convert_sf_rdms number_parts

%% prep models
%place in vectors
p.MODELS.mNum = size(p.MODELS.names,2);
for m = 1:p.MODELS.mNum
    if p.SEARCHLIGHT_USE_SPLIT
        modelVecs{m} = p.MODELS.matrices{m}(:);
    else
        %nonsplit
        modelVecs{m} = p.MODELS.matricesNonsplit{m}(:);
    end
    modelVecs_indxGood{m} = find(~isnan(modelVecs{m}));
    modelVecs{m} = modelVecs{m}(modelVecs_indxGood{m});
end
% save('ModelDat','modelVecs','modelVecs_indxGood','models')

%% init result matrix
resultMat = nan([ss_ref p.MODELS.mNum]);

%% get prior model correlations (optional)

fp_save = [saveFol sprintf('step7_modelCorrelations_%s%s.mat',p.FILELIST_PAR_ID{par},suffix_save)];
if p.SEACHLIGHT_MODEL_APPEND && exist(fp_save,'file')
    %load
    prior = load(fp_save);

    %check which models need to be run
    models_to_do = [];
    for m = 1:p.MODELS.mNum
        ind = find_model_matches(p.MODELS.matrices{m}, prior.models.matrices);
        if length(ind)==1
            %valid
            resultMat(:,:,:,m) = prior.resultMat(:,:,:,ind);
        else
            models_to_do(end+1) = m;
        end
    end
    
else
    %run all
    models_to_do = 1:p.MODELS.mNum;
end

num_models_run = length(models_to_do);
if ~num_models_run
    fprintf('-All models have already been run or there are no models\n');
    continue;
else
    fprintf('-%d of %d models will be run\n', num_models_run, p.MODELS.mNum);
end

%% test models

%process each part
for part = 1:number_parts
    fprintf('-Processing part %d of %d...\n', part, number_parts);
    
    %load
    step6 = load(sprintf('%s%s_RSMs_%s_PART%02d%s.mat',inputFol, prefix, p.FILELIST_PAR_ID{1}, part, suffix));

    %check size
    if any(step6.ss_ref ~= ss_ref)
        error('Size is not constant (ss_ref)!')
    end
	
	%check vtcRes
    if any(step6.vtcRes ~= vtcRes)
        error('VTC resolution is not constant (vtcRes)!')
    end
	
	%check usedSplit
	if (step6.usedSplit ~= p.SEARCHLIGHT_USE_SPLIT)
		error('Split is not constant (usedSplit)!')
    end
    
    %cheic number_parts
    if (step6.number_parts ~= number_parts)
        error('Number of parts is not constant (number_parts)!')
    end
    
    %convert squareform rdms back to RSMs (may stored this way in nonsplit mode to save time/space)
    if convert_sf_rdms
        ind = find(~cellfun(@isempty, step6.RSMs));
        step6.RSMs(ind) = cellfun(@(x) 1 - squareform(x), step6.RSMs(ind), 'UniformOutput', false);
    end
    
    %loop through part voxels
    for i = step6.indxVoxWithData_part'
        %has result in this center?
        if ~isempty(step6.RSMs{i})

            %coordinate
            [x,y,z] = ind2sub(ss_ref, i);

            %run each model
            for mn = 1:length(models_to_do)
                m = models_to_do(mn);

                %which to use
                if p.USE_SLOW_RSM_CALCULATION
                    indBad = find(isnan(step6.RSMs{i}(:)));
                    indVecUse = find(arrayfun(@(x) ~any(find(x==indBad)),modelVecs_indxGood{m}));
                    indUse = modelVecs_indxGood{m}(indVecUse);
                else
                    indVecUse = 1:length(modelVecs{m});
                    indUse = modelVecs_indxGood{m};
                end

                %correlate with model
                if ~isempty(indVecUse) && ~isempty(indUse)
                    resultMat(x,y,z,m) = corr(step6.RSMs{i}(indUse),modelVecs{m}(indVecUse),'type','Spearman');
                end
            end

        end
    end
    
    fprintf('  completed at %f seconds.\n',toc)
end

%% save
fprintf('Saving data ... ')
models = p.MODELS;
save(fp_save,'resultMat','models','vtcRes')
fprintf('saved at %f seconds.\n',toc)

end

%done!
fprintf('Completed RSM-model correlations.\n')

catch err
	try
		save
	catch
		warning('could not save workspace to file during error')
	end
    
    %rethrow error
    rethrow(err)
end

end%end of function



function [inds] = find_model_matches(source, targets)
inds = [];

ind_not_nan_source = find(~isnan(source(:)));
for i = 1:length(targets)
    ind_not_nan = find(~isnan(targets{i}(:)));
    %check nan implicit
    if (length(ind_not_nan_source) == length(ind_not_nan)) && ~any(ind_not_nan_source ~= ind_not_nan)
        %check non-nan
        if ~any(source(ind_not_nan_source) ~= targets{i}(ind_not_nan))
            inds(end+1) = i;
        end
    end
end
end