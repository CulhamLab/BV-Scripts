% Extract_RSM_Cell_Group_Averages_ttest
%
% for each specified pair of "groups"
%   performs a paired-samples t-test comparing the means
%
% must run "Extract_RSM_Cell_Group_Averages" first

% function Extract_RSM_Cell_Group_Averages_ttest

%% Parameteres

% input
FILEPATH_MAT = 'Extract_RSM_Group_Averages_SPLIT.mat';

% output
FILEPATH_XLS = 'Extract_RSM_Group_Averages_SPLIT_ttest.xlsx';
FILEPATH_XLS_OVERWRITE = true;

% define groups to compare + test direction to use
%
%   Nx3 cell matrix for N comparisons
%       col1: first group's name
%       col2: second group's name
%       col3: test direction
%
%   test directions:
%       right:  first > second
%       left:   first < second
%       both:   first <> second
%
% Example: for A>B, C>D, and E>F
%    comparisons = { 'A' , 'B' , 'right';
%                    'C' , 'D' , 'right';
%                    'E' , 'F' , 'right'};
comparisons = { 'A' , 'B' , 'right';
                'C' , 'D' , 'right';
                'E' , 'F' , 'right'};


%% Files

% load input
if ~exist(FILEPATH_MAT, 'file')
    error('Could not locate input mat file: %s', FILEPATH_MAT)
else
    load(FILEPATH_MAT)
end

% check output overwrite
if exist(FILEPATH_XLS, 'file')
    if ~FILEPATH_XLS_OVERWRITE
        error('Output file already exists and overwrite is set to false')
    else
        delete(FILEPATH_XLS)
    end
end


%% Prep

% counts
[number_subjects, number_groups, number_VOI] = size(group_means);
number_comparisons = size(comparisons,1);

% do all groups exist?
if ~isempty(setdiff(unique(comparisons(:,1:2)), group_names))
    error('One or more group names were no found')
end

% are all test directions valid?
if ~isempty(setdiff(unique(comparisons(:,3)), ["right" "left" "both"]))
    error('One or more test directions is invalid')
end


%% Run t-tests & populate excel

% initialize xls
xls_t = cell(number_VOI+1,number_comparisons+2);
xls_t{1,1} = 't-values';
xls_p = cell(number_VOI+1,number_comparisons+2);
xls_p{1,1} = 'p-values';
xls_df = cell(number_VOI+1,number_comparisons+1);
xls_df{1,1} = 'df';

% run/populate
for c = 1:number_comparisons
    switch comparisons{c,3}
        case 'right'
            symbol = '>';
        case 'left'
            symbol = '<';
        case 'both'
            symbol = '<>';
        otherwise
            error('Unsupported test direction')
    end

    % comparison name
    comparison_name = [comparisons{c,1} symbol comparisons{c,2}];
    xls_t{1,1+c} = comparison_name;
    xls_p{1,1+c} = comparison_name;
    xls_df{1,1+c} = comparison_name;

    % for each VOI...
    for v = 1:number_VOI
        % VOI name
        if c==1
            xls_t{1+v,1} = voi_names{v};
            xls_p{1+v,1} = voi_names{v};
            xls_df{1+v,1} = voi_names{v};
        end

        % find group indices
        ind_group_1 = find(strcmp(group_names,comparisons{c,1}));
        ind_group_2 = find(strcmp(group_names,comparisons{c,2}));
        if length(ind_group_1)~=1 || length(ind_group_2)~=1
            error('One or both groups could not be found')
        end

        % select data
        means_group_1 = group_means(:, ind_group_1, v);
        means_group_2 = group_means(:, ind_group_2, v);

        % remove any subjects who had NaN or 0.0
        invalid_values = isnan(means_group_1) | isnan(means_group_2) | (means_group_1==0) | (means_group_2==0);
        if any(invalid_values)
            fprintf("%s in %s contained %d invalid subject means. These will be excluded.\n", comparison_name, voi_names{v}, sum(invalid_values));
            means_group_1(invalid_values) = [];
            means_group_2(invalid_values) = [];
        end

        % perform t-test
        [~,pval,~,stats] = ttest(means_group_1, means_group_2, 'Tail', comparisons{c,3});

        % %store results
        xls_t{1+v,1+c} = stats.tstat;
        xls_p{1+v,1+c} = pval;
        xls_df{1+v,1+c} = stats.df;
    end
end

%% Combine
xls = [xls_t xls_p xls_df];

%% Save
fprintf("Saving: %s\n", FILEPATH_XLS);
xlswrite(FILEPATH_XLS, xls);


%% Done!
disp Done!