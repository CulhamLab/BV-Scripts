function aux_participant_averaged_RSM_excel

%% parameters
USE_SPLIT_DATA = true;
FISHER_TRANSFORM_RSM = true; %do not set true if data has not already been Fisher-transformed

%% read main parameters
return_path = pwd;
main_path = ['..' filesep];
try
    cd(main_path)
    p = ALL_STEP0_PARAMETERS;
    cd(return_path);
catch err
    cd(return_path);
    rethrow(err);
end

%% read VOI RSMs
try
    load([main_path p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep 'VOI_RSMs.mat']);
catch err
    warning('Could not load VOI RSMs. Has VOI step6 been run or has data moved?')
    rethrow(err);
end

%% prep 

%select data
if USE_SPLIT_DATA
    RSMs = data.RSM_split;
    type_name = 'SPLIT';
else
    RSMs = data.RSM_nonsplit;
    type_name = 'NONSPLIT';
end

%add Fisher transform (optional)
if FISHER_TRANSFORM_RSM
    RSMs = atanh(RSMs);
end

%output file name
filename_output = ['Participant-Averaged_RSM_' type_name];
if FISHER_TRANSFORM_RSM
    filename_output = [filename_output '_AddFisher'];
end
filename_output = [filename_output '.xls'];

%delete prior
if exist(filename_output,'file')
    delete(filename_output);
end

%% run

number_voi = length(data.VOINames);
number_cond = size(RSMs,1);

xls = cell(0,number_cond);

xls{1,1} = 'Use Split Data:';
xls{1,2} = USE_SPLIT_DATA;

xls{2,1} = 'Add Fisher Transform:';
xls{2,2} = FISHER_TRANSFORM_RSM;

xls{3,1} = [];

for v = 1:number_voi
    fprintf('Running VOI %d of %d (%s)\n', v, number_voi, data.VOINames{v})

    xls{end+1,1} = data.VOINames{v};
    
    RSMs_voi = RSMs(:,:,:,v);
    RSMs_voi_parmean = nanmean(RSMs_voi,3);
    
    xls = [xls; num2cell(RSMs_voi_parmean)];
    
    xls{end+1,1} = [];
end

xlswrite(filename_output, xls);

disp Done.

