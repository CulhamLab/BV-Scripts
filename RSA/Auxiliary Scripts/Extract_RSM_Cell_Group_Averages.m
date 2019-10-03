function Extract_RSM_Cell_Group_Averages

%read main parameters
p = Get_Main_Params;

%% EDIT HERE - parameters
USE_SPLIT_DATA = true;
ALLOW_EXCEL_OVERWRITE = true;
FILEPATH_EXCEL_OUTPUT = 'Extract_RSM_Group_Averages_[SPLITTYPE].xlsx'; %replaces [SPLITTYPE] with SPLIT or NONSPLIT
FILEPATH_FIGURE = 'Extract_RSM_Group_Averages_[SPLITTYPE].png';

%% EDIT HERE - Define Groups
%cycles though each row/col pair and uses the cell if either:
%   selection(1,row) && selection(2,col)
%   selection(2,row) && selection(1,col)

g = 0; %leave this first

%EXAMPLE:
% % g=g+1;
% % group(g).name = 'Food-Food';
% % group(g).selection = [cellfun(@(x) any(strfind(x, 'Food_')), p.CONDITIONS.PREDICTOR_NAMES);
% %                       cellfun(@(x) any(strfind(x, 'Food_')), p.CONDITIONS.PREDICTOR_NAMES)];
% % 
% % g=g+1;
% % group(g).name = 'Food1H-Food1H';
% % group(g).selection = [cellfun(@(x) any(strfind(x, 'Food_1H_')), p.CONDITIONS.PREDICTOR_NAMES);
% %                       cellfun(@(x) any(strfind(x, 'Food_1H_')), p.CONDITIONS.PREDICTOR_NAMES)];
% % 
% % g=g+1;
% % group(g).name = 'Food2H-Food2H';
% % group(g).selection = [cellfun(@(x) any(strfind(x, 'Food_2H_')), p.CONDITIONS.PREDICTOR_NAMES);
% %                       cellfun(@(x) any(strfind(x, 'Food_2H_')), p.CONDITIONS.PREDICTOR_NAMES)];
% % g=g+1;
% % group(g).name = 'Food1H-Body1H';
% % group(g).selection = [cellfun(@(x) any(strfind(x, 'Food_1H_')), p.CONDITIONS.PREDICTOR_NAMES);
% %                       cellfun(@(x) any(strfind(x, 'Body_1H_')), p.CONDITIONS.PREDICTOR_NAMES)];
% % g=g+1;
% % group(g).name = 'Food1H-andor-Body1H'; %Food1H-Food1H or Body1H-Body1H or Food1H-Body1H
% % group(g).selection = [cellfun(@(x) any(strfind(x, 'Food_1H_')), p.CONDITIONS.PREDICTOR_NAMES) | cellfun(@(x) any(strfind(x, 'Body_1H_')), p.CONDITIONS.PREDICTOR_NAMES);
% %                       cellfun(@(x) any(strfind(x, 'Food_1H_')), p.CONDITIONS.PREDICTOR_NAMES) | cellfun(@(x) any(strfind(x, 'Body_1H_')), p.CONDITIONS.PREDICTOR_NAMES)];






%% YOU DO NOT NEED TO EDIT BELOW HERE





%% check groups

if ~exist('group', 'var')
    error('Group structure array must be defined')
end

number_groups = length(group);

if ~number_groups
    error('No groups detected (empty group structure array)')
end

for gid = 1:number_groups
    if isempty(group(gid).name) || iscell(group(gid).name) || ~ischar(group(gid).name)
        error('Invalid group name in group #%d', gid);
    end
    
    if size(group(gid).selection,1) ~=2
        error('Selection criteria does not have 2 rows in #%d', gid);
    end
    
    if size(group(gid).selection,2) ~= p.NUMBER_OF_CONDITIONS
        error('Selection criteria length does not match number of predictors in #%d', gid);
    end
    
    if ~any(group(gid).selection)
        error('Selection criteria is a valid shape but does not contain in true values in #%d', gid);
    end
end

if length(unique({group.name})) ~= number_groups
    error('Group names contains a duplicate')
