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
    ScriptConstants;

    %% Select Excel file (unless passed as input in which case check it)
    if ~exist('xls_filepath','var')
        xls_filepath = GetExcel;
    else
        CheckExcel(xls_filepath);
    end

    %% Add parameters from excel and process them (check dirs, number of participants, participant IDs, etc)
    ReadExcel(xls_filepath);
    ProcessParameters;

    %% 1. Search for existing files to confirm that all core files are present
    CreateFileList;

    %% 2. Check BBR values
    CheckBBR;

    %% 3. Check motion using the 3DMC SDMs from preprocessing
    MotionChecks;

    %% 5. Link Non-Smoothed VTC to PRT
    LinkVTCtoPRT;
    
    %% 4. Non-Smoothed VTC: Apply Linear Trend Removal + Temporal High Pass, then Spatial Smoothing (unless already done)
    
    %% 6. Generate SDMs from PRTs (add motion from 3DMC SDMs as predictors of no interest)

    %% 7. Generate MDM for each participant and for all participants

    %% Save and Done
    global p
    
    fprintf2( '\n\nText outputs are sent to both the MATLAB Command Window and a log file.\nLog Directory: %s\nLog File: %s\n', p.DIR.LOG, p.LOGFILENAME);
    
    p.DIR.SAVE = [p.DIR.OUT 'Save' filesep];
    if ~exist(p.DIR.SAVE, 'dir')
        mkdir(p.DIR.SAVE);
    end
    fn = sprintf('run_%s.mat', p.timestamp);
    save([p.DIR.SAVE fn],'p');
    save([p.DIR.OUT 'run_latest.mat'],'p');
    
    fprintf2( '\n\nRutime data is saved:\nDirectory: %s\nFile: %s\n', p.DIR.SAVE, fn);
    
    fprintf2( '\n\nComplete!\n');
    
    for fid = p.LOGFILES
        fclose(fid);
    end
    
    %% Handle Errors
    catch err
        global p
        if exist('p', 'var') & any(strcmp(fields(p), 'LOGFILES'))
            for fid = p.LOGFILES
                fclose(fid);
            end
        end
        if exist('p', 'var') & any(strcmp(fields(p), 'fig')) & ishandle(p.fig)
            close(p.fig);
        end
        rethrow(err);
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Main Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ScriptConstants
    global p
    p = struct;

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

function [xls_filepath] = GetExcel
    global p
    [filename, directory, filter] = uigetfile(['*.' p.XLS.FILETYPE]);
    switch filter
        case 0
            fprintf2( 'No file was selected. Script will stop.\n');
            return
        case 1
            xls_filepath = [directory filename];
        case 2
            error2( 'Invalid file selected!');
            return
    end
end

function CheckExcel(xls_filepath)
    global p
    if ~exist(xls_filepath, 'file')
        error2( 'File does not exist!');
    else
        type = xls_filepath(find(xls_filepath=='.',1,'last')+1:end);
        if isempty(regexp(type, p.XLS.FILETYPE))
            error2( 'Invalid type of file!')
        end
    end
end

function ReadExcel(xls_filepath)
    global p
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

