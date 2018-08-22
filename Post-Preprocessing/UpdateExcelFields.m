function UpdateExcelFields(filepath_target)

%% parameters
FILEPATH_TEMPLATE = 'BV20_PostPreprocessing_and_QualityChecks_TEMPLATE.xlsx';
COLUMN_FIELD_NAME = 5;
COLUMN_FIELD_VALUE = 3;

%% input
if ~exist('filepath_target','var')
    [filename, directory, filter] = uigetfile(['*.xls*']);
    switch filter
        case 0
            fprintf('No file was selected. Script will stop.\n');
            return
        case 1
            filepath_target = [directory filename];
        case 2
            error('Invalid file selected!');
        otherwise 
            error('Unknown issue.')
    end
end
fprintf('Target excel file: %s\n', filepath_target);

%% process

%read template
fprintf('Reading template: %s\n', FILEPATH_TEMPLATE);
try
    [~,~,xls_template] = xlsread(FILEPATH_TEMPLATE);
catch err
    warning('Could not read the template excel file!')
    rethrow(err)
end
col_template = size(xls_template,2);
col_check = [1:(COLUMN_FIELD_VALUE-1) (COLUMN_FIELD_VALUE+1):col_template];

%read target
fprintf('Reading target: %s\n', filepath_target);
try
    [~,~,xls_target] = xlsread(filepath_target);
catch err
    warning('Could not read the template excel file!')
    rethrow(err)
end

%backup target
ind = find(filepath_target == '.', 1, 'last');
fp_backup = sprintf('%s_BACKUP%s', filepath_target(1:ind-1), filepath_target(ind:end));
if exist(fp_backup,'file')
    error('Backup file already exists: %s', fp_backup)
end
fprintf('Saving backup: %s\n', fp_backup);
xlswrite(fp_backup, xls_target, 1);

%remove empty rows at end of target
last_valid_row = find(any(cellfun(@(x) ischar(x) || ~isnan(x), xls_target), 2), 1, 'last');
xls_target = xls_target(1:last_valid_row, :);

%copy headers
xls_target(1,1:col_template) = xls_template(1,:);

%fields
fields_template = xls_template(:,COLUMN_FIELD_NAME);
fields_unique = unique(fields_template(cellfun(@ischar, fields_template)));
fields_unique(strcmp(fields_unique, xls_template{1,COLUMN_FIELD_NAME})) = [];
if size(xls_target,2) < COLUMN_FIELD_NAME
    fields_target = {};
else
    fields_target = xls_target(:,COLUMN_FIELD_NAME);
end

%add fields
num_fields = length(fields_unique);
changes_made = false;
for f = 1:num_fields
    field = fields_unique{f};
    fprintf('%d of %d: %s\n', f, num_fields, field);
    
    ind_template = find(strcmp(fields_template, field));
    if length(ind_template) ~= 1
        error
    end
    
    ind_target = find(strcmp(fields_target, field));
    if length(ind_template) > 1
        error
    end
    
    if isempty(ind_target)
        %new field
        fprintf('* NEW FIELD\n');
        xls_target(end+2,1:col_template) = xls_template(ind_template,:);
        changes_made = true;
    else
        %check field
        for c = col_check
            val_template = xls_template{ind_template, c};
            val_target = xls_target{ind_target, c};
            
            dif = 0;
            
            if ischar(val_template) %char
                if ~ischar(val_target) | ~strcmp(val_template, val_target)
                    dif = 1;
                end
            elseif ~isnan(val_template) %numeric
                if ~isnumeric(val_target) | length(val_template)~=length(val_target) | any(val_template~=val_target)
                    dif = 2;
                end
            else %isnan
                if ~isnan(val_target)
                    dif = 3;
                end
            end
            
            if dif ~= 0
                fprintf('* Difference in column %d (type %d)\n', c, dif);
                xls_target(ind_target, c) = xls_template(ind_template, c);
                changes_made = true;
            end
        end
        
        
    end
end

%save
if changes_made
    fprintf('Saving changes...\n')
    xlswrite(filepath_target, xls_target, 1);
else
    fprintf('No changes needed.\n')
end

%done
disp Done.

