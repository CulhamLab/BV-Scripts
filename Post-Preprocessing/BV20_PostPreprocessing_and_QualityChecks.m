% All parameters are set in the loaded excel file (not in this script).
%
% Requirements:
% * NeuroElf toolbox installed (tested with neuroelf_v10_5153)
% * BV20 COM is configured
% * Data must have been preprocessed with the BV20 workflow
% * Single session only
% * Data must not have individual run directories (session directory is okay, but only single session is supported)
%
function BV20_PostPreprocessing_and_QualityChecks(xls_filepath)
    %% Temp
    xls_filepath = 'BV20_PostPreprocessing_and_QualityChecks_EXAMPLE.xlsx';

    %% Handle Errors
    try
    
    %% Check requirements
    if ~exist('xff','file')
        error('NeuroElf does not appear to be installed.')
    end
        
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
    p = ProcessParameters(p);

    %% 1. Search for existing files to confirm that everything files exist and are named correctly
    p.file_list = CreateFileList(p);

    %% 2. Check BBR values
    p = CheckBBR(p);

    %% 3. Check motion using the 3DMC SDMs from preprocessing
    p = MotionChecks(p);
    
    %% 4. Link PRTs to VTCs

    %% 5. Apply Linear Trend Removal and Temporal High Pass if not already run

    %% 6. Apply Spatial Smoothing to create set of smoothed VTCs for univariate analyses

    %% 7. Generate SDMs from PRTs

    %% 8. Merge Generated SDMs with 3DMC SDMs (use motion as predictors of no interest)

    %% 9. Generate MDM for each participant and for all participants using SDM with merged 3DMC

    %% Done
    fprintf2(p, '\n\nText outputs are sent to both the MATLAB Command Window and a log file.\nLog Directory: %s\nLog File: %s\n\nComplete!\n', p.DIR.LOG, p.LOGFILENAME);
    for fid = p.LOGFILES
        fclose(fid);
    end
    
    %% Handle Errors
    catch err
        fclose('all');
        rethrow(err);
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Main Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [p] = ScriptConstants
    p.XLS.FILETYPE = 'xls*';
    p.XLS.ROW_START = 2;
    p.XLS.COL_VALUE = 3;
    p.XLS.COL_ID = 5;
    
    p.BBR.GREAT = 0.5;
    p.BBR.OKAY = 0.7;
    p.BBR.POOR = 1;
    
    p.MTN.YAXIS = 1.5;
    
    p.IMG.TYPE = 'png';
end

function [xls_filepath] = GetExcel(p)
    [filename, directory, filter] = uigetfile(['*.' p.XLS.FILETYPE]);
    switch filter
        case 0
            fprintf2(p, 'No file was selected. Script will stop.\n');
            return
        case 1
            xls_filepath = [directory filename];
        case 2
            error2(p, 'Invalid file selected!');
            return
    end
end

function CheckExcel(p, xls_filepath)
    if ~exist(xls_filepath, 'file')
        error2(p, 'File does not exist!');
    else
        type = xls_filepath(find(xls_filepath=='.',1,'last')+1:end);
        if isempty(regexp(type, p.XLS.FILETYPE))
            error2(p, 'Invalid type of file!')
        end
    end
end

function [p] = ReadExcel(p, xls_filepath)
    p.XLS.PATH = xls_filepath;
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

