function ROI_STEP6_extractROI

%params
p = ALL_STEP0_PARAMETERS;

%all splits?
if p.DO_ALL_SPLITS_VOI
    %full set of splits
    selections = combnk(1:p.NUMBER_OF_RUNS, floor(p.NUMBER_OF_RUNS/2));
    number_splits = size(selections, 1);
    selected = cell2mat(arrayfun(@(x) arrayfun(@(y) any(selections(x,:) == y), 1:p.NUMBER_OF_RUNS), 1:number_splits, 'UniformOutput', false)');

    %restrict to the "unique splits" - i.e., don't include [1 2 3] and [4 5 6] (opposite pairs) in a 6 run set
    %THE FULL SET OF SPLITS IS STILL USED, but only the unique half are computed
    %and then the final matrix is averaged with its transposition (more efficient)
    for i = number_splits:-1:1
        if any(~any(selected(1:(i-1),:) ~= ~selected(i,:), 2))
            selected(i,:) = [];
        end
    end
    
    do_all_split = true;
    
    fprintf('Split Method: full (%d splits)\n', size(selected,1)*2);
else
    selected = [];
    do_all_split = false;
    fprintf('Split Method: odd-even\n');
end

%paths
readFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '5. 3D Matrices of Betas' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep];

%create saveFol
if ~exist(saveFol)
    mkdir(saveFol)
end

%% process each voi
if ~iscell(p.VOI_FILE) && isnan(p.VOI_FILE)
    [voi_data,runtime] = process_voi(nan, p, readFol);
else
    if ~iscell(p.VOI_FILE)
        p.VOI_FILE = {p.VOI_FILE};
    end
    
    if size(p.VOI_FILE,1) == 1
        p.VOI_FILE = repmat(p.VOI_FILE, [p.NUMBER_OF_PARTICIPANTS 1]);
    end
    num_voi = size(p.VOI_FILE,2);
    
    for i = 1:num_voi
        voi_paths = p.VOI_FILE(:,i);
        
        fprintf('Processing VOI file %d of %d\n%s', i, num_voi, sprintf('\t%s\n',voi_paths{:}));
        [voi_data(i),d] = process_voi(voi_paths, p, readFol, do_all_split, selected);
        if i==1
            runtime = d;
        end
    end
end

%% merge
data = voi_data(1).data;
vtcRes = voi_data(1).vtcRes;

count_voi = size(data.RSM_split,4);

for i = 2:length(voi_data)
    
    if voi_data(i).vtcRes ~= vtcRes
        error('Inconsistent VTC Resolution!')
    end
    
    num_voi_add = size(voi_data(i).data.RSM_split,4);
    for j = 1:num_voi_add
        count_voi = count_voi + 1;
        data.RSM_split(:,:,:,count_voi) = voi_data(i).data.RSM_split(:,:,:,j);
        data.RSM_nonsplit(:,:,:,count_voi) = voi_data(i).data.RSM_nonsplit(:,:,:,j);
        data.VOINames{count_voi} = voi_data(i).data.VOINames{j};
        data.VOINames_short{count_voi} = voi_data(i).data.VOINames_short{j};
        data.VOInumVox(:,count_voi) = voi_data(i).data.VOInumVox(:,j);
    end
end

fprintf('Total VOIs: %d\n', count_voi);

%% save

runtime.Step6 = p.RUNTIME;
save([saveFol 'VOI_RSMs'],'data','vtcRes','runtime','do_all_split')
disp Done.

function [voi_data,runtime] = process_voi(voi_filepaths, p, readFol, do_all_split, selected)

%select
if ~iscell(voi_filepaths)
    if isnan(voi_filepaths)
        disp('Select a VOI file to use. This file will be used for all participants.')
        [fn_in,fp_in] = uigetfile('*.voi','VOI','INPUT','MultiSelect','off');
        voi_filepaths = repmat({[fp_in fn_in]}, [p.NUMBER_OF_PARTICIPANTS 1]);
    else
        error('Unexpected input voi_filepaths')
    end
end

%load
disp('Loading first VOI as reference...');
voi_ref = xff(voi_filepaths{1});

%init data struct
data.RSM_split = nan(p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS,voi_ref.NrOfVOIs);
data.RSM_nonsplit = nan(p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS,voi_ref.NrOfVOIs);
data.VOINames = cell(1,voi_ref.NrOfVOIs);
data.VOINames_short = cell(1,voi_ref.NrOfVOIs);
data.VOInumVox = zeros(1,voi_ref.NrOfVOIs);

%count
number_splits = size(selected,1);

