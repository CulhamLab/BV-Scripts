function BOTH_step1_PREPARE2_fillMissingRuns

%where is data and output folder
[p] = ALL_STEP0_PARAMETERS;
fol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '1-2. Betas' filesep];
if ~exist(fol,'dir')
    mkdir(fol)
end

%create temp folder
fillerFol = [fol 'temp' filesep];
if ~exist(fillerFol,'dir')
mkdir(fillerFol)
end

[~,~,filelist] = xlsread(p.FILELIST_FILENAME);

for par = 1:p.NUMBER_OF_PARTICIPANTS
    clearvars -except par fol p fillerFol filelist
    
    id = p.FILELIST_PAR_ID{par};
    
    list_findagood = dir(sprintf('%s%s_*.mat',fol,id));
    
    %create a blank fill in
    fillerPath = [fillerFol sprintf('%s.mat',id)];
    load([fol list_findagood(1).name]);
    betas(:) = nan;
    notice = sprintf('this file was created as a nan fill of %s',[fol list_findagood(1).name]);
    save(fillerPath,'betas','vox','vtcRes','sdmFilepath','vtcFilepath','voiWholeBrain','VariableHelp','notice','conditionNames');
    
    for run = 1:p.NUMBER_OF_RUNS
        list_findme = dir(sprintf('%s%s_%s.mat',fol,p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run}));
        if ~length(list_findme)
            warning(sprintf('%s_%s was missing and has been filled with NaNs.\n',p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run}))
            copyfile(fillerPath,strrep(sprintf('%s%s_%s_filler.mat',fol,p.FILELIST_PAR_ID{par},p.FILELIST_RUN_ID{run}), '*', ''))
        end
    end
    
end

%clear temp folder
close all
if exist(fillerFol,'dir')
rmdir(fillerFol,'s')
end

fprintf('Complete search and fill for missing runs.\n')

end