function [p] = ProcessParameters(p)
    %add filsep if needed
    fs = fields(p.DIR);
    for f = 1:length(fs)
        eval(sprintf('val = p.DIR.%s;', fs{f}))
        if ~isnan(val) & (val(end) ~= filesep)
            eval(sprintf('p.DIR.%s(end+1) = filesep;', fs{f}))
        end
    end
    
    %check if output dir exists, create if not
    if ~exist(p.DIR.OUT, 'dir')
        fs = find(p.DIR.OUT == filesep);
        for i = 1:length(fs)
            d = p.DIR.OUT(1:fs(i));
            if ~exist(d, 'dir')
                mkdir(d);
            end
        end
    end
    
    %log directory
    p.DIR.LOG = [p.DIR.OUT 'Logs' filesep];
    if ~exist(p.DIR.LOG, 'dir')
        mkdir(p.DIR.LOG);
    end
    
    %start a log file
    c = clock;
    timestamp = sprintf('%02d-%02d-%02d_%02d-%02d-%04d', round(c([4 5 6 3 2 1])));
    p.LOGFILENAME = sprintf('log_%s.txt', timestamp);
    p.LOGFILES(1) = fopen(sprintf('%slog_latest.txt', p.DIR.OUT), 'w');
    p.LOGFILES(2) = fopen([p.DIR.LOG p.LOGFILENAME], 'w');

    %print parameters
    fprintf2(p, 'PARAMETERS:\n')
    PrintParameters(p);
    
    %check BV dir exists
    if ~exist(p.DIR.BV, 'dir')
        error2(p, 'BV directory does not exist: %s', p.DIR.BV)
    end

    %check if PRTs will be copied over from another directory, if yes check that directory exists
    if isnan(p.DIR.PRT)%E:\Guy\PRTs
        p.PRT.ALLOW_COPY = false;
    elseif ~exist(p.DIR.PRT, 'dir')
        error2(p, 'PRT directory does not exist: %s', p.DIR.PRT)
    else
        p.PRT.ALLOW_COPY = true;
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
                error2(p, 'Unexpected error in parsing participant directory names');
            end
            if (length(p.PAR.ID) >= num) && ~isempty(p.PAR.ID{num})
                error2(p, '%s and %s have the same participant number!', p.PAR.ID{num}, id{1})
            else
                p.PAR.ID{num} = id{1};
            end
        end
    end

    %number of participants
    p.PAR.NUM = length(p.PAR.ID);
    if p.PAR.NUM == 0
        if pid_provided
            error2(p, 'No participants found in provided list: %s', p.PAR.ID_input);
        else
            error2(p, 'No participants found in folder: %s', p.DIR.BV);
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
                error2(p, 'Participant exclusion list contains a number (%d) that exceeds the number of participants!', p.EXCLUDE.PAR_input)
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
                    error2(p, 'Participant exclusion list contains a number (%d) that exceeds the number of participants!', num)
                end
            end
        end
    end

    %alert if missing participants are not on exclude list
    empty = find(cellfun(@isempty, p.PAR.ID));
    for pn = empty
        if ~p.EXCLUDE.PAR(pn)
            error2(p, 'Participant %d is missing, but is not on the exclude list!', pn)
        end
    end

    %display number of participants and which are excluded
    excluded_texts = {'' , ' (EXCLUDED)'};
    fprintf2(p, '\nFound %d participant(s):\n', p.PAR.NUM);
    arrayfun(@(x) fprintf2(p, '%d: %s%s\n', x, p.PAR.ID{x}, excluded_texts{1+p.EXCLUDE.PAR(x)}), 1:p.PAR.NUM);

    %init run exclusions
    p.EXCLUDE.MATRIX = false(p.PAR.NUM, p.PAR.RUN);

    %set run exclusions - excluded subjects
    p.EXCLUDE.MATRIX(p.EXCLUDE.PAR, :) = true;

    %set run exclusions - excluded runs
    p.EXCLUDE.RUN_input = p.EXCLUDE.RUN;
    p.EXCLUDE.RUN = false(1, p.PAR.RUN);
    if ~isnan(p.EXCLUDE.RUN_input)
        if isnumeric(p.EXCLUDE.RUN_input)
            %single numeric input
            if p.EXCLUDE.RUN_input <= p.PAR.RUN
                p.EXCLUDE.RUN(p.EXCLUDE.RUN_input) = true;
            else
                error2(p, 'Run exclusion list contains a number (%d) that exceeds the number of runs!', p.EXCLUDE.RUN_input)
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
                    error2(p, 'Run exclusion list contains a number (%d) that exceeds the number of runs!', num)
                end
            end
        end
    end
    p.EXCLUDE.MATRIX(:, p.EXCLUDE.RUN) = true;
    fprintf2(p, '\nThere in/are %d globally excluded run(s):\n', sum(p.EXCLUDE.RUN))
    for r = find(p.EXCLUDE.RUN)
        fprintf2(p, 'Run %d\n', r)
    end

    %set run exclusions - specific runs
    p.EXCLUDE.PARRUN_input = p.EXCLUDE.PARRUN;
    p.EXCLUDE.PARRUN = [];
    if ~isnan(p.EXCLUDE.PARRUN_input)
        if isnumeric(p.EXCLUDE.PARRUN_input)
            error2(p, 'The list of specific runs to exclude has a format issue!')
        else
            %non-numeric input, and/or potentially multiple
            exclude = strsplit(strrep(p.EXCLUDE.PARRUN_input,' ',''),',');
            exclude(cellfun(@isempty,exclude)) = [];
            
            for e = exclude
                vals = strsplit(e{1},'-');
                
                if length(vals) ~= 2
                    error2(p, 'The list of specific runs to exclude has a format issue: "%s"', e{1})
                end
                
                vals = cellfun(@str2num, vals, 'UniformOutput', false);
                
                if any(cellfun(@isempty, vals))
                    error2(p, 'The list of specific runs to exclude has a format issue: "%s"', e{1})
                end

                vals = cellfun(@(x) x, vals);
                if any(vals<1) | (vals(1)>p.PAR.NUM) | (vals(2)>p.PAR.RUN)
                    error2(p, 'The list of specific runs to exclude has an invalid pair: "%s"', e{1})
                end
                
                p.EXCLUDE.PARRUN(end+1, :) = vals;
                p.EXCLUDE.MATRIX(vals(1), vals(2)) = true;
            end
        end
    end
    p.EXCLUDE.PARRUN = unique(p.EXCLUDE.PARRUN, 'rows');
    fprintf2(p, '\nThere is/are %d specificly excluded run(s):\n', size(p.EXCLUDE.PARRUN, 1))
    for r = 1:size(p.EXCLUDE.PARRUN, 1)
        fprintf2(p, 'Participant %02d Run %02d\n', p.EXCLUDE.PARRUN(r,:))
    end
    
    %display exclusion matrix
    fprintf2(p, '\nExclusion Matrix (ROW=PAR x COL=RUN):\n')
    disp(p.EXCLUDE.MATRIX)
