% VOI_Rename_Recolour_Reorder(filepath_xls_input, filepath_voi_input, filepath_voi_output, overwrite)
%
% Renames, recolours, and/or reorders the VOIs in a .voi file using
% information from a spreadsheet.
%
% filepath_spreadsheet_input
%   * file can be any format supported by readtable (xls, xlsx, csv, etc.)
%   * each row must be a VOI, the order of rows will be the new order of
%       VOIs, and you may remove VOIs by excluding them from the table
%   * must contain the following columns:
%       1. CurrentName: the name of the VOI in the input .voi
%       2. NewName: the name of the VOI to use in the output .voi (leave empty to keep the current name)
%       3. NewColour: the hexcode of the colour to use in the output .voi (leave empty to keep the curernt colour)
%
% filepath_voi_input
%   * filepath to .voi input file
%   * you may exclude the folder if the file is in the working directory
%
% filepath_voi_output
%   * filepath to write the .voi output to
%   * you may exclude the folder if the file is in the working directory
%   
% overwrite (OPTIONAL)
%   * set true to overwrite the output .voi file
%   * defaults to false if empty or not provided
%
% column_name_CurrentName (OPTIONAL)
%   * set the expected column name for the VOI's current name
%   * defaults to CurrentName if empty or not provided
%
% column_name_NewName (OPTIONAL)
%   * set the expected column name for the VOI's new name
%   * defaults to NewName if empty or not provided
%   * set to Skip to fully disable renaming
%
% column_name_NewColour (OPTIONAL)
%   * set the expected column name for the VOI's new colour hexcode
%   * defaults to NewColour if empty or not provided
%   * set to Skip to fully disable recolouring
%
function VOI_Rename_Recolour_Reorder(filepath_spreadsheet_input, filepath_voi_input, filepath_voi_output, overwrite, column_name_CurrentName, column_name_NewName, column_name_NewColour)

%% Apply default parameters

disp 'Applying defaults to empty/missing parameters...'

if ~exist('overwrite','var') || length(overwrite)~=1 || isempty(overwrite) || (~isnumeric(overwrite) && ~islogical(overwrite))
    overwrite = false;
end

if ~exist('column_name_CurrentName','var') || size(column_name_CurrentName,1)~=1 || isempty(column_name_CurrentName) || ~ischar(column_name_CurrentName)
    column_name_CurrentName = 'CurrentName';
end

if ~exist('column_name_NewName','var') || size(column_name_NewName,1)~=1 || isempty(column_name_NewName) || ~ischar(column_name_NewName)
    column_name_NewName = 'NewName';
end

if ~exist('column_name_NewColour','var') || size(column_name_NewColour,1)~=1 || isempty(column_name_NewColour) || ~ischar(column_name_NewColour)
    column_name_NewColour = 'NewColour';
end

%% Process and check inputs

disp 'Checking parameters...'

% add .voi filetype if needed
[~,~,filetype] = fileparts(filepath_voi_input);
if ~strcmpi(filetype, '.voi')
    filepath_voi_input = [filepath_voi_input '.voi'];
end
[~,~,filetype] = fileparts(filepath_voi_output);
if ~strcmpi(filetype, '.voi')
    filepath_voi_output = [filepath_voi_output '.voi'];
end

% input doesn't exist?
if ~exist(filepath_voi_input,'file')
    error('Input VOI does not exist: %s', filepath_voi_input)
end
if ~exist(filepath_spreadsheet_input,'file')
    error('Input spreadsheet does not exist: %s', filepath_spreadsheet_input)
end

% output exists and overwrite is false?
if exist(filepath_voi_output,'file') && ~overwrite
    error('Output VOI exists and overwrite=false: %s', filepath_voi_output)
end

% input voi is also the output voi
if exist(filepath_voi_output,'file')
    info_input = dir(filepath_voi_input);
    info_output = dir(filepath_voi_output);
    if strcmpi(info_input.name, info_output.name) && strcmpi(info_input.folder, info_output.folder)
        error('Input and output VOI should not be identical.')
    end
end

% perform renaming/recolouring?
do_rename = ~strcmpi(column_name_NewName, 'skip');
do_recolour = ~strcmpi(column_name_NewColour, 'skip');

% NeuroElf is available?
if ~exist('xff','file')
    error('This script requires NeuroElf toolbox.')
end

%% Process spreadsheet

