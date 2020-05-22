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
for pid = 1:p.NUMBER_OF_PARTICIPANTS
for mid = 1:numMod
    if size(p.MODELS.matrices{mid},3) > 1
        %indiv model
        mat_split = p.MODELS.matrices{mid}(:,:,pid);
        mat_nonsplit = p.MODELS.matricesNonsplit{mid}(:,:,pid);
        
    else
        %common model
        mat_split = p.MODELS.matrices{mid}(:,:,1);
        mat_nonsplit = p.MODELS.matricesNonsplit{mid}(:,:,1);
    end
    
    modelVecs_indxGood_split{mid,pid} = find(~isnan(mat_split(:)));
    modelVecs_indxGood_nonsplit{mid,pid} = find(~isnan(mat_nonsplit(:)));

    modelVecs_split{mid,pid} = mat_split(modelVecs_indxGood_split{mid,pid});
    modelVecs_nonsplit{mid,pid} = mat_nonsplit(modelVecs_indxGood_nonsplit{mid,pid});
end
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
           rsm_split_vec = rsm_split(modelVecs_indxGood_split{mid,par});
           ind_use = ~isnan(rsm_split_vec);
           if ~any(ind_use)
               corrs_split(par,mid,vid) = nan;
           else
               corrs_split(par,mid,vid) = corr(rsm_split_vec(ind_use), modelVecs_split{mid,par}(ind_use), 'type', 'Spearman');
           end
           
           %nonsplit
           rsm_nonsplit_vec = rsm_nonsplit(modelVecs_indxGood_nonsplit{mid,par});
           ind_use = ~isnan(rsm_nonsplit_vec);
           if ~any(ind_use)
               corrs_nonsplit(par,mid,vid) = nan;
           else
               corrs_nonsplit(par,mid,vid) = corr(rsm_nonsplit_vec(ind_use), modelVecs_nonsplit{mid,par}(ind_use), 'type', 'Spearman');
           end
       end
   end
end

rsms_nonsplit = data.RSM_nonsplit;
rsms_split = data.RSM_split;

voi_names = cellfun(@(x) strrep(strrep(x,'/',' '),'\', ' '), data.VOINames, 'UniformOutput', false);

runtime.Step7 = p.RUNTIME;
save([saveFol 'VOI_corrs'],'corrs_split','corrs_nonsplit','vtcRes','rsms_nonsplit','rsms_split','voi_names','runtime','do_all_split')
