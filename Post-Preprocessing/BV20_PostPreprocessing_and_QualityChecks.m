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

    %% Select Excel file (unless passed as input in which case check it)
    if ~exist('xls_filepath','var')
        xls_filepath = GetExcel(p);
    else
        CheckExcel(p, xls_filepath);
    end

    %% Add parameters from excel and process them (check dirs, number of participants, participant IDs, etc)
    p = ReadExcel(p, xls_filepath);
    ProcessParameters(p);

    %% 1. Search for existing files to confirm that everything files exist and are named correctly + check which steps were done in preprocessing
    file_list = CreateFileList(p);
    CheckFiles;

    %% 2. Gather BBR values and report any issues

    %% 3. Run motion checks, create summary figures, and report any issues

    %% 4. Link PRTs to VTCs

    %% 5. Apply Linear Trend Removal and Temporal High Pass if not already run

    %% 6. Apply Spatial Smoothing to create set of smoothed VTCs for univariate analyses

    %% 7. Generate SDMs from PRTs

    %% 8. Merge Generated SDMs with 3DMC SDMs (use motion as predictors of no interest)

    %% 9. Generate MDM for each participant and for all participants using SDM with merged 3DMC

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [p] = ScriptConstants
    p.XLS.FILETYPE = 'xls*';
    p.XLS.ROW_START = 2;
    p.XLS.COL_VALUE = 3;
    p.XLS.COL_ID = 5;
end

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
end

