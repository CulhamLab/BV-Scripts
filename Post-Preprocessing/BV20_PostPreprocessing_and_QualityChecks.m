% All parameters are set in the loaded excel file (not in this script).
%
% Requirements:
% * NeuroElf toolbox installed (tested with neuroelf_v10_5153)
% * BV20 (or BVQX version 1.9 or later) COM server must be registered if performing THP/LTR or SS on VTC
% * Temporal High Pass Filter values must be in cycles (not herz)
% * Data must have been preprocessed with the BV20 workflow or have been renamed to match workflow output
% * Single session only
% * Data must not have individual run directories (session directory is okay, but only single session is supported)
% * Files must use BV file naming conventions (i.e., don't rename files in the BV folders)
%
function BV20_PostPreprocessing_and_QualityChecks(xls_filepath)
    %% Handle Errors
    try
	
	%% Disable a warning that occurs (without issue) in newer MATLAB
    warning('off', 'xff:BadTFFCont');
    
    %% Check requirements
    if ~exist('xff','file')
        error('NeuroElf does not appear to be installed.')
    end
        
    %% Get script constants (also initializes global p)
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

    %% 4. Link all VTCs to PRT
    LinkVTCtoPRT;
    
    %% 5. Linear Trend Removal + Temporal High Pass + Spatial Smoothing
    CheckAndFinishVTCPreprocessing;
    
    %% 6. Check TR and Volumes in final VTC
    CheckVTC;
    
    %% 7. Generate SDMs from PRTs (add motion from 3DMC SDMs as predictors of no interest)
    GenerateSDMs;

    %% 8. Generate MDM for each participant and for all participants
    GenerateMDMs;
    
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
    
    fprintf2( '\n\nData Directory: %s\nData File: %s\n', p.DIR.SAVE, fn);
    
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
        if exist('p', 'var') & any(strcmp(fields(p), 'bv')) & ~isempty(p.bv)
            p.bv.Exit;
            p.bv = [];
        end
        rethrow(err);
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Main Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ScriptConstants
    global p
    p = struct; %initialize global p

    p.XLS.FILETYPE = 'xls*';
    p.XLS.ROW_START = 2;
    p.XLS.COL_VALUE = 3;
    p.XLS.COL_ID = 5;
    
    p.BBR.STRANGE = 0.25;
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
    
    %convert relative paths to absolute
    dir_start = p.XLS.PATH(1:find(p.XLS.PATH==filesep,1,'last'));
    for f = 1:length(fs)
        eval(sprintf('val = p.DIR.%s;', fs{f}))
        if strcmp(val,'.') || strcmp(val,['.' filesep])
            eval(sprintf('p.DIR.%s = dir_start;', fs{f}))
        elseif length(val)>=2 && strcmp(val(1:2),['.' filesep])
            eval(sprintf('p.DIR.%s = [dir_start val];', fs{f}))
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

	%support for wildcard in p.VTC.NAME
	p.VTC.NAME_NOWILDCARD = strrep(p.VTC.NAME, '*', '');
	
    %print parameters
    fprintf2( 'PARAMETERS:\n')
    PrintParameters;
    
    %THP
    if isnan(p.VTC.THP_FMR)
        p.VTC.THP_FMR = 0;
    end
    if isnan(p.VTC.THP_VTC)
        p.VTC.THP_VTC = 0;
    end
    
    %temporal high pass filtering should not be applied on BOTH FMR and VTC
    if p.VTC.THP_FMR & p.VTC.THP_VTC
        %error2('Temporal high pass filtering should not be applied to both FMR and VTC! Check the values of VTC.THP_FMR and VTC.THP_VTC')
		fprintf2('WARNING: Temporal high pass filtering is enabled for both FMR and VTC. FMR with thp will be prioratized. If not found, thp will be performed on vtc.')
    end
    
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
    
    %PRT sets
    p.PRT.SETS = strrep(p.PRT.SETS,' ','');
    if ~isnan(p.PRT.SETS)
        p.PRT.SETS = strsplit(p.PRT.SETS, ',');
    end
    p.PRT.SETS_num = length(p.PRT.SETS);
    if p.PRT.SETS_num < 1
        p.PRT.SETS_num = 1;
    end
    p.PRT.NUM_POI = strrep(p.PRT.NUM_POI,' ','');
    if ~isnan(p.PRT.NUM_POI)
        if ischar(p.PRT.NUM_POI)
            try
                p.PRT.NUM_POI = cellfun(@str2num, strsplit(p.PRT.NUM_POI, ','));
            catch
                error2('Cannot parse PRT number of POI as numbers: %s\n', p.PRT.NUM_POI);
            end
        end
        if length(p.PRT.NUM_POI) ~= p.PRT.SETS_num
            error2('Length of PRT number of POI must match number of PRT sets!')
        end
        p.PRT.NUM_POI(p.PRT.NUM_POI < 1) = nan;
    else
        p.PRT.NUM_POI = nan(1, p.PRT.SETS_num);
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
    p.EXCLUDE.MATRIX = false(p.PAR.NUM, p.EXP.RUN);

    %set run exclusions - excluded subjects
    p.EXCLUDE.MATRIX(p.EXCLUDE.PAR, :) = true;

    %set run exclusions - excluded runs
    p.EXCLUDE.RUN_input = p.EXCLUDE.RUN;
    p.EXCLUDE.RUN = false(1, p.EXP.RUN);
    if ~isnan(p.EXCLUDE.RUN_input)
        if isnumeric(p.EXCLUDE.RUN_input)
            %single numeric input
            if p.EXCLUDE.RUN_input <= p.EXP.RUN
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
                if num <= p.EXP.RUN
                    p.EXCLUDE.RUN(num) = true;
                else
                    error2( 'Run exclusion list contains a number (%d) that exceeds the number of runs!', num)
                end
            end
        end
    end
    p.EXCLUDE.MATRIX(:, p.EXCLUDE.RUN) = true;
    fprintf2( '\nThere is/are %d globally excluded run(s):\n', sum(p.EXCLUDE.RUN))
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
                if any(vals<1) | (vals(1)>p.PAR.NUM) | (vals(2)>p.EXP.RUN)
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
            fprintf2( '%s = %s\n', in{2}, sprintf('%g ', in{1}));
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
        vmr_search = sprintf('%s_%s-S1_*BRAIN_IIHC*_MNI.vmr', p.PAR.ID{par}, p.VMR.NAME);
        list = dir([p.file_list(par).dir vmr_search]);
%         fprintf2( '* VMR search results: %s\n', sprintf('%s ', list.name));
        if length(list) > 2
            error2( 'Too many VMR found for search: %s\n%s', vmr_search, sprintf('%s\n', list.name))
        elseif length(list) == 2
            num_trf = cellfun(@length, strfind({list.name}, '_TRF'));
            ind_use = find(num_trf);
            if length(ind_use) ~= 1
                error2( '2 VMR were found but both have TRFs applied so it is inclear which to use. For search: %s\n%s\n\nTo resolve this issue, look at the BV preprocessing data tab and determine which file was used. Move the other file(s) to another directory (e.g., an obselete folder) or delete it/them.\n', vmr_search, sprintf('%s\n', list.name));
            else
                %select the TRF VMR
                p.file_list(par).vmr = list(ind_use).name;
                fprintf2( 'WARNING: Two VMR files were found, but one has TRF so that one will be selected under the assumption that the TRF was to solve the corregistration bug and the non-TRF is left-over from the first attempt.\n');
            end
        elseif ~isempty(list)
            %one result
            p.file_list(par).vmr = list.name;
        else
            %no result
            error2('No VMR found for search: %s', vmr_search)
        end
        fprintf2( '* VMR: %s\n', p.file_list(par).vmr);
        
        %look for all VTC and PRT
        for run = 1:p.EXP.RUN
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
            
            %found
            p.file_list(par).run(run).vtcs = filenames;
            p.file_list(par).run(run).num_vtcs = length(p.file_list(par).run(run).vtcs);
            fprintf2( '*   VTC(s):\n%s', sprintf('      %s\n', p.file_list(par).run(run).vtcs{:}))
            
            
            %PRT
            for prt_num = 1:p.PRT.SETS_num
                search = ApplyNamingConvention(p.PRT.NAMING, par, run, prt_num);
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
                    p.file_list(par).run(run).prt{prt_num} = list.name;
                end
                fprintf2( '*   PRT: %s\n', p.file_list(par).run(run).prt{prt_num});
                if do_copy || p.PRT.OVERWRITE
                    fprintf2( '*   Copying PRT to BV folder from: %s\n', p.DIR.PRT)
                    copyfile([p.DIR.PRT p.file_list(par).run(run).prt{prt_num}], [p.file_list(par).dir p.file_list(par).run(run).prt{prt_num}])
                end
            end
        end 
    end
end

function CheckBBR
    global p
    p.BBR.bbr_cost_end = nan(p.PAR.NUM, p.EXP.RUN);

    fprintf2( '\nBoundary-Based Registration (BBR) cost values will now be checked.\nLower values indicate better FMR-VMR alignment.\n')

    fol = [p.DIR.BV '_WorkflowReports_' filesep 'texts' filesep];
    if ~exist(fol, 'dir')
        fprintf2( 'WARNING: Skipping BBR checks because directory was not found: %s\n', fol)
        return
    end
    
    fprintf2( 'The cutoff values used are:\nSTRANGE < %g\nGREAT <= %g\nOKAY <= %g\nPOOR <= %g\nUNACCEPTABLE > %g\n', p.BBR.STRANGE, p.BBR.GREAT, p.BBR.OKAY, p.BBR.POOR, p.BBR.POOR);
    
    for par = 1:p.PAR.NUM
        fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        for run = 1:p.EXP.RUN
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2( '* Run %d: EXCLUDED\n', run);
                continue
            end
            
            search = sprintf('Workflow_*_%s_%s-S1R%d_%s-S1_BRAIN_IIHC_1_COREG_BBR.txt', p.PAR.ID{par}, p.VTC.NAME, run, p.VMR.NAME);
            list = dir([fol search]);
            
            if length(list) > 1
                error2( 'Too many BBR files found for search: %s\nIn Directory: %s\nResults:\n%s', search, fol, sprintf('%s\n', list.name))
            elseif isempty(list)
                error2( 'No BBR files found for search: %s', search)
            else
                text = fileread([fol list.name]);
                p.BBR.bbr_cost_end(par, run) = str2num(text(find(text==' ',1,'last')+1:end));
                
                if p.BBR.bbr_cost_end(par, run) <= p.BBR.STRANGE
                    p.BBR.bbr_cost_end_assessment{par, run} = 'STRANGE - could be exceptional or perhaps an issue occurred';
                elseif p.BBR.bbr_cost_end(par, run) <= p.BBR.GREAT
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
    
    p.MTN.SDMMatrix = cell(p.PAR.NUM, p.EXP.RUN);

    fprintf2( '\nMotion plots will now be generated.\nIt is up to you to determine if any pars/runs contain too much motion.\nIn the future, we should include criteria for how much motion is acceptable.\nPlots Directory: %s\n', p.DIR.MTN);

    for par = 1:p.PAR.NUM
        fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        for run = 1:p.EXP.RUN
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
                p.file_list(par).run(run).sdm_motion_filename = list.name;
                sdm = xff([p.file_list(par).dir p.file_list(par).run(run).sdm_motion_filename]);
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
                fprintf2( '*   Translation per volume max:  %gmm\n', max(p.MTN.position_delta{par, run}));
                fprintf2( '*   Translation per volume std:  %gmm\n', std(p.MTN.position_delta{par, run}));
                fprintf2( '*   Rotation per volume mean: %gdeg\n', mean(p.MTN.rotation_delta{par, run}));
                fprintf2( '*   Rotation per volume max:  %gdeg\n', max(p.MTN.rotation_delta{par, run}));
                fprintf2( '*   Rotation per volume std:  %gdeg\n', std(p.MTN.rotation_delta{par, run}));
            end
        end
        
        %figure
        if ~any(strcmp(fields(p), 'fig')) | ~ishandle(p.fig)
            p.fig = figure('Position',[0 0 ((p.EXP.RUN*500)+200) 1000]);
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
            for run = 1:p.EXP.RUN
                starts(run) = length(pos_all) + 1;
                if isempty(p.MTN.SDMMatrix{par, run})
                    pos_all = [pos_all; nan(max_run_length, 1)];
                    rot_all = [rot_all; nan(max_run_length, 1)];
                else
                    pos_all = [pos_all; p.MTN.position{par, run}];
                    rot_all = [rot_all; p.MTN.rotation{par, run}];
                end
            end
            clf
            hold on
            pl(1) = plot(pos_all,'g');
            pl(2) = plot(rot_all,'b');
            hold off
            xlabel('Volume')
            ylabel('mm or deg');
            
            m = max([pos_all; rot_all]);
            t = sprintf('Participant %d: %s', par, p.PAR.ID{par});
            if m > p.MTN.YAXIS
                a = [1 length(pos_all) 0 m];
                t = sprintf('%s (extended y-axis: %g)', t, m);
                fprintf2('WARNING: Motion plot y-axis exceeds limit. Will draw larger axis. (new max = %g)\n', m)
            else
                a = [1 length(pos_all) 0 p.MTN.YAXIS];
            end
            
            axis(a);
            hold on
            exclude_text = {'' ' (EXCLUDE)'};
            for run = 1:p.EXP.RUN
                plot([starts(run) starts(run)], a(3:4), 'r')
                text(starts(run), a(4)*0.95, sprintf('Run %d%s', run, exclude_text{1 + p.EXCLUDE.MATRIX(par,run)}), 'Color', 'r');
            end
            hold off
            legend(pl, {'Position','Rotation'}, 'Location', 'EastOutside')
            title(t);
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
    
    if ~p.VTC.LINK_PRT
        fprintf2( 'WARNING: Linking of PRT to VTCs is set to be skipped!\n')
		return
    end
    
    fprintf2( '\nLinking all VTCs to PRTs...\n');
    
    for par = 1:p.PAR.NUM
        fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        for run = 1:p.EXP.RUN
            fprintf2( '* Run %d\n', run);
            
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2( '*   EXCLUDED\n');
                continue
            end

            fn_prt = p.file_list(par).run(run).prt{1};
            fprintf2('*   Linking to: %s\n', fn_prt);
            
            for i = 1:p.file_list(par).run(run).num_vtcs
            
                fn_vtc = p.file_list(par).run(run).vtcs{i};
                fprintf2('*   VTC: %s\n', fn_vtc);
                
                if LinkPRT([p.file_list(par).dir fn_vtc], fn_prt)
                    fprintf2( '*     Set Link\n');
                else
                    fprintf2( '*     Already Linked\n');
                end
            
            end
            
        end
    end
end

function CheckAndFinishVTCPreprocessing
    global p
    p.bv = [];
    
    fprintf2( '\nChecking and finishing any FMR preprocessing (LTR, THP, and Spatial Smoothing)...\n');
    
    for par = 1:p.PAR.NUM
        fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        if ~isempty(p.bv)
            %open the vmr
            vmr = p.bv.OpenDocument([p.file_list(par).dir p.file_list(par).vmr]);
        end
        
        for run = 1:p.EXP.RUN
            fprintf2( '* Run %d\n', run);
            
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2( '*   EXCLUDED\n');
                continue
            end
    
            %looking for the best vtc to finish preprocessing (if needed) + dospatial smoothing on
            filenames = p.file_list(par).run(run).vtcs;
            
            %exclude spatially smoothed vtcs
            ind_smoothed = ~cellfun(@isempty, regexp(filenames, 'SS[-.0-9]*mm'));
            filenames(ind_smoothed) = [];
            
            %if VTC.THP_FMR then select those with correct FMR THP, else select those with no FMR THP
			skip_thp_vtc_check = false;
            if p.VTC.THP_FMR
                filenames = filenames(cellfun(@(x) ~isempty(strfind(x, sprintf('THPGLMF%dc', p.VTC.THP_FMR))), filenames));
				if ~isempty(filenames)
					%found a thp_fmr
					skip_thp_vtc_check = true;
				end
            else
                filenames = filenames(cellfun(@(x) isempty(strfind(x, 'THPGLMF')), filenames));
            end
            
            %if VTC.THP_VTC then discard those with other VTC THP values, else select those with no VTC THP
            if p.VTC.THP_VTC & ~skip_thp_vtc_check
                matches = regexp(filenames, 'THPFFT[0-9]*c', 'match');
                ind_bad_thp = cellfun(@(x) ~isempty(x) && ~strcmp(x, sprintf('THP%dc', p.VTC.THP_VTC)), matches);
                filenames(ind_bad_thp) = [];
            else
                filenames = filenames(cellfun(@(x) isempty(strfind(x, 'THPFFT')), filenames));
            end
            
            %at this point, all VTC are not spatially smoothed and either have no THP or have the desired THP
            
            %try to narrow down to single best option
            needs_thp = false;
            if skip_thp_vtc_check
                %all files already have correct THP
            elseif p.VTC.THP_VTC
                %if one option has VTC THP, select it - otherwise can apply THP
                ind = find(cellfun(@(x) ~isempty(strfind(x, sprintf('THP%dc', p.VTC.THP_VTC))), filenames));
                if length(ind) == 1
                    filenames = filenames(ind);
                else
                    needs_thp = true;
                end
            else
                %all files already have no THP
            end
            
            %should ideally have one file left
            if isempty(filenames)
                error2('Could not find any suitable VTC in list: \n%s', sprintf('%s\n', p.file_list(par).run(run).vtcs{:}))
            elseif length(filenames) > 1
                error2('Could not narrow search to a single best file in list: \n%s', sprintf('%s\n', filenames{:}))
            else
                %success
            end
            
            p.file_list(par).run(run).vtc_base = filenames{1};
            fprintf2('*   Selected VTC: %s\n', p.file_list(par).run(run).vtc_base);

            %determine if spatial smoothing needs to be performed
            fn_final = p.file_list(par).run(run).vtc_base(1 : find(p.file_list(par).run(run).vtc_base=='.',1,'last')-1);
            if needs_thp
                fn_final = sprintf('%s_LTR_THP%dc', fn_final, p.VTC.THP_VTC);
            end
            if ~isnan(p.VTC.SS) & (p.VTC.SS > 0)
                fn_final = sprintf('%s_SD3DVSS%.2fmm', fn_final, p.VTC.SS);
            end
            fn_final = [fn_final '.vtc'];
            p.file_list(par).run(run).vtc_final = fn_final;
            
            %needs spatial smoothing?
            if ~exist([p.file_list(par).dir p.file_list(par).run(run).vtc_final], 'file')
                needs_ss = true;
            else
                needs_ss = false;
            end
            
            %apply THP/LTR and/or SS
            if needs_thp | needs_ss
                %open BV connection if it's not already open
                if isempty(p.bv)
                    try
                        fprintf2('Opening connection to BV20...\n')
                        p.bv = actxserver('BrainVoyager.BrainVoyagerScriptAccess.1');
                    catch
					
                        fprintf2('WARNING: Could not connect to BV20. Either BV20 is not installed or the COM server is not registered.\n');
						
						try
							fprintf2('Opening connection to BVQX (2.2 or newer)...\n')
							p.bv = actxserver('BrainVoyagerQX.BrainVoyagerQXScriptAccess.1');
                        catch
                            fprintf2('WARNING: Could not connect to BVQX (2.2 or newer). Either BVQX (2.2 or newer) is not installed or the COM server is not registered.\n');
                            
                            try
                                fprintf2('Opening connection to BVQX (1.9 or 2.0)...\n')
                                p.bv = actxserver('BrainVoyagerQX.BrainVoyagerQXInterface.1')
                            catch
                                error2('Could not connect to any BV COM servers.');
                            end
						end
						
                    end
                    
                    %open the vmr
                    vmr = p.bv.OpenDocument([p.file_list(par).dir p.file_list(par).vmr]);
                end
                
                %link the vtc
                vmr.LinkVTC([p.file_list(par).dir p.file_list(par).run(run).vtc_base]);
                
                %thp/ltr
                if needs_thp
                    fprintf2('*     Applying Temporal High Pass Filter and Linear Trend Removal...\n')
                    vmr.TemporalHighPassFilter(p.VTC.THP_VTC, 'cycles');
                end
                
                %ss
                if needs_ss
                    fprintf2('*     Applying Spatial Smoothing...\n')
                    vmr.SpatialGaussianSmoothing(p.VTC.SS, 'mm');
                end
                
            end
			
			fprintf2('*     Complete\n');
        end
        
        if ~isempty(p.bv)
            %close files
            vmr.Close;
        end
    end
    
    if ~isempty(p.bv)
        fprintf2('Closing BV link...\n')
        p.bv.Exit;
        p.bv = [];
    end
end

function CheckVTC
    global p
	
	if ~p.VTC.CHECK
        fprintf2( 'WARNING: Checking of VTCs TR/volumes is set to be skipped!\n')
		return
    end
    
    fprintf2( '\nChecked the TR and number of volumes in final VTCs...\n');
    
    for par = 1:p.PAR.NUM
        fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        for run = 1:p.EXP.RUN
            fprintf2( '* Run %d\n', run);
            
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2( '*   EXCLUDED\n');
                continue
            end
            
            %load VTC
            fprintf2('*   VTC: %s\n', p.file_list(par).run(run).vtc_final);
            fp = [p.file_list(par).dir p.file_list(par).run(run).vtc_final];
            if ~exist(fp, 'file')
                error2('Expected VTC does not exist: %s\n', fp)
            end
            vtc = xff(fp);
            
            %check TR
            if vtc.TR ~= p.EXP.TR
                TR = vtc.TR;
                vtc.clear;
                error2('Unexpected TR = %d in VTC = %s\n', TR, p.file_list(par).run(run).vtc_final)
            end
            
            %check number of volumes
            p.file_list(par).run(run).num_vol = vtc.NrOfVolumes;
            vtc.clear;
            if p.file_list(par).run(run).num_vol ~= p.EXP.VOL
                if p.EXP.VOL_VARIES
                    fprintf2( '*     WARNING: unexpected number of volumes = %d\n', p.file_list(par).run(run).num_vol);
                else
                    error2('Unexpected number of volumes = %d in VTC = %s\n', p.file_list(par).run(run).num_vol, p.file_list(par).run(run).vtc_final);
                end
            else
                fprintf2( '*     No issues found.\n');
            end
            
        end
    end
    
end

function GenerateSDMs
    global p
    
    fprintf2( '\nCreate SDMs from PRTs...\n');
    
    %prt to sdm parameters
    param.rcond = []; %no exclude
    param.prtr = p.EXP.TR;
    
    for par = 1:p.PAR.NUM
        fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});
        
        if ~any(~p.EXCLUDE.MATRIX(par,:))
            fprintf2( '* EXCLUDED\n');
            continue
        end
        
        for run = 1:p.EXP.RUN
            fprintf2( '* Run %d\n', run);
            
            if p.EXCLUDE.MATRIX(par, run)
                fprintf2( '*   EXCLUDED\n');
                continue
            end
            
            %number of volumes in this run
            if p.VTC.CHECK
                param.nvol = p.file_list(par).run(run).num_vol;
            else
                fprintf2( 'WARNING: Checking of VTCs TR/volumes was skipped so expected number of volumes will be used instead of actual!\n')
                param.nvol = p.EXP.VOL;
            end
            
            %load motion sdm
            fprintf2('*   SDM: %s\n', p.file_list(par).run(run).sdm_motion_filename);
            sdm_motion = xff([p.file_list(par).dir p.file_list(par).run(run).sdm_motion_filename]);
            
            for set = 1:p.PRT.SETS_num
            
                %prt to sdm
                fprintf2('*   PRT: %s\n', p.file_list(par).run(run).prt{set});
                prt = xff([p.file_list(par).dir p.file_list(par).run(run).prt{set}]);
                fprintf2('*     Creating SDM...\n');
                sdm = prt.CreateSDM(param);

                %combine
                fprintf2('*     Copying motion...\n');
                sdm.PredictorColors = [sdm.PredictorColors(1:end-1,:); sdm_motion.PredictorColors; sdm.PredictorColors(end,:)];
                sdm.PredictorNames = [sdm.PredictorNames(1:end-1) sdm_motion.PredictorNames sdm.PredictorNames(end)];
                sdm.SDMMatrix = [sdm.SDMMatrix(:,1:end-1) sdm_motion.SDMMatrix(:,:) sdm.SDMMatrix(:,end)];
                sdm.NrOfPredictors = size(sdm.PredictorColors,1);
                
                %pred of interest
                if ~isnan(p.PRT.NUM_POI)
                    sdm.FirstConfoundPredictor = p.PRT.NUM_POI(set) + 1;
                else
                    %leave default (all in PRT are POI)
                end
                sdm.RTCMatrix = sdm.RTCMatrix(:,1:(sdm.FirstConfoundPredictor-1));
                
                %save
                if ~iscell(p.PRT.SETS)
                    fn_out = sprintf('%s_%s-S1R%d_PRT-and-3DMC.sdm', p.PAR.ID{par}, p.VTC.NAME_NOWILDCARD, run);
                else
                    fn_out = sprintf('%s_%s-S1R%d_PRT-and-3DMC_%s.sdm', p.PAR.ID{par}, p.VTC.NAME_NOWILDCARD, run, p.PRT.SETS{set});
                end
                
                p.file_list(par).run(run).sdm{set} = fn_out;
                fprintf2('*   New SDM: %s\n', p.file_list(par).run(run).sdm{set});
                sdm.SaveAs([p.file_list(par).dir p.file_list(par).run(run).sdm{set}]);

                %clear memory
                prt.clear;
                sdm.clear;
            end
            
            %clear memory
            sdm_motion.clear;
        end
    end
    