end

function PrintParameters(p, in) %recursive method
    if nargin == 1
        in = {p , 'p'};
    end
    
    if isstruct(in{1})
        for field = fields(in{1})'
            eval(sprintf('PrintParameters(p, {in{1}.%s , [in{2} ''.'' field{1}]});', field{1}));
        end
    else
        if ischar(in{1})
            fprintf2(p, '%s = %s\n', in{2}, sprintf('%s ', in{1}));
        else
            fprintf2(p, '%s = %s\n', in{2}, sprintf('%d ', in{1}));
        end
    end
end

function [file_list] = CreateFileList(p)
    file_list = struct;
    
    for par = 1:p.PAR.NUM
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            continue
        end
        
        %detect session subfolder
        fol = [p.DIR.BV p.PAR.ID{par} filesep];
        fol_session = [fol 'Session-1' filesep];
        if exist(fol_session, 'dir')
            file_list(par).dir = fol_session;
        else
            file_list(par).dir = fol;
        end
        
        fprintf2(p, '\nSearching for %s files in: %s\n', p.PAR.ID{par}, file_list(par).dir)
        
        %look for VMR
        vmr_search = sprintf('%s_%s-S1_BRAIN_IIHC*_MNI.vmr', p.PAR.ID{par}, p.VMR.NAME);
        list = dir([file_list(par).dir vmr_search]);
