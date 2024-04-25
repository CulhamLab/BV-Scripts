% function VOI_GetNames(filepath_voi_input, filepath_spreadsheet_output, overwrite)
%
% Reads a .voi file and creates a spreadsheet with the VOI names in the
% order that they appear in the file.
%
% filepath_voi_input
%   * filepath to .voi input file
%   * you may exclude the folder if the file is in the working directory
%   
% filepath_spreadsheet_output
%   * filepath to the spreadsheet to write
%   * may be any filetype supported by writetable (xls, xlsx, csv, etc.)
%
% overwrite (OPTIONAL)
%   * set true to overwrite the output spreadsheet file
%   * defaults to false if empty or not provided
%
function VOI_GetNames(filepath_voi_input, filepath_spreadsheet_output, overwrite)

%% Apply default parameters

disp 'Applying defaults to empty/missing parameters...'

if ~exist('overwrite','var') || length(overwrite)~=1 || isempty(overwrite) || (~isnumeric(overwrite) && ~islogical(overwrite))
    overwrite = false;
end

%% Process and check inputs

disp 'Checking parameters...'

% add .voi filetype if needed
[~,~,filetype] = fileparts(filepath_voi_input);
if ~strcmpi(filetype, '.voi')
    filepath_voi_input = [filepath_voi_input '.voi'];
end

% input doesn't exist?
if ~exist(filepath_voi_input,'file')
    error('Input VOI does not exist: %s', filepath_voi_input)
end

% output exists and overwrite is false?
if exist(filepath_spreadsheet_output,'file') && ~overwrite
    error('Output spreadsheet exists and overwrite=false: %s', filepath_spreadsheet_output)
end

% NeuroElf is available?
if ~exist('xff','file')
    error('This script requires NeuroElf toolbox.')
end

%% Load VOI

disp 'Loading VOI...'
voi = xff(filepath_voi_input);

%% Parse names

disp 'Parsing VOI names...';
t = table;
t.VOI_Names = arrayfun(@(x) x.Name, voi.VOI, 'UniformOutput', false)';

%% Write file

if exist(filepath_spreadsheet_output,'file')
    if overwrite
        delete(filepath_spreadsheet_output)
    else
        error('Attempted to overwrite spreadsheet file when overwrite=false')
    end
end

fprintf('Writing spreadsheet: %s\n', filepath_spreadsheet_output);
writetable(t, filepath_spreadsheet_output)

%% Done

disp Done!