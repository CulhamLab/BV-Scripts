function BOTH_step1_PREPARE3_removeFlaggedErrors

%params + stop if params set fase
[p] = ALL_STEP0_PARAMETERS;
if ~p.REMOVE_CERTAIN_CONDITIONS
    warning(sprintf('Stopping %s before any conditions have been removed because parameter is set false.\n',mfilename))
    return
end

%folders
folRead = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '1-2. Betas' filesep];
folSave = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '3. Betas after condition removal' filesep];
if ~exist(folSave,'dir')
    mkdir(folSave)
end

%read toRemove
if ~exist('toRemove.mat','file')
    error('toRemove.mat could not be found.')
end
load('toRemove')

for par = 1:p.NUMBER_OF_PARTICIPANTS
    for run = 1:p.NUMBER_OF_RUNS
        %clear prior values
        clearvars -except par run folRead folSave p toRemoveMatrix
        
        %are there any conditions to remove?
        condsToRemove = toRemoveMatrix(find(toRemoveMatrix(:,1)==par & toRemoveMatrix(:,2)==run),3);
        
        %stop if there are no conditions to remove from this run
        if ~length(condsToRemove)
            continue
        end
        
        %display
        fprintf('Removing %d conditions from %s_%s: %s\n',length(condsToRemove),p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run},sprintf('%d ',condsToRemove))
        
        %load in the beta file
        list = dir(sprintf('%s%s_%s*.mat',folRead,p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run})); 
        if length(list)==0
            error(sprintf('No file found for %s_%s.\n',p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run}))
        elseif length(list)>1
            error(sprintf('Too many files found for %s_%s.\n',p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run}))
        end
        loadname = list(1).name;
        load(sprintf('%s%s',folRead,loadname))
        
        %set these beta for each voxel for these conditions to nan
        betas(:,condsToRemove) = nan;
        
        %resave in new folder
        removalNotice = sprintf('The following conditions were intentionally set to nan: %s',sprintf('%d ',condsToRemove));
        if ~exist('notice','var')
            save(sprintf('%s%s',folSave,loadname),'betas','vox','vtcRes','sdmFilepath','vtcFilepath','voiWholeBrain','VariableHelp','removalNotice','conditionNames');
        else
            save(sprintf('%s%s',folSave,loadname),'betas','vox','vtcRes','sdmFilepath','vtcFilepath','voiWholeBrain','VariableHelp','notice','removalNotice','conditionNames');
        end
    end
end