%         fprintf2(p, '* VMR search results: %s\n', sprintf('%s ', list.name));
        if length(list) > 2
            error2(p, 'Too many VMR found for search: %s\n%s', vmr_search, sprintf('%s\n', list.name))
        elseif length(list) == 2
            num_trf = cellfun(@length, strfind({list.name}, '_TRF'));
            ind_use = find(num_trf);
            if length(ind_use) ~= 1
                error2(p, '2 VMR were found but both have TRFs applied so it is inclear which to use. For search: %s\n%s', vmr_search, sprintf('%s\n', list.name));
            else
                %select the TRF VMR
                file_list(par).vmr = list(ind_use).name;
                fprintf2(p, 'WARNING: Two VMR files were found, but one has TRF so that one will be selected under the assumption that the TRF was to solve the corregistration bug and the non-TRF is left-over from the first attempt.\n');
            end
        else
            %one result
            file_list(par).vmr = list.name;
        end
        fprintf2(p, '* VMR: %s\n', file_list(par).vmr);
        
        %look for all VTC and PRT
        for run = 1:p.PAR.RUN
            fprintf2(p, '* Run %d:\n', run)
            
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2(p, '*   EXCLUDED\n');
                continue
            end
            
            %VTC
            
            vtc_search = sprintf('%s_%s-S1R%d_*MNI*.vtc', p.PAR.ID{par}, p.VTC.NAME, run);
            list = dir([file_list(par).dir vtc_search]);
            filenames = {list.name};
            
            %error if no results
            if isempty(list)
                error2(p, 'Could not find any VTC for search: %s', vtc_search)
            end
            
            %discard files that have not been motion corrected
            filenames(cellfun(@isempty, strfind(filenames, '3DMCTS'))) = [];
            
            %error if no motion corrected results
            if ~isempty(list) & isempty(filenames)
                error2(p, 'Could not find motion corrected VTC for search: %s', vtc_search)
            end
            
            %discard any that are already smoothed (on FMR or VTC level)
            ind_smoothed = ~cellfun(@isempty, regexp(filenames, 'SS[-.0-9]*mm'));
            filenames(ind_smoothed) = [];
            
            %expect a single result (the output VTC from preprocessing)
            if length(filenames) > 1
                error2(p, 'Too many potential VTC found for search: %s\n%s', vtc_search, sprintf('%s\n', filenames{:}))
            elseif isempty(filenames)
                error2(p, 'No potential VTC found. This can occur if spatial smoothing was performed during preprocessing. For search: %s', vtc_search)
            else
                file_list(par).run(run).vtc_base = filenames{1};
            end
            fprintf2(p, '*   VTC: %s\n', file_list(par).run(run).vtc_base)
            
            
            %PRT
            search = ApplyNamingConvention(p.PRT.NAMING, par, run, p);
            list = dir([file_list(par).dir search]);
            do_copy = false;
            if isempty(list) & p.PRT.ALLOW_COPY
                list = dir([p.DIR.PRT search]);
                do_copy = true;
            end
            if length(list) > 1
                error2(p, 'Too many potential PRT found for search: %s\n%s', search, sprintf('%s\n', list.name))
            elseif isempty(list)
                error2(p, 'No PRT found for search: %s', search)
            else
                %select the one result
                file_list(par).run(run).prt = list.name;
            end
            fprintf2(p, '*   PRT: %s\n', file_list(par).run(run).prt)
            if do_copy
                fprintf2(p, '*   Copying PRT to BV folder from: %s\n', p.DIR.PRT)
                copyfile([p.DIR.PRT file_list(par).run(run).prt], [file_list(par).dir file_list(par).run(run).prt])
            end
        end 
    end
end

