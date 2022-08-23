function PRT_to_SDM(number_volumes, TR, folder, ind_first_poni)

%% Defaults
if ~exist('folder', 'var') || isempty(folder) || ~ischar(folder)
    folder = [pwd filesep];
end
if folder(end) ~= filesep
    folder(end+1) = filesep;
end

if ~exist('ind_first_poni', 'var') || isempty(ind_first_poni) || ~isnumeric(ind_first_poni)
    ind_first_poni = nan;
end

%% Parameters
param.rcond = []; %empty to exclude no conditions
param.nvol = number_volumes; %number of volumes

%% Select File(s)
file_list = dir([folder '*.prt']);
number_files = length(file_list);
if ~number_files
    error('No PRT files found')
end

%% Generate SDMs
for i = 1:number_files
    fn = file_list(i).name;
    fp = [file_list(i).folder filesep file_list(i).name];
    fprintf('Processing %d of %d: %s\n', i, number_files, fn);
    
    fp_out = strrep(fp, '.prt', '.sdm');
    if exist(fp_out, 'file')
        warning('File already exists and will NOT be overwritten: %s', fp_out)
    end
    
    prt = xff(fp);
    
    if strcmpi(prt.ResolutionOfTime, 'msec')
        param.prtr = TR * 1000;
    else
        param.prtr = TR;
    end
    
    sdm = prt.CreateSDM(param);
    
    if ~isnan(ind_first_poni)
        sdm.FirstConfoundPredictor = ind_first_poni;
    end
    
    sdm.SaveAs(fp_out);
    
    prt.ClearObject;
    sdm.ClearObject;
    clear prt sdm;
end