end

%% output filename
if USE_SPLIT_DATA
    type = 'SPLIT';
else
    type = 'NONSPLIT';
end
FILEPATH_EXCEL_OUTPUT = strrep(FILEPATH_EXCEL_OUTPUT, '[SPLITTYPE]', type);
FILEPATH_FIGURE = strrep(FILEPATH_FIGURE, '[SPLITTYPE]', type);

%% overwrite?
if exist(FILEPATH_EXCEL_OUTPUT, 'file')
    if ~ALLOW_EXCEL_OVERWRITE
        error('Output file already exists and overwrite is disabled: %s', FILEPATH_EXCEL_OUTPUT)
    else
        warning('Output file already exists and overwrite is enabled. File will be overwritten: %s', FILEPATH_EXCEL_OUTPUT);
    end
end

%% read VOI RSMs
fprintf('Loading VOI RSMs...\n');
try
    load([p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep 'VOI_RSMs.mat']);
catch err
    warning('Could not load VOI RSMs. Has VOI step6 been run or has data moved?')
    rethrow(err);
end

%% Split/NonSplit
fprintf('Selecting split or nonsplit data...\n');
if USE_SPLIT_DATA
    RSMs = data.RSM_split;
    rsm_ind_use = true(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
else
    RSMs = data.RSM_nonsplit;
    rsm_ind_use = false(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    for i = 1:p.NUMBER_OF_CONDITIONS
        rsm_ind_use(i,(i+1):end) = true;
    end
end

%% Init Excel
xls = cell(0);

%% Calculate Averages
fprintf('Calculating group averages per participant...\n');
number_vois = length(data.VOINames);
row = 0;
created_figure = false;
for voi = 1:number_vois
    row = row + 1;
    xls{row,1} = data.VOINames{voi};
    
    for pid = 1:p.NUMBER_OF_PARTICIPANTS
        if pid == 1
            for gid = 1:number_groups
                xls{row, 1+gid} = group(gid).name;
            end
            row = row + 1;
        end
        
        xls{row,1} = sprintf('P%02d', pid);
        
        rsm = RSMs(:,:,pid,voi);
        
        if ~any(isnan(rsm(:)))
            rsm(~rsm_ind_use) = nan;
            selections = false(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS, number_groups);
            
            for gid = 1:number_groups
                values = [];
                
                for c1 = 1:p.NUMBER_OF_CONDITIONS
                    for c2 = 1:p.NUMBER_OF_CONDITIONS
                        if ~isnan(rsm(c1,c2)) && ( (group(gid).selection(1,c1) && group(gid).selection(2,c2)) || (group(gid).selection(2,c1) && group(gid).selection(1,c2)) )
                            values(end+1) = rsm(c1,c2);
                            selections(c1,c2,gid) = true;
                        end
                    end
                end
                
                xls{row, 1+gid} = mean(values);

            end
            
            if ~created_figure
                fig = figure('Position', [1 1 1500 1000]);
                
                ncol = ceil(sqrt(number_groups));
                if (ncol*(ncol-1)) < number_groups
                    nrow = ncol;
                else
                    nrow = ncol-1;
                end
                
                for gid = 1:number_groups
                    subplot(nrow, ncol, gid);
                    imagesc(selections(:,:,gid));
                    axis square;
                    colormap([0 0 0; 0 1 0])
                    title(strrep(group(gid).name,'_',' '));
                end
                
                fprintf('Saving selections to: %s\n', FILEPATH_FIGURE);
                saveas(fig, FILEPATH_FIGURE);
                close(fig)
                created_figure = true;
            end
        end
        row = row + 1;
        
    end
end

%% Save
fprintf('Writing to: %s\n', FILEPATH_EXCEL_OUTPUT);
if exist(FILEPATH_EXCEL_OUTPUT, 'file')
    delete(FILEPATH_EXCEL_OUTPUT);
end
xlswrite(FILEPATH_EXCEL_OUTPUT, xls);

%% Done
fprintf('Complete!\n');




%%
function [p] = Get_Main_Params
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