function [p] = CheckBBR(p)
    p.BBR.bbr_cost_end = nan(p.PAR.NUM, p.PAR.RUN);

    fprintf2(p, '\nBoundary-Based Registration (BBR) cost values will now be checked.\nLower values indicate better FMR-VMR alignment.\n')

    fol = [p.DIR.BV '_WorkflowReports_' filesep 'texts' filesep];
    if ~exist(fol, 'dir')
        fprintf2(p, 'WARNING: Skipping BBR checks because directory was not found: %s\n', fol)
        return
    end
    
    fprintf2(p, 'The cutoff values used are:\nGREAT <= %g\nOKAY <= %g\nPOOR <= %g\nUNACCEPTABLE > %g\n', p.BBR.GREAT, p.BBR.OKAY, p.BBR.POOR, p.BBR.POOR);
    
    for par = 1:p.PAR.NUM
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            continue
        end
        
        fprintf2(p, 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        for run = 1:p.PAR.RUN
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2(p, '* Run %d: EXCLUDED\n', run);
                continue
            end
            
            search = sprintf('Workflow_*_%s_%s-S1R%d_%s-S1_BRAIN_IIHC_1_COREG_BBR.txt', p.PAR.ID{par}, p.VTC.NAME, run, p.VMR.NAME);
            list = dir([fol search]);
            
            if length(list) > 1
                error2(p, 'Too many BBR files found for search: %s\n%s', search, sprintf('%s\n', list.name))
            elseif isempty(list)
                error2(p, 'No BBR files found for search: %s', search)
            else
                text = fileread([fol list.name]);
                p.BBR.bbr_cost_end(par, run) = str2num(text(find(text=='.',1,'last')-1:end));
                
                if p.BBR.bbr_cost_end(par, run) <= p.BBR.GREAT
                    p.BBR.bbr_cost_end_assessment{par, run} = 'GREAT';
                elseif p.BBR.bbr_cost_end(par, run) <= p.BBR.OKAY
                    p.BBR.bbr_cost_end_assessment{par, run} = 'OKAY';
                elseif p.BBR.bbr_cost_end(par, run) <= p.BBR.POOR
                    p.BBR.bbr_cost_end_assessment{par, run} = 'POOR';
                else
                    error2(p, 'BBR cost is too high (%g) for Participant %d (%s) Run %d. The FMR-VMR alignment must be improved or the par/run excluded.', p.BBR.bbr_cost_end(par, run), par, p.PAR.ID{par}, run)
                end
                
                fprintf2(p, '* Run %d: %g (%s)\n', run, p.BBR.bbr_cost_end(par, run), p.BBR.bbr_cost_end_assessment{par, run});
            end
            
        end
    end
end

function [p] = MotionChecks(p)
    p.DIR.MTN = [p.DIR.OUT 'Motion_Plots' filesep];
    if ~exist(p.DIR.MTN, 'dir')
        mkdir(p.DIR.MTN);
    end
    
    p.MTN.SDMMatrix = cell(p.PAR.NUM, p.PAR.RUN);

    fprintf2(p, '\nMotion plots will not be generated.\nIt is up to you to determine if any pars/runs contain too much motion.\nIn the future, we should include criteria for how much motion is acceptable.\nPlots Directory: %s', p.DIR.MTN);

    for par = 1:p.PAR.NUM
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            continue
        end
        
        fprintf2(p, 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        for run = 1:p.PAR.RUN
            fprintf2(p, '* Run %d\n', run);
            
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2(p, '*   EXCLUDED\n');
                continue
            end
            
            search = sprintf('%s_%s-S1R%d_3DMC.sdm', p.PAR.ID{par}, p.VTC.NAME, run);
            list = dir([p.file_list(par).dir search]);
            if length(list) > 1
                error2(p, 'Too many files found for SDM searc: %s\n%s', search, sprintf('%s\n', list.name));
            elseif isempty(list)
                error2(p, 'No files found for SDM searc: %s', search);
            else
                p.file_list(par).sdm_motion_filename = list.name;
                sdm = xff([p.file_list(par).dir p.file_list(par).sdm_motion_filename]);
                p.MTN.SDMMatrix{par, run} = sdm.SDMMatrix;
                p.MTN.PredictorColors{par, run} = sdm.PredictorColors;
                p.MTN.PredictorNames{par, run} = sdm.PredictorNames;
                sdm.clear;
                
                xyz = p.MTN.SDMMatrix{par, run}(:,1:3);
                p.MTN.position{par, run} = sqrt(sqrt(xyz(:,1).^2 + xyz(:,2).^2) + xyz(:,3).^2);
                p.MTN.position_delta{par, run} = diff(p.MTN.position{par, run});
                xyzr = p.MTN.SDMMatrix{par, run}(:,4:6);
                p.MTN.rotation{par, run} = sqrt(sqrt(xyzr(:,1).^2 + xyzr(:,2).^2) + xyzr(:,3).^2);
                p.MTN.rotation_delta{par, run} = diff(p.MTN.rotation{par, run});
                
                fprintf2(p, '*   Translation per volume mean: %gmm\n', mean(p.MTN.position_delta{par, run}));
                fprintf2(p, '*   Translation per volume max: %gmm\n', max(p.MTN.position_delta{par, run}));
                fprintf2(p, '*   Translation per volume std: %gmm\n', std(p.MTN.position_delta{par, run}));
                fprintf2(p, '*   Rotation per volume mean: %gdeg\n', mean(p.MTN.rotation_delta{par, run}));
                fprintf2(p, '*   Rotation per volume max: %gdeg\n', max(p.MTN.rotation_delta{par, run}));
                fprintf2(p, '*   Rotation per volume std: %gdeg\n', std(p.MTN.rotation_delta{par, run}));
            end
        end
        
        %figure
        if ~exist('fig', 'var')
            fig = figure('Position',[0 0 ((p.PAR.RUN*500)+200) 1000]);
        end
        filepath_plot = sprintf('%sPAR%02d_%s.%s', p.DIR.MTN, par, p.PAR.ID{par}, p.IMG.TYPE);
        if exist(filepath_plot, 'file') & ~p.MTN.OVERWRITE
            fprintf2(p, '* Plot already exists and WILL NOT be overwritten\n');
        else
            if exist(filepath_plot, 'file')
                fprintf2(p, '* Plot already exists, but WILL be overwritten\n');
            end
            
            max_run_length = max(cellfun(@length, p.MTN.SDMMatrix(par, :)));
            pos_all = [];
            rot_all = [];
            for run = 1:p.PAR.RUN
                starts(run) = length(pos_all) + 1;
                if isempty(p.MTN.SDMMatrix{par, run})
                    pos_all = [pos_all; nan(max_run_length, 1)];
                    rot_all = [rot_all; nan(max_run_length, 1)];
                else
                    pos_all = [pos_all; p.MTN.position{par, run}];
                    rot_all = [rot_all; p.MTN.rotation{par, run}];
                end
            end
            pl = plot([pos_all rot_all]);
            xlabel('Volume')
            ylabel('mm or deg');
            a = [1 length(pos_all) 0 p.MTN.YAXIS];
            axis(a);
            hold on
            exclude_text = {'' ' (EXCLUDE)'};
            for run = 1:p.PAR.RUN
                plot([starts(run) starts(run)], a(3:4), 'r')
                text(starts(run), a(4)*0.95, sprintf('Run %d%s', run, exclude_text{1 + p.EXCLUDE.MATRIX(par,run)}), 'Color', 'r');
            end
            hold off
            legend(pl, {'Position','Rotation'}, 'Location', 'EastOutside')
            title(sprintf('Participant %d: %s', par, p.PAR.ID{par}));
            saveas(fig, filepath_plot, p.IMG.TYPE);
            fprintf2(p, '* Plot: %s\n', filepath_plot);
        end
        
    end
    
    if exist('fig', 'var')
        close(fig);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Utility Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [string] = ApplyNamingConvention(string, par, run, p);
    string = strrep(string, '[PID]', p.PAR.ID{par});
    
    expressions = regexp(string, '\[R#[0-9]*\]', 'match');
    for exp = expressions
        exp = exp{1};
        
        num = exp(find(exp=='#')+1:find(exp==']')-1);
        replace = sprintf(sprintf('%%0%sd', num), run);
        
        string = strrep(string, exp, replace);    
    end
    
    expressions = regexp(string, '\[P#[0-9]*\]', 'match');
    for exp = expressions
        exp = exp{1};
        
        num = exp(find(exp=='#')+1:find(exp==']')-1);
        replace = sprintf(sprintf('%%0%sd', num), par);
        
        string = strrep(string, exp, replace);    
    end
end

function error2(varargin)
    p = varargin{1};
    message = varargin{2};
    
    if nargin < 3
        args = '';
    else
        args = sprintf(', varargin{%d}', 3:nargin);
    end
    
    fprintf2(p, '\n\n\n');
    eval(sprintf('fprintf2(p,[''ERROR: '' message],''%s''%s);', message, args))
    eval(sprintf('error(''%s''%s);', message, args))
    
end

%this fprintf send to both command window and a log file
function fprintf2(varargin)
    p = varargin{1};
    message = varargin{2};
    
    if nargin < 3
        args = '';
    else
        args = sprintf(', varargin{%d}', 3:nargin);
    end
    
    eval(sprintf('fprintf(''%s''%s);', message, args))
    for fid = p.LOGFILES
        eval(sprintf('fprintf(fid, ''%s''%s);', message, args))
    end
end

%newer versions of MATLAB do not have this function
function hout=suptitle(str)
    %SUPTITLE puts a title above all subplots.
    %
    %	SUPTITLE('text') adds text to the top of the figure
    %	above all subplots (a "super title"). Use this function
    %	after all subplot commands.
    %
    %   SUPTITLE is a helper function for yeastdemo.

    %   Copyright 2003-2010 The MathWorks, Inc.


    % Warning: If the figure or axis units are non-default, this
    % will break.

    % Parameters used to position the supertitle.

    % Amount of the figure window devoted to subplots
    plotregion = .92;

    % Y position of title in normalized coordinates
    titleypos  = .95;

    % Fontsize for supertitle
    fs = get(gcf,'defaultaxesfontsize')+4;

    % Fudge factor to adjust y spacing between subplots
    fudge=1;

    haold = gca;
    figunits = get(gcf,'units');

    % Get the (approximate) difference between full height (plot + title
    % + xlabel) and bounding rectangle.

    if (~strcmp(figunits,'pixels')),
        set(gcf,'units','pixels');
        pos = get(gcf,'position');
        set(gcf,'units',figunits);
    else
        pos = get(gcf,'position');
    end
    ff = (fs-4)*1.27*5/pos(4)*fudge;

    % The 5 here reflects about 3 characters of height below
    % an axis and 2 above. 1.27 is pixels per point.

    % Determine the bounding rectangle for all the plots

    % h = findobj('Type','axes');

    % findobj is a 4.2 thing.. if you don't have 4.2 comment out
    % the next line and uncomment the following block.

    h = findobj(gcf,'Type','axes');  % Change suggested by Stacy J. Hills

    max_y=0;
    min_y=1;
    oldtitle = NaN;
    numAxes = length(h);
    thePositions = zeros(numAxes,4);
    for i=1:numAxes
        pos=get(h(i),'pos');
        thePositions(i,:) = pos;
        if (~strcmp(get(h(i),'Tag'),'suptitle')),
            if (pos(2) < min_y)
                min_y=pos(2)-ff/5*3;
            end;
            if (pos(4)+pos(2) > max_y)
                max_y=pos(4)+pos(2)+ff/5*2;
            end;
        else
            oldtitle = h(i);
        end
    end

    if max_y > plotregion,
        scale = (plotregion-min_y)/(max_y-min_y);
        for i=1:numAxes
            pos = thePositions(i,:);
            pos(2) = (pos(2)-min_y)*scale+min_y;
            pos(4) = pos(4)*scale-(1-scale)*ff/5*3;
            set(h(i),'position',pos);
        end
    end

    np = get(gcf,'nextplot');
    set(gcf,'nextplot','add');
    if ishghandle(oldtitle)
        delete(oldtitle);
    end
    axes('pos',[0 1 1 1],'visible','off','Tag','suptitle');
    ht=text(.5,titleypos-1,str);set(ht,'horizontalalignment','center','fontsize',fs);
    set(gcf,'nextplot',np);
    axes(haold); %#ok<MAXES>
    if nargout,
        hout=ht;
    end
end