end

function GenerateMDMs
        global p
    
    fprintf2( '\nCreate MDMs...\n');
    
    suffix = '';
    if isnan(p.VTC.SS) | (p.VTC.SS <= 0)
        suffix = '_NonSmoothed';
        fprintf2('WARNING: Non-Smoothed VTC will be added to MDMs!\n');
    end
    
    for set = 1:p.PRT.SETS_num
    
        %start all-subs mdm
        mdm_all = xff('mdm');
        mdm_all.TypeOfFunctionalData = 'VTC';
        mdm_all.PSCTransformation = 1;
        mdm_all.zTransformation = 0;

        for par = 1:p.PAR.NUM
            fprintf2( 'Participant %d: %s\n', par, p.PAR.ID{par});

            if ~any(~p.EXCLUDE.MATRIX(par,:))
                fprintf2( '* EXCLUDED\n');
                continue
            end

            %start mdm
            mdm = xff('mdm');
            mdm.TypeOfFunctionalData = 'VTC';
            mdm.RFX_GLM = 0;
            mdm.PSCTransformation = 1;
            mdm.zTransformation = 0;
            mdm.SeparatePredictors = 0;

            for run = 1:p.EXP.RUN
                fprintf2( '* Run %d\n', run);

                if p.EXCLUDE.MATRIX(par, run)
                    fprintf2( '*   EXCLUDED\n');
                    continue
                end

                fprintf2( '*   Adding...\n');

                mdm.XTC_RTC(end+1,:) = {p.file_list(par).run(run).vtc_final p.file_list(par).run(run).sdm{set}};
                mdm.NrOfStudies = mdm.NrOfStudies + 1;

				if p.MDM.PATH_ABS
					fol = p.file_list(par).dir;
				else
					fol = strrep(p.file_list(par).dir, p.DIR.BV, filesep);
				end
                mdm_all.XTC_RTC(end+1,:) = {[fol p.file_list(par).run(run).vtc_final] [fol p.file_list(par).run(run).sdm{set}]};
                mdm_all.NrOfStudies = mdm.NrOfStudies + 1;

            end

            if ~iscell(p.PRT.SETS)
                p.file_list(par).mdm{set} = sprintf('%s_%s%s.mdm', p.PAR.ID{par}, p.VTC.NAME_NOWILDCARD, suffix);
            else
                p.file_list(par).mdm{set} = sprintf('%s_%s_%s%s.mdm', p.PAR.ID{par}, p.VTC.NAME_NOWILDCARD, p.PRT.SETS{set}, suffix);
            end
            fprintf2('* MDM: %s\n', p.file_list(par).mdm{set});
            mdm.SaveAs([p.file_list(par).dir p.file_list(par).mdm{set}]);
            mdm.clear;
        end

        if ~iscell(p.PRT.SETS)
            p.mdm_all{set} = sprintf('Multi-Participant_%s%s.mdm', p.VTC.NAME_NOWILDCARD, suffix);
        else
            p.mdm_all{set} = sprintf('Multi-Participant_%s_%s%s.mdm', p.VTC.NAME_NOWILDCARD, p.PRT.SETS{set}, suffix);
        end
        fprintf2('Multi-Participant MDM: %s\n', p.mdm_all{set});
        mdm_all.SaveAs([p.DIR.BV p.mdm_all{set}]);
        mdm_all.clear;
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

function [string] = ApplyNamingConvention(string, par, run, set)
    global p
    string = strrep(string, '[PID]', p.PAR.ID{par});
    
    if iscell(p.PRT.SETS) | ~isnan(p.PRT.SETS)
        string = strrep(string, '[PRED_SET]', p.PRT.SETS{set});
    end
    
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