disp 'Reading spreadsheet...'
try
    sheet = readtable(filepath_spreadsheet_input, 'VariableNamingRule', 'preserve');
catch err
    warning('Failed to read spreadsheet: %s\nSee error message below.', filepath_spreadsheet_input);
    rethrow(err)
end

%initialize table
t = table;

% prior names...
if ~ismember(column_name_CurrentName, sheet.Properties.VariableNames)
    error('Spreadsheet does not contain the expected CurrentName column: %s', column_name_CurrentName);
else
    vals = sheet.(column_name_CurrentName);
    if ~iscell(vals)
        error('The content in the CurrentName column does not have the expected format')
    end
    t.CurrentName = vals;

    % remove invalid characters
    t.CurrentName = strrep(t.CurrentName, char(65279), '');
end

% new names...
if do_rename
    if ~ismember(column_name_NewName, sheet.Properties.VariableNames)
        error('Spreadsheet does not contain the expected NewName column: %s', column_name_NewName);
    else
        vals = sheet.(column_name_NewName);
        if ~iscell(vals)
            error('The content in the NewName column does not have the expected format')
        end
        t.NewName = vals;
    end

    % skip rename for VOIs with empty NewName
    t.DoRename = ~cellfun(@isempty, t.NewName);
else
    % skip all renaming
    t.DoRename(:) = false;
end

% new colours...
if do_recolour
    if ~ismember(column_name_NewColour, sheet.Properties.VariableNames)
        error('Spreadsheet does not contain the expected NewColour column: %s', column_name_NewColour);
    else
        vals = sheet.(column_name_NewColour);
        if ~iscell(vals)
            error('The content in the NewColour column does not have the expected format')
        end
        t.NewColourHex = vals;
    end

    % remove # symbol
    t.NewColourHex = strrep(t.NewColourHex, '#', '');

    % convert to RGB
    t.RGB = nan(height(t),3);
    for r = 1:height(t)
        if ~length(t.NewColourHex{r})
            continue % will skip recolouring this VOI
        elseif length(t.NewColourHex{r})~=6
            error('Row %d contains an invalid hexcode: %s', r, t.NewColourHex{r})
        else
            try
                t.RGB(r,:) = hex2dec({t.NewColourHex{r}(1:2) t.NewColourHex{r}(3:4) t.NewColourHex{r}(5:6)})';
            catch err
                warning('An error occured when converting the hexcode in row %d: %s', r, t.NewColourHex{r})
                rethrow(err)
            end
        end
    end

    % skip recolour for VOIs without NewColour (specifically, check if any NaN in RGB)
    t.DoRecolour = ~any(isnan(t.RGB),2);
else
    % skip all recolouring
    t.DoRecolour(:) = false;
end

%% Load VOI

disp 'Loading VOI...'
voi = xff(filepath_voi_input);
voi_names = arrayfun(@(x) x.Name, voi.VOI, 'UniformOutput', false);

% make copy with no VOIs
voi_new = voi.CopyObject;
voi_new.VOI = voi_new.VOI([]);

%% Process changes

disp 'Processing changes...';
voi_count = height(t);
for v = 1:voi_count
    fprintf('Adding VOI %d of %d: %s\n', v, voi_count, t.CurrentName{v});

    % find the voi
    ind = find(strcmpi(voi_names, t.CurrentName{v}));
    if isempty(ind)
        error('VOI %d was not found: %s', v, t.CurrentName{v})
    elseif length(ind)>1
        error('Multiple matches were found for VOI %d: %s', v, t.CurrentName{v})
    end

    % copy voi
    voi_new.VOI(v) = voi.VOI(ind);

    % rename?
    if t.DoRename(v)
        fprintf('\tRenaming:\t\t%s\n', t.NewName{v});
        voi_new.VOI(v).Name = t.NewName{v};
    end

    % recolour?
    if t.DoRecolour(v)
        fprintf('\tRecolouring:\t%s(hexcode: #%s)\n', sprintf('%d ', t.RGB(v,:)), t.NewColourHex{v});
        voi_new.VOI(v).Color = t.RGB(v,:);
    end

    % newline
    fprintf('\n');
end

%% Save

fprintf('Writing new .voi file: %s\n', filepath_voi_output);
voi_new.SaveAs(filepath_voi_output);

%% Done

fprintf('\nDone!\n');
