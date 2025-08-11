function Extract_RSM_Cell_Group_Averages

%read main parameters
[p,dir_main] = Get_Main_Params;

%% EDIT HERE - parameters
USE_SPLIT_DATA = true;
ALLOW_EXCEL_OVERWRITE = true;
FILEPATH_MAT = 'Extract_RSM_Group_Averages_[SPLITTYPE].mat';
FILEPATH_EXCEL_OUTPUT = 'Extract_RSM_Group_Averages_[SPLITTYPE].xlsx'; %replaces [SPLITTYPE] with SPLIT or NONSPLIT
FILEPATH_FIGURE = 'Extract_RSM_Group_Averages_[SPLITTYPE]_[GROUP].png';

%% EDIT HERE - Define Groups
%cycles though each row/col pair and uses the cell if either:
%   selection(1,row) && selection(2,col)
%   selection(2,row) && selection(1,col)
%
%exclude is an optional field that excludes cells from one or more other groups
%when used, exclude is a cell array of group names: {'name1' 'name2'}

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
% % 
% % g=g+1;
% % group(g).name = 'Food1H-Body1H';
% % group(g).selection = [cellfun(@(x) any(strfind(x, 'Food_1H_')), p.CONDITIONS.PREDICTOR_NAMES);
% %                       cellfun(@(x) any(strfind(x, 'Body_1H_')), p.CONDITIONS.PREDICTOR_NAMES)];
% % g=g+1;
% % group(g).name = 'Food1H-andor-Body1H'; %Food1H-Food1H or Body1H-Body1H or Food1H-Body1H
% % group(g).selection = [cellfun(@(x) any(strfind(x, 'Food_1H_')) | any(strfind(x, 'Body_1H_')), p.CONDITIONS.PREDICTOR_NAMES);
% %                       cellfun(@(x) any(strfind(x, 'Food_1H_')) | any(strfind(x, 'Body_1H_')), p.CONDITIONS.PREDICTOR_NAMES)];
% % 
% % g=g+1;
% % group(g).name = 'Food_without_1H-1H';
% % group(g).selection = [cellfun(@(x) any(strfind(x, 'Food_')), p.CONDITIONS.PREDICTOR_NAMES);
% %                       cellfun(@(x) any(strfind(x, 'Food_')), p.CONDITIONS.PREDICTOR_NAMES)];
% % group(g).exclude = {'Food1H-Food1H'};





% insert groups here



%% YOU DO NOT NEED TO EDIT BELOW HERE





%% check groups

if ~exist('group', 'var')
    error('Group structure array must be defined')
end

has_exclude = isfield(group, 'exclude');

