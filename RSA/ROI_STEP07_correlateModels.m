function ROI_STEP7_correlateModels

%params
p = ALL_STEP0_PARAMETERS;

%paths
readFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '7. ROI Model Correlations' filesep];

%create saveFol
if ~exist(saveFol)
    mkdir(saveFol)
end

%load ROI RSMs
load([readFol 'VOI_RSMs'])

%valid version?
if ~exist('runtime','var') || ~isfield(runtime, 'Step6') || runtime.Step6.VERSION<1
    error('The odd//even split method has been improved. Rerun from step 6.')
end

%count
numVOI = size(data.RSM_split,4);
numMod = length(p.MODELS.names);

%place models in vectors
for mid = 1:numMod
    modelVecs_indxGood_split{mid} = find(~isnan(p.MODELS.matrices{mid}(:)));
    modelVecs_indxGood_nonsplit{mid} = find(~isnan(p.MODELS.matricesNonsplit{mid}(:)));
    
    modelVecs_split{mid} = p.MODELS.matrices{mid}(modelVecs_indxGood_split{mid});
    modelVecs_nonsplit{mid} = p.MODELS.matricesNonsplit{mid}(modelVecs_indxGood_nonsplit{mid});
end

%init
corrs_split = nan(p.NUMBER_OF_PARTICIPANTS,numMod,numVOI);
corrs_nonsplit = nan(p.NUMBER_OF_PARTICIPANTS,numMod,numVOI);

for mid = 1:numMod
   for par = 1:p.NUMBER_OF_PARTICIPANTS
       for vid = 1:numVOI
           rsm_split = data.RSM_split(:,:,par,vid);
           rsm_nonsplit = data.RSM_nonsplit(:,:,par,vid);
           
           %split
           rsm_split_vec = rsm_split(modelVecs_indxGood_split{mid});
           corrs_split(par,mid,vid) = corr(rsm_split_vec,modelVecs_split{mid},'type','Spearman');
           
           %nonsplit
           rsm_nonsplit_vec = rsm_nonsplit(modelVecs_indxGood_nonsplit{mid});
           corrs_nonsplit(par,mid,vid) = corr(rsm_nonsplit_vec,modelVecs_nonsplit{mid},'type','Spearman');
       end
   end
end

rsms_nonsplit = data.RSM_nonsplit;
rsms_split = data.RSM_split;

voi_names = cellfun(@(x) strrep(strrep(x,'/',' '),'\', ' '), data.VOINames, 'UniformOutput', false);

runtime.Step7 = p.RUNTIME;
save([saveFol 'VOI_corrs'],'corrs_split','corrs_nonsplit','vtcRes','rsms_nonsplit','rsms_split','voi_names','runtime','do_all_split')