function ProcessParameters
    global p
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
    p.timestamp = sprintf('%02d-%02d-%02d_%02d-%02d-%04d', round(c([4 5 6 3 2 1])));
    p.LOGFILENAME = sprintf('log_%s.txt', p.timestamp);
    p.LOGFILES(1) = fopen(sprintf('%slog_latest.txt', p.DIR.OUT), 'w');
    p.LOGFILES(2) = fopen([p.DIR.LOG p.LOGFILENAME], 'w');

    %print parameters
    fprintf2( 'PARAMETERS:\n')
    PrintParameters;
    
    %check BV dir exists
    if ~exist(p.DIR.BV, 'dir')
        error2( 'BV directory does not exist: %s', p.DIR.BV)
    end

    %check if PRTs will be copied over from another directory, if yes check that directory exists
    if isnan(p.DIR.PRT)%E:\Guy\PRTs
        p.PRT.ALLOW_COPY = false;
    elseif ~exist(p.DIR.PRT, 'dir')
        error2( 'PRT directory does not exist: %s', p.DIR.PRT)
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
                error2( 'Unexpected error in parsing participant directory names');
            end
            if (length(p.PAR.ID) >= num) && ~isempty(p.PAR.ID{num})
                error2( '%s and %s have the same participant number!', p.PAR.ID{num}, id{1})
            else
                p.PAR.ID{num} = id{1};
            end
        end
    end

    %number of participants
    p.PAR.NUM = length(p.PAR.ID);
    if p.PAR.NUM == 0
        if pid_provided
            error2( 'No participants found in provided list: %s', p.PAR.ID_input);
        else
            error2( 'No participants found in folder: %s', p.DIR.BV);
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
                error2( 'Participant exclusion list contains a number (%d) that exceeds the number of participants!', p.EXCLUDE.PAR_input)
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
                    error2( 'Participant exclusion list contains a number (%d) that exceeds the number of participants!', num)
                end
            end
        end
    end

    %alert if missing participants are not on exclude list
    empty = find(cellfun(@isempty, p.PAR.ID));
    for pn = empty
        if ~p.EXCLUDE.PAR(pn)
            error2( 'Participant %d is missing, but is not on the exclude list!', pn)
        end
    end

    %display number of participants and which are excluded
    excluded_texts = {'' , ' (EXCLUDED)'};
    fprintf2( '\nFound %d participant(s):\n', p.PAR.NUM);
    arrayfun(@(x) fprintf2( '%d: %s%s\n', x, p.PAR.ID{x}, excluded_texts{1+p.EXCLUDE.PAR(x)}), 1:p.PAR.NUM);

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
                error2( 'Run exclusion list contains a number (%d) that exceeds the number of runs!', p.EXCLUDE.RUN_input)
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
                    error2( 'Run exclusion list contains a number (%d) that exceeds the number of runs!', num)
                end
            end
        end
    end
    p.EXCLUDE.MATRIX(:, p.EXCLUDE.RUN) = true;
    fprintf2( '\nThere in/are %d globally excluded run(s):\n', sum(p.EXCLUDE.RUN))
    for r = find(p.EXCLUDE.RUN)
        fprintf2( 'Run %d\n', r)
    end

    %set run exclusions - specific runs
    p.EXCLUDE.PARRUN_input = p.EXCLUDE.PARRUN;
    p.EXCLUDE.PARRUN = [];
    if ~isnan(p.EXCLUDE.PARRUN_input)
        if isnumeric(p.EXCLUDE.PARRUN_input)
            error2( 'The list of specific runs to exclude has a format issue!')
        else
            %non-numeric input, and/or potentially multiple
            exclude = strsplit(strrep(p.EXCLUDE.PARRUN_input,' ',''),',');
            exclude(cellfun(@isempty,exclude)) = [];
            
            for e = exclude
                vals = strsplit(e{1},'-');
                
                if length(vals) ~= 2
                    error2( 'The list of specific runs to exclude has a format issue: "%s"', e{1})
                end
                
                vals = cellfun(@str2num, vals, 'UniformOutput', false);
                
                if any(cellfun(@isempty, vals))
                    error2( 'The list of specific runs to exclude has a format issue: "%s"', e{1})
                end

                vals = cellfun(@(x) x, vals);
                if any(vals<1) | (vals(1)>p.PAR.NUM) | (vals(2)>p.PAR.RUN)
                    error2( 'The list of specific runs to exclude has an invalid pair: "%s"', e{1})
                end
                
                p.EXCLUDE.PARRUN(end+1, :) = vals;
                p.EXCLUDE.MATRIX(vals(1), vals(2)) = true;
            end
        end
    end
    p.EXCLUDE.PARRUN = unique(p.EXCLUDE.PARRUN, 'rows');
    fprintf2( '\nThere is/are %d specificly excluded run(s):\n', size(p.EXCLUDE.PARRUN, 1))
    for r = 1:size(p.EXCLUDE.PARRUN, 1)
        fprintf2( 'Participant %02d Run %02d\n', p.EXCLUDE.PARRUN(r,:))
    end
    
    %display exclusion matrix
    fprintf2( '\nExclusion Matrix (ROW=PAR x COL=RUN):\n')
    disp(p.EXCLUDE.MATRIX)
