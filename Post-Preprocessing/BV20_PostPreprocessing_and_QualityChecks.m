% All parameters are set in the loaded excel file (not in this script).
%
% Requirements:
% * NeuroElf toolbox (tested with neuroelf_v10_5153)
% * Data must have been preprocessed with the BV20 workflow
% * Single session only
%
function BV20_PostPreprocessing_and_QualityChecks(xls_filepath)
%% Temp
xls_filepath = 'BV20_PostPreprocessing_and_QualityChecks_EXAMPLE.xlsx';

%% Get script constants
p = ScriptConstants;

%%  0. Select Excel file (unless passed as input in which case check it)
if ~exist('xls_filepath','var')
    xls_filepath = GetExcel(p);
else
    CheckExcel(p, xls_filepath);
end

%%  1. Add parameters from excel and check them
p = ReadExcel(p, xls_filepath);
CheckParameters(p);

%%  2. Search for existing files to confirm that everything is in order

%%  3. Link PRTs to VTCs

%%  4. Apply Linear Trend Removal and Temporal High Pass if not already run

%%  5. Apply Spatial Smoothing to create set of smoothed VTCs for univariate analyses

%%  6. Generate SDMs from PRTs

%%  7. Merge Generated SDMs with 3DMC SDMs (use motion as predictors of no interest)

%%  8. Generate MDM for each participant and for all participants using SDM with merged 3DMC

%%  9. Gather BBR values and report any issues

%% 10. Run motion checks and create summary figures

%% 11. (DETAILS UNKNOWN) Something to assist with functional-anatomical alignment checks

function [p] = ScriptConstants
p.XLS.FILETYPE = 'xls*';
p.XLS.ROW_START = 2;
p.XLS.COL_VALUE = 3;
p.XLS.COL_ID = 5;

function [xls_filepath] = GetExcel(p)
[filename, directory, filter] = uigetfile(['*.' p.XLS.FILETYPE]);
switch filter
    case 0
        fprintf('No file was selected. Script will stop.\n');
        return
    case 1
        xls_filepath = [directory filename];
    case 2
        error('Invalid file selected!');
        return
end

function CheckExcel(p, xls_filepath)
if ~exist(xls_filepath, 'file')
    error('File does not exist!');
else
    type = xls_filepath(find(xls_filepath=='.',1,'last')+1:end);
    if isempty(regexp(type, p.XLS.FILETYPE))
        error('Invalid type of file!')
    end
end

function [p] = ReadExcel(p, xls_filepath)
p.excel = xls_filepath;
[~,~,xls] = xlsread(xls_filepath);
num_rows = size(xls,1);
for r = p.XLS.ROW_START:num_rows
    id = xls{r,p.XLS.COL_ID};
    if ~isnan(id)
        val = xls{r,p.XLS.COL_VALUE};
        eval(sprintf('p.%s = val;', id))
    end
end

function CheckParameters(p)
%add filsep if needed
fs = fields(p.DIR);
for f = 1:length(fs)
    eval(sprintf('val = p.DIR.%s;', fs{f}))
    if ~isnan(val) & (val(end) ~= filesep)
        eval(sprintf('p.DIR.%s(end+1) = filesep;', fs{f}))
    end
end

%check BV dir exists
if ~exist(p.DIR.BV, 'dir')
    error('BV directory does not exist: %s', p.DIR.BV)
end

%check if output dir exists, create if not
if ~exist(p.DIR.OUT, 'dir')
    fprintf('Output directory does not exist and will now be created: %s\n', p.DIR.OUT)
    fs = find(p.DIR.OUT == filesep);
    for i = 1:length(fs)
        d = p.DIR.OUT(1:fs(i));
        if ~exist(d, 'dir')
            mkdir(d);
        end
    end
end

