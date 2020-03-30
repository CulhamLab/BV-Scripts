function Extract_RSM_Averages

%read main parameters
p = Get_Main_Params;

%% EDIT HERE - parameters
USE_SPLIT_DATA = true;
ALLOW_EXCEL_OVERWRITE = true;
FILEPATH_EXCEL_OUTPUT = 'Extract_RSM_Averages.xlsx';

%% EDIT HERE - which predictors to include

%use the order of predictors in ALL_STEP0_PARAMETERS

%leave this to include all predictors
predictors_use = true(1, true(1, p.NUMBER_OF_CONDITIONS));

%otherwise, create a 1-by-#Predictors that is true for predictors to
%include and false for predictors in exclude
% predictors_use = [true(1,2) false(1,4) true(1,2)];

%% EDIT HERE - define factors each with a 1-by-#Predictors

%EXAMPLE (can any/more numbers, not limited to 0 and 1):
% f=0;
% 
% f=f+1;
% factor(f).name = 'ID';
% factor(f).values = [0 1 0 1 0 1 0 1]; %0=dice, 1=rubik
% 
% f=f+1;
% factor(f).name = 'Size';
% factor(f).values = [0 0 1 1 0 0 1 1]; %0=small, 1=large
% 
% f=f+1;
% factor(f).name = 'Distance';
% factor(f).values = [0 0 0 0 1 1 1 1]; %0=near, 1=far

%% Don't edit below this point

%% read VOI RSMs
try
    load([p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep 'VOI_RSMs.mat']);
catch err
    warning('Could not load VOI RSMs. Has VOI step6 been run or has data moved?')
    rethrow(err);
end
    
%% run

%delete prior output
if exist(FILEPATH_EXCEL_OUTPUT,'file')
    if (ALLOW_EXCEL_OVERWRITE)
        delete(FILEPATH_EXCEL_OUTPUT);
    else
        error('Output excel file already exists and allow overwrite is set false!');
    end
end

%create empty xls
xlswrite(FILEPATH_EXCEL_OUTPUT, {' '}, 'Main')
Create_Empty_XLSX(FILEPATH_EXCEL_OUTPUT);

%factor groups
[group_matrix, group_factor_compare, factor_names] = Calculate_Groups(factor, predictors_use, p);
[number_groups, number_factors] = size(group_factor_compare);
compare_names = {'Different' 'Same'};

%select data
if USE_SPLIT_DATA
    RSMs = data.RSM_split;
    type_name = 'SPLIT';
else
    RSMs = data.RSM_nonsplit;
    type_name = 'NONSPLIT';
end

%start xls with info
number_participants = size(RSMs,3);
xls = {sprintf('Means and Standard Deviations of each group of cells pooled across %d particiapnts in the %s RSMs', number_participants, type_name)};