has_nodiag = isfield(group, 'nodiag');
if has_nodiag
    for g = 1:length(group)
        if isempty(group(g).nodiag)
            group(g).nodiag = false;
        end
    end
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
        error('Selection criteria does not have 2 rows in #%d (%s)', gid, group(gid).name);
    end
    
    if size(group(gid).selection,2) ~= p.NUMBER_OF_CONDITIONS
        error('Selection criteria length does not match number of predictors in #%d (%s)', gid, group(gid).name);
    end
    
    if ~any(group(gid).selection)
        error('Selection criteria is a valid shape but does not contain in true values in #%d (%s)', gid, group(gid).name);
    end
    
    group(gid).do_exclude = false;
    if has_exclude && ~isempty(group(gid).exclude)
        %handle structure of exclude field
        if ~iscell(group(gid).exclude)
            if ~ischar(group(gid).exclude)
                %convert string to cell array of length one
                group(gid).exclude = {group(gid).exclude};
            else
                error('The exclude field in #%d (%s) is not a cell array. Example of cell array: {''model_name1'' ''model_name2''}', gid, group(gid).name)
            end
        end
        
        %find exclude groups + store their selections to use as exclusion criteria
        group(gid).exclude_count = length(group(gid).exclude);
        for e = 1:group(gid).exclude_count
            ind = find(strcmp({group.name},group(gid).exclude{e}));
            if ind==gid
                error('#%d (%s) attempted to exclude itself', gid, group(gid).name);
            elseif isempty(ind)
                error('No matches found for exclude "%s" in #%d (%s)', group(gid).exclude{e}, gid, group(gid).name);
            elseif length(ind) > 1
                error('Too many (>1) matches found for exclude "%s" in #%d (%s)', group(gid).exclude{e}, gid, group(gid).name);
            else
                group(gid).exclude_selection{e} = group(ind).selection;
            end
        end
        
        %enable group exclude
        group(gid).do_exclude = true;
    else
        %disable group exclude
        group(gid).do_exclude = false;
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
FILEPATH_MAT = strrep(FILEPATH_MAT, '[SPLITTYPE]', type);
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
    fol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep];
    if fol(1)=='.'
        fol = [dir_main filesep fol];
    end
    load([fol 'VOI_RSMs.mat']);
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
missing = [];
group_means = nan(p.NUMBER_OF_PARTICIPANTS, number_groups, number_vois);
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
%                 values = [];
                selection = false(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
                
                fprintf('Processing VOI %d of %d (%s), Particiapnt %d of %d, Group %d of %d (%s)...\n', voi, number_vois, data.VOINames{voi}, pid, p.NUMBER_OF_PARTICIPANTS, gid, number_groups, group(gid).name);
                
                for c1 = 1:p.NUMBER_OF_CONDITIONS
                    for c2 = 1:p.NUMBER_OF_CONDITIONS
                        if ~isnan(rsm(c1,c2))
                            if IsValidSelection(c1, c2, group(gid).selection)
                                if group(gid).do_exclude
                                    exclusion_criteria_met = false;

                                    for e = 1:group(gid).exclude_count
                                        if IsValidSelection(c1, c2, group(gid).exclude_selection{e})
                                            exclusion_criteria_met = true;
                                            break;
                                        end
                                    end

                                    if exclusion_criteria_met
                                        continue;
                                    end
                                end

%                                 values(end+1) = rsm(c1,c2);
                                selection(c1,c2) = true;
                            end
                        end
                    end
                end

                % remove diagonal?
                if has_nodiag && group(gid).nodiag
                    selection(eye(size(selection))==1) = 0;
                end
                
                values = rsm(selection);
                
                if isempty(values)
                    error('Group #%d (%s) contains no cells!', gid, group(gid).name);
                end
                
                group_mean = mean(values);
                xls{row, 1+gid} = group_mean;
                group_means(pid,gid,voi) = group_mean;
                
                selections(:,:,gid) = selection;
            end
            
            if ~created_figure
                fig = figure('Position', [1 1 1000 1000]);
                
                condition_labels = strrep(p.CONDITIONS.DISPLAY_NAMES(p.RSM_PREDICTOR_ORDER),'_',' ');
                for gid = 1:number_groups
                    clf
                    imagesc(selections(p.RSM_PREDICTOR_ORDER,p.RSM_PREDICTOR_ORDER,gid));
                    axis square;
                    colormap([0.8 0.8 0.8; 0 0.7 0])
                    
                    hold on
                    for i = 1:p.NUMBER_OF_CONDITIONS
                        plot([i i]+0.5, [0 p.NUMBER_OF_CONDITIONS]+0.5, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1)
                        plot([0 p.NUMBER_OF_CONDITIONS]+0.5, [i i]+0.5, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1)
                    end
                    hold off
                    
                    
                    set(gca,'XAxisLocation','top','xtick',1:p.NUMBER_OF_CONDITIONS,'xticklabel',cell(1,p.NUMBER_OF_CONDITIONS),'ytick',1:p.NUMBER_OF_CONDITIONS,'yticklabel',condition_labels);
                    hText = xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS,90,condition_labels);
                    suptitle([strrep(group(gid).name,'_',' ') ' (' type ')' char(10)]);
                    
                    fp = strrep(FILEPATH_FIGURE, '[GROUP]', group(gid).name);
                    fprintf('Saving selection #%d to: %s\n', gid, fp);
                    saveas(fig, fp);
                end
                
                close(fig)
                created_figure = true;
            end
        else
            missing(end+1,:) = [voi pid];
            warning('Data is missing (nan) in one or more cells of VOI %d (%s) Participant %d! Excluded from averaging.', voi, data.VOINames{voi}, pid);
        end
        row = row + 1;
        
    end
end

%report missing
number_missing = size(missing,1);
if number_missing > 0
    fprintf('\nData was missing from the following %d. These sets were excluded from the averaging.\n', number_missing);
    for i = 1:number_missing
        fprintf('VOI %d (%s), Participant %d.\n', missing(i,1), data.VOINames{missing(i,1)}, missing(i,2));
    end
    fprintf('\n');
end

%% Save
fprintf('Writing to: %s\n', FILEPATH_EXCEL_OUTPUT);
if exist(FILEPATH_EXCEL_OUTPUT, 'file')
    delete(FILEPATH_EXCEL_OUTPUT);
end
xlswrite(FILEPATH_EXCEL_OUTPUT, xls);

%% Save MAT
group_means_legend = 'subject x cell group x VOI';
group_names = {group.name};
voi_names = data.VOINames;
save(FILEPATH_MAT, 'group_means', 'group_means_legend', 'group_names', 'voi_names')

%% Done
fprintf('Complete!\n');




%%
function [p,dir_main] = Get_Main_Params
return_path = pwd;
main_path = ['..' filesep];
try
    cd(main_path)
    dir_main = pwd;
    p = ALL_STEP0_PARAMETERS;
    cd(return_path);
catch err
    cd(return_path);
    rethrow(err);
end

function [valid] = IsValidSelection(c1, c2, selection)
valid = (selection(1,c1) && selection(2,c2)) || (selection(2,c1) && selection(1,c2));