function ProcessParameters(p)
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

    %check if PRTs will be copied over from another directory, if yes check that directory exists
    if isnan(p.DIR.PRT)%E:\Guy\PRTs
        p.PRT.DO_COPY = false;
    elseif ~exist(p.DIR.PRT, 'dir')
        error('PRT directory does not exist: %s', p.DIR.PRT)
    else
        p.PRT.DO_COPY = true;
    end

    %participant IDs
    pid_provided = false;
    if ~isnan(p.PAR.ID)
        %ID are provided
        p.PAR.ID_input = p.PAR.ID;
        p.PAR.ID = strsplit(strrep(p.PAR.ID, ' ', ''),',');
        p.PAR.ID(cellfun(@isempty,p.PAR.ID)) = [];
        pid_provided = true;
    else
        %ID not provided, find them (assume P# or P## format)
        list = dir(p.DIR.BV);
        list = list([list.isdir]);
        list = list(cellfun(@(x) ~any(x==' ' | x=='.'), {list.name})); %cannot contain spaces or periods

        %select only P# and P## format
        potential_matches = cellfun(@(x) regexp(x, 'P[0-9]*', 'match'), {list.name}, 'UniformOutput', false);
        matches = arrayfun(@(x) ~isempty(potential_matches{x}) && strcmp(potential_matches{x}{1}, list(x).name), 1:length(list));
        IDs = {list(matches).name};

        %get participant numbers from IDs
        p.PAR.ID = cell(0);
        for id = IDs
            num = str2num(id{1}(2:end));
            if length(num) ~= 1
                error('Unexpected error in parsing participant directory names');
            end
            if (length(p.PAR.ID) >= num) && ~isempty(p.PAR.ID{num})
                error('%s and %s have the same participant number!', p.PAR.ID{num}, id{1})
            else
                p.PAR.ID{num} = id{1};
            end
        end
    end

    %number of participants
    p.PAR.NUM = length(p.PAR.ID);
    if p.PAR.NUM == 0
        if pid_provided
            error('No participants found in provided list: %s', p.PAR.ID_input);
        else
            error('No participants found in folder: %s', p.DIR.BV);
        end
    end

    %excluded participants
    p.EXCLUDE.PAR_input = p.EXCLUDE.PAR;
    p.EXCLUDE.PAR = false(1, p.PAR.NUM);
    if ~isnan(p.EXCLUDE.PAR_input)
        if isnumeric(p.EXCLUDE.PAR_input)
            %single numeric input
            if p.EXCLUDE.PAR_input <= p.PAR.NUM
                p.EXCLUDE.PAR(p.EXCLUDE.PAR_input) = true;
            else
                error('Participant exclusion list contains a number (%d) that exceeds the number of participants!', p.EXCLUDE.PAR_input)
            end
        else
            %non-numeric input, and/or potentially multiple
            exclude = strsplit(strrep(p.EXCLUDE.PAR_input,' ',''),',');
            exclude(cellfun(@isempty,exclude)) = [];
            for e = exclude
                num = str2num(e{1});
                if isempty(num)
                    %ID provided
                    num = str2num(e{1}(2:end));
                end
                if num <= p.PAR.NUM
                    p.EXCLUDE.PAR(num) = true;
                else
                    error('Participant exclusion list contains a number (%d) that exceeds the number of participants!', num)
                end
            end
        end
    end

    %alert if missing participants are not on exclude list
    empty = find(cellfun(@isempty, p.PAR.ID));
    for pn = empty
        if ~p.EXCLUDE.PAR(pn)
            error('Participant %d is missing, but is not on the exclude list!', pn)
        end
    end

    %display number of participants and which are excluded
    excluded_texts = {'' , ' (EXCLUDED)'};
    fprintf('\nFound %d participant(s):\n', p.PAR.NUM);
    arrayfun(@(x) fprintf('%d: %s%s\n', x, p.PAR.ID{x}, excluded_texts{1+p.EXCLUDE.PAR(x)}), 1:p.PAR.NUM);

    %init run exclusions
    p.EXCLUDE.MATRIX = false(p.PAR.NUM, p.PAR.RUN);

    %set run exclusions - excluded subjects
    p.EXCLUDE.MATRIX(p.EXCLUDE.PAR, :) = true;

    %set run exclusions - excluded runs
    p.EXCLUDE.RUN_input = p.EXCLUDE.RUN;
    p.EXCLUDE.RUN = false(1, p.PAR.RUN);
    if ~isnan(p.EXCLUDE.PAR_input)
        if isnumeric(p.EXCLUDE.RUN_input)
            %single numeric input
            if p.EXCLUDE.RUN_input <= p.PAR.RUN
                p.EXCLUDE.RUN(p.EXCLUDE.RUN_input) = true;
            else
                error('Run exclusion list contains a number (%d) that exceeds the number of runs!', p.EXCLUDE.RUN_input)
            end
        else
            %non-numeric input, and/or potentially multiple
            exclude = strsplit(strrep(p.EXCLUDE.RUN_input,' ',''),',');
            exclude(cellfun(@isempty,exclude)) = [];
            for e = exclude
                num = str2num(e{1});
                if isempty(num)
                    %ID provided
                    num = str2num(e{1}(2:end));
                end
                if num <= p.PAR.RUN
                    p.EXCLUDE.RUN(num) = true;
                else
                    error('Run exclusion list contains a number (%d) that exceeds the number of runs!', num)
                end
            end
        end
    end
    p.EXCLUDE.MATRIX(:, p.EXCLUDE.RUN) = true;
    fprintf('\nThere are %d globally excluded runs:\n', sum(p.EXCLUDE.RUN))
    for r = find(p.EXCLUDE.RUN)
        fprintf('Run %d\n', r)
    end

    %set run exclusions - specific runs
    p.EXCLUDE.PARRUN_input = p.EXCLUDE.PARRUN;
    p.EXCLUDE.PARRUN = [];
    if ~isnan(p.EXCLUDE.PARRUN_input)
        if isnumeric(p.EXCLUDE.PARRUN_input)
            error('The list of specific runs to exclude has a format issue!')
        else
            %non-numeric input, and/or potentially multiple
            exclude = strsplit(strrep(p.EXCLUDE.PARRUN_input,' ',''),',');
            exclude(cellfun(@isempty,exclude)) = [];
            
            for e = exclude
                vals = strsplit(e{1},'-');
                
                if length(vals) ~= 2
                    error('The list of specific runs to exclude has a format issue: "%s"', e{1})
                end
                
                vals = cellfun(@str2num, vals, 'UniformOutput', false);
                
                if any(cellfun(@isempty, vals))
                    error('The list of specific runs to exclude has a format issue: "%s"', e{1})
                end

                vals = cellfun(@(x) x, vals);
                if any(vals<1) | (vals(1)>p.PAR.NUM) | (vals(2)>p.PAR.RUN)
                    error('The list of specific runs to exclude has an invalid pair: "%s"', e{1})
                end
                
                p.EXCLUDE.PARRUN(end+1, :) = vals;
                p.EXCLUDE.MATRIX(vals(1), vals(2)) = true;
            end
        end
    end
    p.EXCLUDE.PARRUN = unique(p.EXCLUDE.PARRUN, 'rows');
    fprintf('\nThere are %d specificly excluded runs:\n', size(p.EXCLUDE.PARRUN, 1))
    for r = 1:size(p.EXCLUDE.PARRUN, 1)
        fprintf('Participant %02d Run %02d\n', p.EXCLUDE.PARRUN(r,:))
    end
    
    %display exclusion matrix
    fprintf('\nExclusion Matrix (ROW=PAR x COL=RUN):\n')
    disp(p.EXCLUDE.MATRIX)
end

function [file_list] = CreateFileList(p)
    %TODO
    file_list=[];
end

function CheckFiles
	
end