group = ['Group#' factor_names; num2cell([1:number_groups]') compare_names(1 + group_factor_compare)];
xls(3:3-1+size(group,1), 1:size(group,2)) = group;

xls{end+1,1} = ' ';

names = p.CONDITIONS.DISPLAY_NAMES;
if size(names, 1) == 1
    names = names';
end
matrix = [names num2cell(group_matrix)];
xls(end+1:end+size(matrix,1), 1:size(matrix,2)) = matrix;

xls{end+1,1} = ' ';

%group names
for g = 1:number_groups
    group_name = '';
    for f = 1:number_factors
        if (f>1) group_name(end+1) = '_'; end
        group_name = [group_name compare_names{1 + group_factor_compare(g,f)} factor(f).name];
    end
    group_names{g} = group_name;
end

%for each voi...
number_voi = length(data.VOINames);
col_m = number_factors+1;
col_std = col_m + 1;
for v = 1:number_voi
    fprintf('Running VOI %d of %d (%s)\n', v, number_voi, data.VOINames{v})
    xls{end+1,1} = data.VOINames{v};
    
    xls_raw = ['ParticipantNumber' 'GroupNumber' 'GroupName' factor_names 'r-value'];
    
    RSMs_voi = RSMs(:,:,:,v);
    
    row_group = size(xls, 1) + 1;
    row_type = row_group + 1;
    
    row_par = row_type + 1;
    
    pooled_group_values = cell(1,number_groups);
    
    means = nan(number_participants, number_groups);
    stds = nan(number_participants, number_groups);
    
    for s = 1:number_participants
        if (s>1) row_par=row_par+1; end
        
        rsm_this = RSMs_voi(:,:,s);
        
        c=1;
        xls{row_par,c} = sprintf('P%02d', s);
        
        for g = 1:number_groups
            
            values_this = rsm_this( (group_matrix==g) );
            
            pooled_group_values{g} = [pooled_group_values{g}; values_this];
            
            number_values_this = length(values_this);
            xls_raw = [xls_raw; repmat([num2cell([s g]) group_name compare_names(1 + group_factor_compare(g,:))], [number_values_this 1]) num2cell(values_this)];
            
            means(s,g) = mean(values_this);
            stds(s,g) = std(values_this);
            
            c=c+1;
            xls{row_group,c} = group_names{g};
            xls{row_type,c} = 'Mean';
            xls{row_par,c} = means(s,g);
            
            c=c+1;
            xls{row_type,c} = 'StDev';
            xls{row_par,c} = stds(s,g);
            
        end
    end
    
    %subject-average
    row_par = row_par + 1;
    c=1;
    xls{row_par,c} = sprintf('Average');
    for g = 1:number_groups
        c=c+1;
        xls{row_par,c} = mean(means(:,g));
        c=c+1;
        xls{row_par,c} = mean(stds(:,g));
    end
    
    %all subjects pooled together
    row_par = row_par + 1;
    c=1;
    xls{row_par,c} = sprintf('All Ps pooled as one');
    for g = 1:number_groups
        c=c+1;
        xls{row_par,c} = mean(pooled_group_values{g});
        c=c+1;
        xls{row_par,c} = std(pooled_group_values{g});
    end
        
% % % OLD FORMAT    
%     rp = size(xls,1) + 1;
%     
%     rh = rp+1;
%     xls(rh,1:number_factors) = factor_names;
%     xls{rh,col_m} = 'Mean';
%     xls{rh,col_std} = 'Standard Deviation';
%     
%     for g = 1:number_groups
%         group_name = '';
%         for f = 1:number_factors
%             if (f>1) group_name(end+1) = '_'; end
%             group_name = [group_name compare_names{1 + group_factor_compare(g,f)} factor(f).name];
%         end
%         
%         search = repmat((group_matrix==g), [1 1 number_participants]);
%         values = RSMs_voi(search);
%         
%         r = size(xls,1) + 1;
%         xls(r, 1:number_factors) = compare_names(1 + group_factor_compare(g,:));
%         
%         c = col_std;
%         means = nan(1,number_participants);
%         stds = nan(1,number_participants);
%         for s = 1:number_participants
%             rsm_this = RSMs_voi(:,:,s);
%             values_this = rsm_this( (group_matrix==g) );
%             
%             number_values_this = length(values_this);
%             
%             xls_raw = [xls_raw; repmat([num2cell([s g]) group_name compare_names(1 + group_factor_compare(g,:))], [number_values_this 1]) num2cell(values_this)];
%             
%             means(s) = mean(values_this);
%             stds(s) = std(values_this);
%             
%             c = c + 1;
%             xls{rp, c} = sprintf('P%02d', s);
%             xls{rh,c} = 'Mean';
%             xls{r, c} = means(s);
%             
%             c = c + 1;
%             xls{rh,c} = 'Standard Deviation';
%             xls{r, c} = stds(s);
%         end
%         
%         %combine all subs into 1
%         c = c + 1;
%         xls{rp, c} = 'All_Ps_Pooled_Together';
%         xls{rh,c} = 'Mean';
%         xls{r, c} = mean(values);
%         
%         c = c + 1;
%         xls{rh,c} = 'Standard Deviation';
%         xls{r, c} = std(values);
%         
%         %average across sub values
%         xls(r, [col_m col_std]) = {mean(means) , mean(means)};
%         xls{rp, col_m} = 'Average (not including pooled together)';
%         
%     end
    
    xls{end+1,1} = ' ';
    
    %write raw
    fprintf('Writting raw to %s\n', FILEPATH_EXCEL_OUTPUT);
    xlswrite(FILEPATH_EXCEL_OUTPUT, xls_raw, data.VOINames{v});
end

%write
fprintf('Writting main output to %s\n', FILEPATH_EXCEL_OUTPUT)
xlswrite(FILEPATH_EXCEL_OUTPUT, xls);

%% done
disp Done!

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

%%
%create the groups from factors + create matrix
function [group_matrix, group_factor_compare, factor_names] = Calculate_Groups(factor, predictors_use, p)

number_factors = length(factor);

%correct direction of 1D arrays
for f = 1:number_factors
    if size(factor(f).values,2) == 1
        factor(f).values = factor(f).values'; %make 1xN
    end
end
if size(predictors_use,2) == 1
    predictors_use = predictors_use';
end

%check that all factors have length equal to number of predictors + check for nans
for f = 1:number_factors
    if length(factor(f).values) ~= p.NUMBER_OF_CONDITIONS
        error('Factor %d (%s) does not have length of values equal to number of predictors!', f, factor(f).name)
    elseif any(isnan(factor(f).values))
        error('Factor %d (%s) contains nan values!', f, factor(f).name)
    end
end
if length(predictors_use) ~= p.NUMBER_OF_CONDITIONS
    error('predictors_does not have length of values equal to number of predictors!', f, factor(f).name)
elseif any(isnan(predictors_use))
    error('predictors_does contains nan values!', f, factor(f).name)
end

%check that factor names are unique
factor_names = {factor.name};
if length(factor_names) ~= length(unique(factor_names))
    error('One or more factor has the same name!')
end

%generate groups
number_groups = 2 ^ number_factors;
group_factor_compare = nan(number_groups, number_factors);
for f = 1:number_factors
    reps = 2 ^ (f-1);
    len = number_groups / reps;
    
    group_factor_compare(:,f) = repmat([ones(len/2,1); zeros(len/2,1)], [reps 1]);
end

%compare factor matrices
factor_matrices = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS, number_factors);
for f = 1:number_factors
    factor_matrices(:,:,f) = repmat(factor(f).values, [p.NUMBER_OF_CONDITIONS 1]) == repmat(factor(f).values', [1 p.NUMBER_OF_CONDITIONS]);
end

%create group assignment matrix
group_matrix_all = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
for g = 1:number_groups
    search = repmat(reshape(group_factor_compare(g,:), [1 1 number_factors]), [p.NUMBER_OF_CONDITIONS p.NUMBER_OF_CONDITIONS]);
    ind = ~any(~(factor_matrices == search), 3);
    
    %check that overlap has not occured somehow
    if any(~isnan(group_matrix_all(ind)))
        error('Overlap in final factor search (shouldn''t be possible)')
    end

    group_matrix_all(ind) = g;
end

%limit predictors used + remove groups that aren't found
matrix_exclude = repmat(~predictors_use, [p.NUMBER_OF_CONDITIONS 1]) | repmat(~predictors_use', [1 p.NUMBER_OF_CONDITIONS]);
group_matrix_all(matrix_exclude) = nan;
groups_keep = [];
for g = 1:number_groups
    if any(group_matrix_all(:)==g)
        groups_keep(end+1) =g;
    end
end
group_factor_compare = group_factor_compare(groups_keep, :);
group_matrix = nan(size(group_matrix_all));
for i = 1:length(groups_keep)
    group_matrix(group_matrix_all==groups_keep(i)) = i;
end

%%
function Create_Empty_XLSX(relative_filepath)
full_filepath = [pwd filesep relative_filepath];
try
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(full_filepath);
    objExcel.ActiveWorkbook.Worksheets.Item('Sheet1').Delete;
    objExcel.ActiveWorkbook.Worksheets.Item('Sheet2').Delete;
    objExcel.ActiveWorkbook.Worksheets.Item('Sheet3').Delete;
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
catch err
    warning(err.message)
    warning('Could not create empty excel file. Output will contain extra pages.')
end
