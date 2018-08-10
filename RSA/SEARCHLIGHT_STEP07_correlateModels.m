%tests the RSM of each voxel produced by step4 again each model defined in here
%saves a matrix of rvalues (X-Y-Z-model)
%
%takes ~5min per subject

function SEARCHLIGHT_step3_correlateModels

%params
[p] = ALL_STEP0_PARAMETERS;

%paths
inputFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '6. 3D Matrices of RSMs' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '7. 3D Matrices of Model RValues' filesep];
if ~exist(saveFol,'dir')
    mkdir(saveFol);
end

%open parallel workers (try 4 and work down to 2)
useParfor = false; %default;
if p.USE_PARALLEL_POOLS 
    if exist('parpool', 'file')
        useParfor = false;
        warning('Parallel pool has not been updated for latest MATLAB. Parfor will not be used.')
    elseif exist('matlabpool')
        useParfor = true;
        if ~matlabpool('size') %only open more if workers are not already created
            for poolsize = 4:-1:2
                try
                    fprintf('Attempting to open %d parallel workers.\n\n',poolsize);
                    eval(['matlabpool open ' num2str(poolsize)])
                    fprintf('\nSUCCESS! %d parallel workers will be used.\n\n',poolsize);
                    break;
                catch
                    fprintf('Could not open %d parallel workers.\n\n',poolsize);
                end
            end

            if ~matlabpool('size')
                error('This computer thinks it supports parfor but encountered an issue. Try manually entering "matlabpool close" and executing the script again.') %won't work
            end
        end
    end
end

try %if anything goes wrong, close the parallel workers
tic
for par = 1:p.NUMBER_OF_PARTICIPANTS
fprintf('\nRunning participant %g of %g...\n',par,p.NUMBER_OF_PARTICIPANTS)
clearvars -except par p inputFol saveFol useParfor

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

%% get prior model correlations (optional)

fp_save = [saveFol sprintf('step5_modelCorrelations_%s.mat',p.FILELIST_PAR_ID{par})];
if p.SEACHLIGHT_MODEL_APPEND && exist(fp_save,'file')
    %load
    prior = load(fp_save);
    ss = size(prior.resultMat);
    resultMat = nan([ss(1:3) p.MODELS.mNum]);

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

%% test models
clear ss
num_models_run = length(models_to_do);
if ~num_models_run
    fprintf('All models have already been run ...\n');
    vtcRes = prior.vtcRes;
else
    fprintf('Loading RSMs ...\n');
    load([inputFol sprintf('step4_RSMs_%s',p.FILELIST_PAR_ID{par})])
    
    if ~exist('resultMat','var')
        ss = size(RSMs);
        resultMat = nan([ss p.MODELS.mNum]);
    end
    pctAchieved = 0;
    numElem=numel(RSMs);
end

if ~exist('ss','var')
    ss = size(RSMs);
end

for mn = 1:length(models_to_do)
    m = models_to_do(mn);
    fprintf('Starting model %d (%d of %d to run) ... ',m,mn,num_models_run)
    
    %work in model-specific 3D
    resultMat_this = nan(ss);
    
    %parallel loop through all voxels' RSM
    if useParfor
        parfor i = 1:numElem
            %has result in this center?
            if numel(RSMs{i})
                %which to use
                if p.USE_SLOW_RSM_CALCULATION
                    indBad = find(isnan(RSMs{i}(:)));
                    indVecUse = find(arrayfun(@(x) ~any(find(x==indBad)),modelVecs_indxGood{m}));
                    indUse = modelVecs_indxGood{m}(indVecUse);
                else
                    indVecUse = 1:length(modelVecs{m});
                    indUse = modelVecs_indxGood{m};
                end
                
                %correlate with model
                if length(indVecUse) && length(indUse)
                    resultMat_this(i) = corr(RSMs{i}(indUse),modelVecs{m}(indVecUse),'type','Spearman');
                end
            end
        end
    else
        for i = 1:numElem
            %has result in this center?
            if numel(RSMs{i})
                %which to use
                if p.USE_SLOW_RSM_CALCULATION
                    indBad = find(isnan(RSMs{i}(:)));
                    indVecUse = find(arrayfun(@(x) ~any(find(x==indBad)),modelVecs_indxGood{m}));
                    indUse = modelVecs_indxGood{m}(indVecUse);
                else
                    indVecUse = 1:length(modelVecs{m});
                    indUse = modelVecs_indxGood{m};
                end
                
                %correlate with model
                resultMat_this(i) = corr(RSMs{i}(indUse),modelVecs{m}(indVecUse),'type','Spearman');
            end
        end
    end
    
    try
    resultMat(:,:,:,m) = resultMat_this;
    catch err
        save
        rethrow(err)
    end
    
    fprintf('completed at %f seconds.\n',toc)
end

%% save
fprintf('Saving data ... ')
models = p.MODELS;
save(fp_save,'resultMat','models','vtcRes')
fprintf('saved at %f seconds.\n',toc)

end

%close parallel workers
if useParfor
    matlabpool close
end

%done!
fprintf('Completed RSM-model correlations.\n')

catch err
    %close parallel workers
    if exist('useParfor','var') && useParfor
        matlabpool close
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