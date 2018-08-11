%demeans betas calculated in script1
%1) for each subject for each voxel the mean beta is calculated
%2) this mean beta is subtracted from all betas from this voxel
%3) betas are averaged across runs
%
%This process is performed for each subject independently
%
%
%two sets of demean values are generated...
%
%Set for split RSM (used by default):
%-even and odd runs are demeaned separetely
%-even and odd runs are averaged separately
%-yields two sets of prepared betas to compare against one another
%(asymetrical RSM)
%
%Set for nonsplit RSM (not default):
%-all runs are demeaned and averaged together
%-yields one set of prepared betas to be compared with itself (symetrical
%RSM)

function BOTH_step1_PREPARE4_demeanAndAverageBetas

%params
[p] = ALL_STEP0_PARAMETERS;

%paths
betaFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '1-2. Betas' filesep];
betaFolCondRemoved = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '3. Betas after condition removal' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '4. Demeaned and Averaged Betas' filesep];
if ~exist(saveFol,'dir')
    mkdir(saveFol);
end

%stop if condition replacement was expected but not found
if p.REMOVE_CERTAIN_CONDITIONS & ~exist(betaFolCondRemoved,'dir')
    error('It appears that condition removal is set true in parameters but has not been run. (Could not find second beta folder).')
end

%extra vars
numVox = 500000; %for pre-allocation, should be more than enough (if it isn't, the script will slow down but shouldn't break)

for par = 1:p.NUMBER_OF_PARTICIPANTS
fprintf('Running participant %g of %g...\n',par,p.NUMBER_OF_PARTICIPANTS)
clearvars -except betaFol betaFolCondRemoved saveFol numVox p par subIncludeSara

%allBetas_MeanAcrossRun = nan(numVox,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS); 
%oddBetas_MeanAcrossRun = nan(numVox,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS); 
%evenBetas_MeanAcrossRun = nan(numVox,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS); 

%allBetas = nan(numVox,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_RUNS);
%oddBetas = nan(numVox,p.NUMBER_OF_CONDITIONS,ceil(p.NUMBER_OF_RUNS/2)); 
%evenBetas = nan(numVox,p.NUMBER_OF_CONDITIONS,floor(p.NUMBER_OF_RUNS/2));

doOnce = 0;

for run = 1:p.NUMBER_OF_RUNS
    %pick removal file first
    folderToUse = betaFolCondRemoved;
    betaList = dir(sprintf('%s%s_%s*.mat',betaFolCondRemoved,p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run}));
    if length(betaList)>1
        error(sprintf('Too many files found in condition removed beta folder for SUB%02d RUN%02d.\n',par,run))
    elseif ~length(betaList)
        folderToUse = betaFol;
        betaList = dir(sprintf('%s%s_%s*.mat',betaFol,p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run}));
        if length(betaList)>1
            error(sprintf('Too many files found in beta folder for %s_%s.\n',p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run}))
        elseif ~length(betaList)
            error(sprintf('No file found in beta folder for %s_%s.\n',p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run}))
        end
    end

    %load
    loadPath = [folderToUse betaList.name];
    fprintf('-Loading betas for %s_%s: %s\n',p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run},loadPath)
    
    clear file
    file = load(loadPath);
    
    if ~doOnce
        %individualize numVox (w/ data)
        numVox = size(file.betas,1);
        %get vox coord
        vox = file.vox;
        vtcRes = file.vtcRes;
        %reinit for this first run
        allBetas_MeanAcrossRun = nan(numVox,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS); 
        oddBetas_MeanAcrossRun = nan(numVox,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS); 
        evenBetas_MeanAcrossRun = nan(numVox,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_PARTICIPANTS); 
        allBetas = nan(numVox,p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_RUNS);
        oddBetas = nan(numVox,p.NUMBER_OF_CONDITIONS,ceil(p.NUMBER_OF_RUNS/2)); 
        evenBetas = nan(numVox,p.NUMBER_OF_CONDITIONS,floor(p.NUMBER_OF_RUNS/2));
        %don't do this again
        doOnce = 1;
    elseif size(file.betas,1) ~= numVox
		error('Invalid number of voxels!')
    else
        %check vox coord
        if (size(vox,1) ~= size(file.vox,1)) | any(sum(vox - file.vox))
            error('Inconsistent voxel coords!')
        elseif file.vtcRes ~= vtcRes
            error('Inconsistent resolution.') %shouldn't be possible to reach this
        end
	end
    
    %set betas that are zero (condition not present in run) to nan *betas
    %won't be *exactly* zero by chance
    file.betas(file.betas==0) = nan;
    
    %keep only requested predictor betas + set order
    ind_pred_use = cellfun(@(x) find(cellfun(@(y) strcmp(x,y),file.conditionNames)), p.CONDITIONS.PREDICTOR_NAMES);
    file.betas = file.betas(:,ind_pred_use);
    
    %place in giant mat
    allBetas(:,:,run) = file.betas;
end

%display
fprintf('-Calculating demeaned betas (for even runs, odd runs, and all runs) and then saving...\n')

%split even and odd runs
evenBetas = allBetas(:,:,2:2:end);
oddBetas = allBetas(:,:,1:2:end);

%all
meanVector = nanmean(nanmean(allBetas,3),2);
meanMat = repmat(meanVector,[1 p.NUMBER_OF_CONDITIONS p.NUMBER_OF_RUNS]);
allBetas_MeanAcrossRun(:,:,par) = nanmean(allBetas - meanMat,3);

%odd
meanVector = nanmean(nanmean(oddBetas,3),2);
meanMat = repmat(meanVector,[1 p.NUMBER_OF_CONDITIONS ceil(p.NUMBER_OF_RUNS/2)]);
oddBetas_MeanAcrossRun(:,:,par) = nanmean(oddBetas - meanMat,3);

%even
meanVector = nanmean(nanmean(evenBetas,3),2);
meanMat = repmat(meanVector,[1 p.NUMBER_OF_CONDITIONS floor(p.NUMBER_OF_RUNS/2)]);
evenBetas_MeanAcrossRun(:,:,par) = nanmean(evenBetas - meanMat,3);

%mean across sub
allBetas_MeanAcrossSub = nanmean(allBetas_MeanAcrossRun,3);
oddBetas_MeanAcrossSub = nanmean(oddBetas_MeanAcrossRun,3);
evenBetas_MeanAcrossSub = nanmean(evenBetas_MeanAcrossRun,3);

%remove vox with no data (there are a few at corners sometimes)
indKeep = find(sum(~isnan(allBetas_MeanAcrossSub),2));
allBetas_MeanAcrossSub = allBetas_MeanAcrossSub(indKeep,:);
oddBetas_MeanAcrossSub = oddBetas_MeanAcrossSub(indKeep,:);
evenBetas_MeanAcrossSub = evenBetas_MeanAcrossSub(indKeep,:);
vox = vox(indKeep,:);

%save
conditions = p.CONDITIONS;
save([saveFol sprintf('step2_demeanAndAverageBetas_%s',p.FILELIST_PAR_ID{par})],'vox','allBetas_MeanAcrossSub','oddBetas_MeanAcrossSub','evenBetas_MeanAcrossSub','conditions','vtcRes')

end

fprintf('Complete demeaning and averaging step.\n')
end