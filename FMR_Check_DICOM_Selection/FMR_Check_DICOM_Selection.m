%Reads FMRs in a BV20 project folder to determine which dicoms were
%selected in the creation of the FMR.
%
%Detects the following issues:
%1. DICOMs with multiple participant codes present in a single participant (inconsistent_code)
%2. DICOMs from the same series used for multiple runs in a single participant (duplicate_series)
%3. DICOMs from a single participant code present in more than one participant (duplicate_code)
%
%Results are displayed in the command window and summarized in an excel
%file.
%
%NOTE: Does not support session subfolders or multiple sessions.
%
function FMR_Check_DICOM_Selection

%% Parameters

%filepath to write excel output to
OUTPUT_FILEPATH = 'FMR_Check_DICOM_Selection.xls';

%path to the BV20 project directory
PATH_TO_BV_DIRECTORY = 'C:\Users\kstubbs4\Documents\BrainVoyagerData\Carol_CHP_Redo';

%Set nan if you named participants P1, P2, etc. and all participants are included (automatic)
%otherwise, write a cell array of participant IDs in order
%leave cells of excluded participants empty ([]) or nan
%
%Example 1:
%Uses P# format and no participants are excluded
%PARTICIPANT_ID_IN_ORDER = nan;
%
%Example 2:
%Participant 1 is AB12
%Participant 2 is CD34
%Participant 3 was excluded (set nan or [])
%Participant 4 is GH78
%PARTICIPANT_ID_IN_ORDER = {'AB12' 'CD34' nan 'GH78'};
%
%Example 3:
%PARTICIPANT_ID_IN_ORDER{1} = 'AB12';
%PARTICIPANT_ID_IN_ORDER{2} = 'CD3D';
%Participant 4 is left empty
%PARTICIPANT_ID_IN_ORDER{4} = 'GH78';
PARTICIPANT_ID_IN_ORDER = nan;

%% Prepare
if PATH_TO_BV_DIRECTORY(end) ~= filesep
    PATH_TO_BV_DIRECTORY(end+1) = filesep;
end

if exist(OUTPUT_FILEPATH,'file')
    delete(OUTPUT_FILEPATH);
end

%% Run
if iscell(PARTICIPANT_ID_IN_ORDER)
    participant_IDs = PARTICIPANT_ID_IN_ORDER;
else
    %get participant IDs from folder names
    list = dir([PATH_TO_BV_DIRECTORY 'P*']);
    list = list([list.isdir]);
    filenames = {list.name};
    
    %remove folders that do no contain at least one FMR
    has_fmr = cellfun(@(x) ~isempty(dir([PATH_TO_BV_DIRECTORY x filesep '*.fmr'])), filenames);
    filenames = filenames(has_fmr);
    
    par_nums = cellfun(@(x) str2num(x(2:end)), filenames);
    
    participant_IDs(par_nums) = filenames;
end

number_participants = length(participant_IDs);

%process each particiapnt
xls = {'Participant#' 'Run#' 'Code' 'Series' 'FMR' 'Dicom' 'Issues'};
found_issue = 0;
for p = 1:number_participants
    pid = participant_IDs{p};
    
    if isempty(pid) | isnan(pid)
        continue
    end
    
    fol = [PATH_TO_BV_DIRECTORY pid filesep];
    
    if ~exist(fol,'dir')
        warning('No directory found for %s', pid)
        continue
    end
    
    fprintf('\nParticipant %d: %s\n', p, pid);
    
    list = dir([fol '*.fmr']);
    filenames = {list.name};
    
    run_tokens = regexp(filenames, 'S1R\d+.fmr','match');
    ind_keep = ~cellfun(@isempty, run_tokens);
    
    filenames = filenames(ind_keep);
    run_numbers = cellfun(@(x) str2num(x(find(x=='R',1,'last')+1:find(x=='.',1,'last')-1)), filenames);
    number_files = length(run_numbers);
    
    series_list = [];
    for f = 1:number_files
        fn = filenames{f};
        run = run_numbers(f);
        issues = '';
        
        fmr = xff([fol fn]);
        dicom = fmr.FirstDataSourceFile;
        fmr.clear;
        clear fmr
        
        %partipant code
        underscores = find(dicom=='_');
        spaces = find(dicom==' ');
        code = dicom(underscores(3)+1:spaces(1)-1);
        
        %series
        dashes = find(dicom=='-');
        series = str2num(dicom(dashes(1)+1:dashes(2)-1));
        
        %write
        fprintf('-Run %02d, Series %02d, Code %s (%s ==> %s)\n', run, series, code, dicom, fn);
        
        %detect if multiple codes present in a single participant
        if f==1
            codes{p} = code;
        elseif ~strcmp(codes{p}, code)
            warning('ISSUE: inconsistent participant code!')
            found_issue = found_issue + 1;;
            issues = [issues 'inconsistent_code '];
        end
        
        %detect duplicate series
        if any(series_list == series)
            warning('ISSUE: duplicate series found!')
            found_issue = found_issue + 1;;
            issues = [issues 'duplicate_series '];
        end
        series_list(end+1) = series;
        
        %add to excel output
        xls(end+1,:) = {p , run , code , series , fn , dicom , issues};
    end
    
end

%check for duplicate codes
fprintf('\nChecking for duplicate participant codes...\n');
codes_shortlist = codes(~cellfun(@isempty, codes));
if length(codes_shortlist) ~= length(unique(codes_shortlist))
    warning('ISSUE: duplicate participant code found!')
    found_issue = found_issue + 1;;
end

%% Add code list at top of excp
xls_top = {'Participant#' , 'Name' , 'Dicom Code' , 'Issues'};
for p = 1:number_participants
    code = codes{p};
    if ~isempty(code)
        issues = '';
        
        if sum(strcmp(codes, code)) > 1
            issues = [issues 'duplicate_code '];
        end
        
        xls_top(end+1,:) = {p , participant_IDs{p} , code , issues};
    end
end
xls_top{end+1,size(xls,2)} = [];
xls = [xls_top; xls];

%% add warning to excel if issues were found
xls_top = cell(2, size(xls,2));
if found_issue
    xls_top{1,1} = sprintf('WARNING: %d issue(s) detected!', found_issue);
else 
    xls_top{1,1} = 'No issues detected';
end
xls = [xls_top; xls];

%% Write excel
fprintf('\nWriting excel: %s\n', OUTPUT_FILEPATH);
xlswrite(OUTPUT_FILEPATH, xls);

%% Done
if (found_issue)
    error('One or more issues were found! See warning above.')
else
    disp('Done. No issues found.')
end