% AddTSVPONIToSDM(filepath_sdm_read, filepath_tsv_read, filepath_sdm_write, names_select, names_to_write, colours, skip_missing)
% 
% Adds regressors for TSV to SDM.
%
% Inputs:
%   filepath_sdm_read
%
%   filepath_tsv_read
%
%   filepath_sdm_write
%
%   names_select    cell array of regressor names to add
%
%   names_to_write  (optional) cell array of names to write in the SDM (must
%                   match the order of names_select
%
%   colours         (optional) Nx3 array of 0-255 RGB values
%
%   skip_missing    (optional) if set true, missing regressors will be
%                   ignored rather than throwing an error
%
function AddTSVPONIToSDM(filepath_sdm_read, filepath_tsv_read, filepath_sdm_write, names_select, names_to_write, colours, skip_missing)

%% Defaults
if ~exist('names_to_write', 'var') || isempty(names_to_write) || ~iscell(names_to_write)
    names_to_write = names_select;
else
    if length(names_to_write) ~= length(names_select)
        error('The length (and order) of names_to_write must match names_select')
    end
end

if ~exist('colours', 'var') || isempty(colours) || ~isnumeric(colours)
    colours = repmat([200 200 200], [length(names_select) 1]);
end

if ~exist('skip_missing', 'var') || isempty(skip_missing) || ~islogical(skip_missing)
    skip_missing = false;
end

%% Load Files
if ~exist(filepath_sdm_read, 'file')
    error('Missing input: %s', filepath_sdm_read);
else
    sdm = xff(filepath_sdm_read);
end

if ~exist(filepath_tsv_read, 'file')
    error('Missing input: %s', filepath_tsv_read);
else
    tsv = readtable(filepath_tsv_read, 'FileType', 'text');
end

%% Check
%check # vol
if sdm.NrOfDataPoints ~= height(tsv)
    error('SDM contains %d vol but TSV contains %d vol', sdm.NrOfDataPoints, height(tsv))
end

%check tsv contains all reg names
col_ind = cellfun(@(x) find(strcmpi(x, tsv.Properties.VariableNames)), names_select, 'UniformOutput', false);
ind_missing = find(cellfun(@length, col_ind) ~= 1);
if ~isempty(ind_missing)
    if skip_missing
        warning('TSV does not contain:\n%s\nskip_missing is true so these will be excluded', sprintf('\t%s\n', names_select{ind_missing}));
        col_ind(ind_missing) = [];
        names_select(ind_missing) = [];
        names_to_write(ind_missing) = [];
        colours(ind_missing,:) = [];
    else
        error('TSV does not contain:\n%s', sprintf('\t%s\n', names_select{ind_missing}));
    end
end
col_ind = cell2mat(col_ind);

%% Add Regressor
values = tsv{:,col_ind};

number_to_add = length(names_to_write);
ind_to_copy_from = sdm.NrOfPredictors;
inds_copy_to = sdm.NrOfPredictors+1 : sdm.NrOfPredictors+number_to_add;

inds_paste_to = inds_copy_to;
if sdm.IncludesConstant
    inds_paste_to = inds_paste_to - 1;
end

%copy to make space
sdm.PredictorColors(inds_copy_to,:) = repmat(sdm.PredictorColors(ind_to_copy_from,:), [number_to_add 1]);
sdm.PredictorNames(inds_copy_to) = sdm.PredictorNames(ind_to_copy_from);
sdm.SDMMatrix(:,inds_copy_to) = repmat(sdm.SDMMatrix(:,ind_to_copy_from), [1 number_to_add]);

%paste in new values
sdm.PredictorColors(inds_paste_to,:) = colours;
sdm.PredictorNames(inds_paste_to) = names_to_write;
sdm.SDMMatrix(:,inds_paste_to) = values;

%set number
sdm.NrOfPredictors = length(sdm.PredictorNames);

%% Save
sdm.SaveAs(filepath_sdm_write);