end

function PrintParameters(in) %recursive method
    global p
    if nargin == 0
        in = {p , 'p'};
    end
    
    if isstruct(in{1})
        for field = fields(in{1})'
            eval(sprintf('PrintParameters({in{1}.%s , [in{2} ''.'' field{1}]});', field{1}));
        end
    else
        if ischar(in{1})
            fprintf2( '%s = %s\n', in{2}, sprintf('%s ', in{1}));
        else
            fprintf2( '%s = %s\n', in{2}, sprintf('%d ', in{1}));
        end
    end
end

function CreateFileList
    global p
    p.file_list = struct;
    
    fprintf2( '\nSearching for existing files...\n');
    
    for par = 1:p.PAR.NUM
        fprintf('Participant %d (%s):\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        %detect session subfolder
        fol = [p.DIR.BV p.PAR.ID{par} filesep];
        fol_session = [fol 'Session-1' filesep];
        if exist(fol_session, 'dir')
            p.file_list(par).dir = fol_session;
        else
            p.file_list(par).dir = fol;
        end
        
        fprintf2( '* Searching for files in: %s\n', p.file_list(par).dir)
        
        %look for VMR
        vmr_search = sprintf('%s_%s-S1_BRAIN_IIHC*_MNI.vmr', p.PAR.ID{par}, p.VMR.NAME);
        list = dir([p.file_list(par).dir vmr_search]);
%         fprintf2( '* VMR search results: %s\n', sprintf('%s ', list.name));
        if length(list) > 2
            error2( 'Too many VMR found for search: %s\n%s', vmr_search, sprintf('%s\n', list.name))
        elseif length(list) == 2
            num_trf = cellfun(@length, strfind({list.name}, '_TRF'));
            ind_use = find(num_trf);
            if length(ind_use) ~= 1
                error2( '2 VMR were found but both have TRFs applied so it is inclear which to use. For search: %s\n%s', vmr_search, sprintf('%s\n', list.name));
            else
                %select the TRF VMR
                p.file_list(par).vmr = list(ind_use).name;
                fprintf2( 'WARNING: Two VMR files were found, but one has TRF so that one will be selected under the assumption that the TRF was to solve the corregistration bug and the non-TRF is left-over from the first attempt.\n');
            end
        else
            %one result
            p.file_list(par).vmr = list.name;
        end
        fprintf2( '* VMR: %s\n', p.file_list(par).vmr);
        
        %look for all VTC and PRT
        for run = 1:p.PAR.RUN
            fprintf2( '* Run %d:\n', run)
            
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2( '*   EXCLUDED\n');
                continue
            end
            
            %VTC
            
            vtc_search = sprintf('%s_%s-S1R%d_*MNI*.vtc', p.PAR.ID{par}, p.VTC.NAME, run);
            list = dir([p.file_list(par).dir vtc_search]);
            filenames = {list.name};
            
            %error if no results
            if isempty(list)
                error2( 'Could not find any VTC for search: %s', vtc_search)
            end
            
            %discard files that have not been motion corrected
            filenames(cellfun(@isempty, strfind(filenames, '3DMCTS'))) = [];
            
            %error if no motion corrected results
            if ~isempty(list) & isempty(filenames)
                error2( 'Could not find motion corrected VTC for search: %s', vtc_search)
            end
            
            %discard any that are already smoothed (on FMR or VTC level)
            ind_smoothed = ~cellfun(@isempty, regexp(filenames, 'SS[-.0-9]*mm'));
            filenames(ind_smoothed) = [];
            
            %expect a single result (the output VTC from preprocessing)
            if length(filenames) > 1
                error2( 'Too many potential VTC found for search: %s\n%s', vtc_search, sprintf('%s\n', filenames{:}))
            elseif isempty(filenames)
                error2( 'No potential VTC found. This can occur if spatial smoothing was performed during preprocessing. For search: %s', vtc_search)
            else
                p.file_list(par).run(run).vtc_base = filenames{1};
            end
            fprintf2( '*   VTC: %s\n', p.file_list(par).run(run).vtc_base)
            
            
            %PRT
            search = ApplyNamingConvention(p.PRT.NAMING, par, run);
            list = dir([p.file_list(par).dir search]);
            do_copy = false;
            if isempty(list) & p.PRT.ALLOW_COPY
                list = dir([p.DIR.PRT search]);
                do_copy = true;
            end
            if length(list) > 1
                error2( 'Too many potential PRT found for search: %s\n%s', search, sprintf('%s\n', list.name))
            elseif isempty(list)
                error2( 'No PRT found for search: %s', search)
            else
                %select the one result
                p.file_list(par).run(run).prt = list.name;
            end
            fprintf2( '*   PRT: %s\n', p.file_list(par).run(run).prt)
            if do_copy
                fprintf2( '*   Copying PRT to BV folder from: %s\n', p.DIR.PRT)
                copyfile([p.DIR.PRT p.file_list(par).run(run).prt], [p.file_list(par).dir p.file_list(par).run(run).prt])
            end
        end 
    end
end

function CheckBBR
    global p
    p.BBR.bbr_cost_end = nan(p.PAR.NUM, p.PAR.RUN);

    fprintf2( '\nBoundary-Based Registration (BBR) cost values will now be checked.\nLower values indicate better FMR-VMR alignment.\n')

    fol = [p.DIR.BV '_WorkflowReports_' filesep 'texts' filesep];
    if ~exist(fol, 'dir')
        fprintf2( 'WARNING: Skipping BBR checks because directory was not found: %s\n', fol)
        return
    end
    
    fprintf2( 'The cutoff values used are:\nGREAT <= %g\nOKAY <= %g\nPOOR <= %g\nUNACCEPTABLE > %g\n', p.BBR.GREAT, p.BBR.OKAY, p.BBR.POOR, p.BBR.POOR);
    
    for par = 1:p.PAR.NUM
        fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        for run = 1:p.PAR.RUN
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2( '* Run %d: EXCLUDED\n', run);
                continue
            end
            
            search = sprintf('Workflow_*_%s_%s-S1R%d_%s-S1_BRAIN_IIHC_1_COREG_BBR.txt', p.PAR.ID{par}, p.VTC.NAME, run, p.VMR.NAME);
            list = dir([fol search]);
            
            if length(list) > 1
                error2( 'Too many BBR files found for search: %s\n%s', search, sprintf('%s\n', list.name))
            elseif isempty(list)
                error2( 'No BBR files found for search: %s', search)
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
                    error2( 'BBR cost is too high (%g) for Participant %d (%s) Run %d. The FMR-VMR alignment must be improved or the par/run excluded.', p.BBR.bbr_cost_end(par, run), par, p.PAR.ID{par}, run)
                end
                
                fprintf2( '* Run %d: %g (%s)\n', run, p.BBR.bbr_cost_end(par, run), p.BBR.bbr_cost_end_assessment{par, run});
            end
            
        end
    end
end

function MotionChecks
    global p
    
    p.DIR.MTN = [p.DIR.OUT 'Motion_Plots' filesep];
    if ~exist(p.DIR.MTN, 'dir')
        mkdir(p.DIR.MTN);
    end
    
    p.MTN.SDMMatrix = cell(p.PAR.NUM, p.PAR.RUN);

    fprintf2( '\nMotion plots will not be generated.\nIt is up to you to determine if any pars/runs contain too much motion.\nIn the future, we should include criteria for how much motion is acceptable.\nPlots Directory: %s', p.DIR.MTN);

    for par = 1:p.PAR.NUM
        fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        for run = 1:p.PAR.RUN
            fprintf2( '* Run %d\n', run);
            
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2( '*   EXCLUDED\n');
                continue
            end
            
            search = sprintf('%s_%s-S1R%d_3DMC.sdm', p.PAR.ID{par}, p.VTC.NAME, run);
            list = dir([p.file_list(par).dir search]);
            if length(list) > 1
                error2( 'Too many files found for SDM searc: %s\n%s', search, sprintf('%s\n', list.name));
            elseif isempty(list)
                error2( 'No files found for SDM searc: %s', search);
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
                
                fprintf2( '*   Translation per volume mean: %gmm\n', mean(p.MTN.position_delta{par, run}));
                fprintf2( '*   Translation per volume max: %gmm\n', max(p.MTN.position_delta{par, run}));
                fprintf2( '*   Translation per volume std: %gmm\n', std(p.MTN.position_delta{par, run}));
                fprintf2( '*   Rotation per volume mean: %gdeg\n', mean(p.MTN.rotation_delta{par, run}));
                fprintf2( '*   Rotation per volume max: %gdeg\n', max(p.MTN.rotation_delta{par, run}));
                fprintf2( '*   Rotation per volume std: %gdeg\n', std(p.MTN.rotation_delta{par, run}));
            end
        end
        
        %figure
        if ~any(strcmp(fields(p), 'fig')) | ~ishandle(p.fig)
            p.fig = figure('Position',[0 0 ((p.PAR.RUN*500)+200) 1000]);
        end
        filepath_plot = sprintf('%sPAR%02d_%s.%s', p.DIR.MTN, par, p.PAR.ID{par}, p.IMG.TYPE);
        if exist(filepath_plot, 'file') & ~p.MTN.OVERWRITE
            fprintf2( '* Plot already exists and WILL NOT be overwritten\n');
        else
            if exist(filepath_plot, 'file')
                fprintf2( '* Plot already exists, but WILL be overwritten\n');
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
            saveas(p.fig, filepath_plot, p.IMG.TYPE);
            fprintf2( '* Plot: %s\n', filepath_plot);
        end
        
    end
    
    if any(strcmp(fields(p), 'fig'))
        close(p.fig);
    end
end

function LinkVTCtoPRT
    global p
    
    fprintf2( '\nLinking PRTs to non-smoothed VTCs...\n');
    
    for par = 1:p.PAR.NUM
        fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        for run = 1:p.PAR.RUN
            fprintf2( '* Run %d\n', run);
            
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2( '*   EXCLUDED\n');
                continue
            end
            
            fn_vtc = p.file_list(par).run(run).vtc_base;
            fn_prt = p.file_list(par).run(run).prt;
            
            if LinkPRT([p.file_list(par).dir fn_vtc], fn_prt)
                fprintf2( '*   set link to %s\n', fn_prt);
            else
                fprintf2( '*   already linked to %s\n', fn_prt);
            end
            
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Utility Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [did_link] = LinkPRT(fp_vtc, fn_prt)
    did_link = false;
    vtc = xff(fp_vtc);
    if isempty(vtc.NameOfLinkedPRT) | ~strcmp(vtc.NameOfLinkedPRT, fn_prt)
        vtc.NameOfLinkedPRT = fn_prt;
        vtc.save;
        did_link = true;
    end
    vtc.clear;
end

function [string] = ApplyNamingConvention(string, par, run)
    global p
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
    global p
    message = varargin{1};
    
    if nargin < 2
        args = '';
    else
        args = sprintf(', varargin{%d}', 2:nargin);
    end
    
    fprintf2( '\n\n\n');
    eval(sprintf('fprintf2(''ERROR: %s''%s);', message, args))
    eval(sprintf('error(''%s''%s);', message, args))
    
end

%this fprintf send to both command window and a log file
function fprintf2(varargin)
    global p
    message = varargin{1};
    
    if nargin < 2
        args = '';
    else
        args = sprintf(', varargin{%d}', 2:nargin);
    end
    
    eval(sprintf('fprintf(''%s''%s);', message, args))
    for fid = p.LOGFILES
        eval(sprintf('fprintf(fid, ''%s''%s);', message, args))
    end
end
