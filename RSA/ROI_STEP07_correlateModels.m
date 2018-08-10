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

save([saveFol 'VOI_corrs'],'corrs_split','corrs_nonsplit','vtcRes')

%% everything below this point used to be another script
clearvars -except corrs_split corrs_nonsplit p saveFol data

%find unique VOI vals/inds
[unique_voi_nums,unique_voi_nums_ind] = unique(cellfun(@(x) x(4:find(x=='_',1)-1),data.VOINames_short,'UniformOutput',false)');

%find unique rad vals/inds
[unique_rad_nums,unique_rad_nums_ind] = unique(cellfun(@(x) x(find(x=='_',1)+4:end),data.VOINames_short,'UniformOutput',false)');

%%%%%%april 22 2015
numRAD_type = 1;
numVOI_type = length(data.VOINames);
% numVOI_type = length(unique_voi_nums);
% numRAD_type = length(unique_rad_nums);

for vid = 1:numVOI_type
for rid = 1:numRAD_type
    %%%%%%april 22 2015
%     vname_short = sprintf('voi%s_rad%s',unique_voi_nums{vid},unique_rad_nums{rid});
    vname_short = data.VOINames{vid};

    vind = find(cellfun(@(x) strcmp(x,vname_short),data.VOINames_short));
    if length(vind)~=1
        error('This error indicates that a VOI has a missing RAD type.')
    end
    
    vname = data.VOINames{vind};
    VOI_type_names{vid} = vname;
    
    corrs_split_organized(:,:,vid,rid) = corrs_split(:,:,vind);
	corrs_nonsplit_organized(:,:,vid,rid) = corrs_nonsplit(:,:,vind);
    rsms_nonsplit_organized(:,:,:,vid,rid) = data.RSM_nonsplit(:,:,:,vind);
    rsms_split_organized(:,:,:,vid,rid) = data.RSM_split(:,:,:,vind);
end
end

save([saveFol 'VOI_corrs_organized'],'rsms_split_organized','corrs_split_organized','corrs_nonsplit_organized','rsms_nonsplit_organized','VOI_type_names','unique_rad_nums')
