function ROI_STEP6_extractROI

%params
p = ALL_STEP0_PARAMETERS;

%paths
readFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '5. 3D Matrices of Betas' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep];

%create saveFol
if ~exist(saveFol)
    mkdir(saveFol)
end

%load VOI file
if isnan(p.VOI_FILE)
    disp('Select a VOI file to use. This file should contain all ROIs.')
    [fn_in,fp_in] = uigetfile('*.voi','VOI','INPUT','MultiSelect','off');
    disp('Loading VOI...');
    voi = xff([fp_in fn_in]);
else
    disp('Loading VOI...');
    voi = xff(p.VOI_FILE);
end

%init data struct
data.RSM_split = nan(p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS,voi.NrOfVOIs);
data.RSM_nonsplit = nan(p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS,voi.NrOfVOIs);
data.VOINames = cell(1,voi.NrOfVOIs);
data.VOINames_short = cell(1,voi.NrOfVOIs);
data.VOInumVox = zeros(1,voi.NrOfVOIs);

%load sub data only once
disp('Loading subject data...')
for par = 1:p.NUMBER_OF_PARTICIPANTS
    preloaded_subdata(par) = load(sprintf('%sstep3_organize3D_%s',readFol,p.FILELIST_PAR_ID{par}));
end

vtcRes = preloaded_subdata(1).vtcRes;

disp('Calculating ROI RSMs...')
for vid = 1:voi.NrOfVOIs %for each voi...
   fprintf('Processing VOI %g of %g...\n',vid,voi.NrOfVOIs)
    
   %name of voi
   data.VOINames{vid} = voi.VOI(vid).Name;
   data.VOINames_short{vid} = data.VOINames{vid};
   
   %convert TAL VOI coords to save coords
   vox_TAL = voi.VOI(vid).Voxels;
   returnPath = pwd;
    try
        cd('Required Methods')
        [X,Y,Z] = SAVE_SYSTEM_COORD_CONVERSION( vox_TAL , vtcRes );
        cd ..
    catch e
        cd(returnPath)
        rethrow(e)
    end
   xyz = [X,Y,Z];
   
   %remove anything outside data
   xyz = xyz(find(~isnan(sum(xyz,2))),:);
   
   %param
   data.VOInumVox(vid) = size(xyz,1);
   
   %calculate RSM for each sub at this VOI
   for par = 1:p.NUMBER_OF_PARTICIPANTS
        %load sub betas
        subdata = preloaded_subdata(par);
        
        %preinit [vox# cond# odd/even/all]
        betas = nan(data.VOInumVox(vid),p.NUMBER_OF_CONDITIONS,3);
        
        %for each cond, gather all betas
        for cond = 1:p.NUMBER_OF_CONDITIONS
            %all three matrices have the same shape so we only need one index
            ind_vox_thiscond = sub2ind(size(subdata.betas_3D_even),xyz(:,1),xyz(:,2),xyz(:,3),repmat(cond,[data.VOInumVox(vid) 1]));
            
            betas(:,cond,1) = subdata.betas_3D_even(ind_vox_thiscond); %even
            betas(:,cond,2) = subdata.betas_3D_odd(ind_vox_thiscond); %odd
            betas(:,cond,3) = subdata.betas_3D_all(ind_vox_thiscond); %all
        end
        
        %if there are any missing values, remove the row (remove the voxel)
        indNotNan = find(~isnan(sum(sum(betas,3),2)));
        betas = betas(indNotNan,:,:);
        
        %%%%%NOT VERY EFFICIENT
        for c1 = 1:p.NUMBER_OF_CONDITIONS %even
        for c2 = 1:p.NUMBER_OF_CONDITIONS %odd
            %reminder: data.RSM_split = nan(p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_CONDITIONS,numSub,voi.NrOfVOIs);
            evens = betas(:,c1,1);
            odds = betas(:,c2,2);
            bothc1 = betas(:,c1,3);
            bothc2 = betas(:,c2,3);
            
            indNan = find(isnan(evens)|isnan(odds));
            evens(indNan) = [];
            odds(indNan) = [];
            
            indNan = find(isnan(bothc1)|isnan(bothc2));
            bothc1(indNan) = [];
            bothc2(indNan) = [];
            
            if length(evens)
                data.RSM_split(c1,c2,par,vid) = corr(evens,odds,'type','Pearson');
            else
                data.RSM_split(c1,c2,par,vid) = nan;
            end
               
            if length(bothc1)
                data.RSM_nonsplit(c1,c2,par,vid) = corr(bothc1,bothc2,'type','Pearson');
            else
                data.RSM_nonsplit(c1,c2,par,vid) = nan;
            end
        end
        end
   end
end

save([saveFol 'VOI_RSMs'],'data','vtcRes')
disp Done.