%load sub data only once
disp('Processing participant data...')
for par = 1:p.NUMBER_OF_PARTICIPANTS
    fprintf('Processing participant %d of %d: %s\n', par, p.NUMBER_OF_PARTICIPANTS, p.FILELIST_PAR_ID{par});
    
    %load voi
    fprintf('\tLoading VOI: %s\n', voi_filepaths{par});
    voi = xff(voi_filepaths{par});
    
    %load data
    fprintf('\tLoading processed betas...\n');
    subdata = load(sprintf('%sstep3_organize3D_%s',readFol,p.FILELIST_PAR_ID{par}));
    
    %use settings of first file
    fprintf('\tChecking settings...\n');
    if ~exist('vtcRes', 'var')
        %func res
        vtcRes = subdata.vtcRes;
    elseif subdata.vtcRes ~= vtcRes
        error('mismatch in vtcRes')
    end
    
    %get first data runtime
    if ~exist('runtime', 'var') && isfield(subdata, 'runtime')
        runtime = subdata.runtime;
    end
    
    %prep ROIs
    fprintf('\tPreparing ROIs based on settings...\n');
    for vid = 1:voi.NrOfVOIs %for each voi...
       %name of voi
       if isempty(data.VOINames{vid})
            data.VOINames{vid} = voi.VOI(vid).Name;
            data.VOINames_short{vid} = data.VOINames{vid};
       end

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
       voi_xyz{vid,par} = xyz(find(~isnan(sum(xyz,2))),:);

       sz = size(subdata.betas_3D_even);
       sz = sz(1:3);
       inval = any( (voi_xyz{vid,par} < 1) | (voi_xyz{vid,par} > sz) , 2);
        if any(inval)
            num_keep = sum(~inval);
            num_toss = sum(inval);
            fprintf('Discarding %d voxels outside of bounding box (kept %d voxels)\n', num_toss, num_keep);
            voi_xyz{vid,par}(inval,:) = [];
        end

       %param
       data.VOInumVox(par,vid) = size(voi_xyz{vid,par},1);
    end
        
    %check do_all_split
    if (~isfield(subdata, 'do_all_split') || ~subdata.do_all_split) && do_all_split
        error('All splits mode is enabled, but step 5 was not run with all splits enabled. Rerun step 5.')
    end
       
    %calculate
    fprintf('\tCalculating RSMs...\n');
    for vid = 1:voi.NrOfVOIs %for each voi...
        fprintf('\t\tProcessing ROI %d of %d: %s (name in file: %s)\n', vid, voi.NrOfVOIs, data.VOINames{vid}, voi.VOI(vid).Name);
        
        %preinit [vox# cond# odd/even/all]
        betas = nan(data.VOInumVox(par,vid),p.NUMBER_OF_CONDITIONS,3);
        
        %for each cond, gather all betas
        for cond = 1:p.NUMBER_OF_CONDITIONS
            %all three matrices have the same shape so we only need one index
            ind_vox_thiscond = sub2ind(size(subdata.betas_3D_even),voi_xyz{vid,par}(:,1),voi_xyz{vid,par}(:,2),voi_xyz{vid,par}(:,3),repmat(cond,[data.VOInumVox(par,vid) 1]));
            
            betas(:,cond,1) = subdata.betas_3D_even(ind_vox_thiscond); %even
            betas(:,cond,2) = subdata.betas_3D_odd(ind_vox_thiscond); %odd
            betas(:,cond,3) = subdata.betas_3D_all(ind_vox_thiscond); %all
        end
        
        %if there are any missing values, remove the row (remove the voxel)
        if ~p.ALLOW_MISSING_CONDITIONS_IN_VOI_ANALYSIS
            indNotNan = find(~isnan(sum(sum(betas,3),2)));
            betas = betas(indNotNan,:,:);
        end
        
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
            
            if ~do_all_split
                %odd/even split method
                if length(evens)
                    data.RSM_split(c1,c2,par,vid) = corr(evens,odds,'type','Pearson');
                else
                    data.RSM_split(c1,c2,par,vid) = nan;
                end
            end
               
            if length(bothc1)
                data.RSM_nonsplit(c1,c2,par,vid) = corr(bothc1,bothc2,'type','Pearson');
            else
                data.RSM_nonsplit(c1,c2,par,vid) = nan;
            end
        end
        end
        
        %if do_all_split, calcualte split with all unique splits
        if do_all_split
            %init nan
            rsms = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS, number_splits);
            
            for split = 1:number_splits
                %init
                betas_group1 = nan(data.VOInumVox(par,vid), p.NUMBER_OF_CONDITIONS);
                betas_group2 = nan(data.VOInumVox(par,vid), p.NUMBER_OF_CONDITIONS);
                
                %process betas_3D_runs(x,y,z,run,cond)
                for v = 1:data.VOInumVox(par,vid)
                    %group 1
                    betas_run = squeeze(subdata.betas_3D_runs(voi_xyz{vid,par}(v,1), voi_xyz{vid,par}(v,2), voi_xyz{vid,par}(v,3), selected(split,:), :));
                    betas_group1(v,:) = nanmean(betas_run, 1) - nanmean(betas_run(:));
                    
                    %group 2
                    betas_run = squeeze(subdata.betas_3D_runs(voi_xyz{vid,par}(v,1), voi_xyz{vid,par}(v,2), voi_xyz{vid,par}(v,3), ~selected(split,:), :));
                    betas_group2(v,:) = nanmean(betas_run, 1) - nanmean(betas_run(:));
                end
                
                for c1 = 1:p.NUMBER_OF_CONDITIONS %group1
                for c2 = 1:p.NUMBER_OF_CONDITIONS %group2
                    %select conditions
                    group1c1 = betas_group1(:,c1);
                    group2c2 = betas_group2(:,c2);

                    %exclude nans
                    indNan = find(isnan(group1c1)|isnan(group2c2));
                    group1c1(indNan) = [];
                    group2c2(indNan) = [];

                    %corr (default nan)
                    if length(group1c1)
                        rsms(c1,c2,split) = corr(group1c1,group2c2,'type','Pearson');
                    else
                        rsms(c1,c2,split) = nan;
                    end
                end
                end
                
            end %for each split
            
            %average across RSMs from splits
            data.RSM_split(:,:,par,vid) = nanmean(rsms, 3);

        end %all split method
        
        %average odd/even and even/odd to create symmetrical RSM
        data.RSM_split(:,:,par,vid) = arrayfun(@(x,y) nanmean([x y]), data.RSM_split(:,:,par,vid), data.RSM_split(:,:,par,vid)');
    end
   
    voi.ClearObject;
    clear voi;
end

voi_data.data = data;
voi_data.vtcRes = vtcRes;

voi_ref.ClearObject;

if ~exist('runtime', 'var')
    runtime = struct;
end