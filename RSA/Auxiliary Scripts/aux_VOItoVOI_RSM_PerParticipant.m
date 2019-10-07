function aux_VOItoVOI_RSM_PerParticipant

FP_OUT_SPLIT = 'aux_VOItoVOI_RSM_PerParticipant_split.xlsx';
FP_OUT_NONSPLIT = 'aux_VOItoVOI_RSM_PerParticipant_nonsplit.xlsx';

%% Load Parameters

fprintf('Loading parameters...\n');
%remember where to come back to
return_path = pwd;
try
    %move to main folder
    cd ..

    %get params
    p = ALL_STEP0_PARAMETERS;
    
    %return to aux folder
    cd(return_path);
catch err
    cd(return_path);
    rethrow(err);
end

%% Prep
load([p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep 'VOI_RSMs.mat']);
xls_split = cell(0);
xls_nonsplit = cell(0);
number_voi = length(data.VOInumVox);

selection_split = true(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
selection_nonsplit = false(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
for c = 1:p.NUMBER_OF_CONDITIONS
    selection_nonsplit(c,(c+1):end) = true;
end

if exist(FP_OUT_SPLIT, 'file')
    delete(FP_OUT_SPLIT);
end

if exist(FP_OUT_NONSPLIT, 'file')
    delete(FP_OUT_NONSPLIT);
end

%% Loop
fprintf('Processing...\n');
row = 0;
for pid = 1:p.NUMBER_OF_PARTICIPANTS
    voi_cond_rsms_nonsplit = arrayfun(@(v) data.RSM_nonsplit(:,:,pid,v), 1:number_voi, 'UniformOutput', false);
    voi_voi_rsm_nonsplit = CalculateVOIRSM(voi_cond_rsms_nonsplit, selection_nonsplit);
    
    voi_cond_rsms_split = arrayfun(@(v) data.RSM_split(:,:,pid,v), 1:number_voi, 'UniformOutput', false);
    voi_voi_rsm_split = CalculateVOIRSM(voi_cond_rsms_split, selection_split);
    
    row = row + 1;
    
    xls_split{row,1} = sprintf('P%02d', pid);
    xls_nonsplit{row,1} = sprintf('P%02d', pid);
    
    for v = 1:number_voi
        xls_split{row,1+v} = data.VOINames{v};
        xls_split{row+v,1} = data.VOINames{v};
        xls_nonsplit{row,1+v} = data.VOINames{v};
        xls_nonsplit{row+v,1} = data.VOINames{v};
    end
    
    xls_split(row+1:row+number_voi, 2:(number_voi+1)) = num2cell(voi_voi_rsm_split);
    xls_nonsplit(row+1:row+number_voi, 2:(number_voi+1)) = num2cell(voi_voi_rsm_nonsplit);
    
    row = row + number_voi + 1;
    
end

fprintf('Saving...\n');
xlswrite(FP_OUT_SPLIT, xls_split);
xlswrite(FP_OUT_NONSPLIT, xls_nonsplit);

fprintf('Done!\n');

function [rsm] = CalculateVOIRSM(rsms, selection)
rsms_array = cell2mat(cellfun(@(x) x(selection), rsms, 'UniformOutput', false));
rsm = corr(rsms_array,'Type','Spearman');