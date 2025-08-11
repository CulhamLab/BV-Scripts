%% Parameters
folder = pwd;
search_term = '*.sdm';

%% Prep
if isstring(folder)
    folder = folder.char;
end
if isstring(search_term)
    search_term = search_term.char;
end
if ~exist(folder, "dir")
    error("Folder not found: %s", folder)
end
if folder(end)~=filesep
    folder(end+1) = filesep;
end
if length(search_term)<4 || ~strcmp(lower(search_term(end-3:end)), '.sdm')
    error("Invalid search_term")
end

%% Find all matches
list = dir([folder search_term]);
number_files = length(list);

%% No matches?
if ~number_files
    error("No matches for: " + folder + search_term)
end

%% Process
for fid = 1:number_files
    fprintf("Processing %d of %d: %sf\n", number_files, list(fid).name);

    % load sdm
    sdm = xff([list(fid).folder filesep list(fid).name]);

    % get predictors
    predictors = sdm.SDMMatrix;

    % convert to table
    tbl = array2table(predictors, VariableNames=sdm.PredictorNames);

    % write to csv
    [~,name,~] = fileparts(list(fid).name);
    fp = [list(fid).folder filesep name '.csv'];
    if exist(fp, "file")
        delete(fp)
    end
    writetable(tbl, fp);
end

%% Done
disp Done!