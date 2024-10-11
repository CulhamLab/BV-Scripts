% Reads all selected PRT files in the specified folder (and subfolders).
% Counts the number of events for each condition and write the table to the
% specified filepath. The table contains one row per file and one column
% per unique condition.
%
% Requires Neuroelf

%% Parameters
search_folder = "C:\Users\kmstu\Downloads\3DReach PRTs\";
search_term = "*.prt";
output_filepath = ".\3DReachPRTs_Counts.xlsx";

%% Run

% find files
list = dir(fullfile(search_folder, "**", search_term));

% discard any non-PRT
list = list( arrayfun(@(x) strcmpi(x.name(find(x.name=='.',1,"last"):end),'.prt'), list) );
list_count = length(list);
if ~list_count
    error("No .prt files were found!\n");
else
    fprintf("Found %d .prt files...\n", list_count);
end

% clear prior output
if exist(output_filepath, "file")
    delete(output_filepath)
end

% init
values = cell(0);
conditions = cell(0);

% process files
for fid = 1:list_count
    fp = [list(fid).folder filesep list(fid).name];
    fprintf("Processing %d of %d: %s\n", fid, list_count, fp);

    % folder and filename
    values{fid,1} = [list(fid).folder filesep];
    values{fid,2} = list(fid).name;

    % read
    prt = xff(fp);

    % add each condition
    for c = 1:prt.NrOfConditions
        % find match
        ind = find(strcmpi(conditions, prt.Cond(c).ConditionName));
        if length(ind)>1
            error("Too many matches")
        elseif isempty(ind)
            ind = length(conditions) + 1;
            conditions{ind} = prt.Cond(c).ConditionName{1};
        end

        % set event count
        values{fid,2+ind} = prt.Cond(c).NrOfOnOffsets;
    end

    % cleanup
    prt.ClearObject;
end

% convert empty to 0
values(cellfun(@isempty, values)) = {0};

% add totals
values = [{'TOTAL' 'TOTAL'} num2cell(sum(cell2mat(values(:,3:end)), 1)); values];

% convert to table
headers = [{'Folder' 'Filename'} conditions];
tbl = array2table(values, "VariableNames", headers);

% write table
fprintf("Writing: %s\n", output_filepath);
writetable(tbl, output_filepath);

%% Done
fprintf("Done!\n");