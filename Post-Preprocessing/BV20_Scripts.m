%Performs the following:
%1 Reads parameters from bv20_script_params.xlsx
%2 Search for existing files
%3 Links PRTs to VTCs
%4 Applies Linear Trend Removal (LTR) + Temporal High Pass (THP) in one
%  step and then Spatial Smoothing in a second step (generates VTCs)
%5 Generates SDMs from PRTs
%6 Merges Generated SDMs with 3DMC SDMs
%7 Generates MDM for each participant and for all participants using SDM
%  with merged 3DMC

function BV20_Scripts

%% parameters
xls_filepath = 'bv20_script_params.xlsx';

%% 1. Parse params from xls
fprintf('######### Step 1: Parsing information from excel file #########\n')

%check
if ~exist(xls_filepath,'file')
    error('Excel file cannot be found!')
end

%read in
[~,~,xls] = xlsread(xls_filepath);

%folder
p.FOLDER_MAIN = xls{2,2};
if p.FOLDER_MAIN(end)~=filesep, p.FOLDER_MAIN(end+1)=filesep; end

%names of run types
p.TYPE_NAMES.ANAT = xls{3,2};
p.TYPE_NAMES.FUNC = xls{4,2};

%one-offs
p.NUMBER_RUNS = xls{5,2};
p.TR_MSEC = xls{6,2};
p.THP_CYCLES = xls{7,2};
p.SPATIAL_SMOOTH_MM = xls{8,2};
p.PRT_FORMAT = xls{9,2};
p.OVERWRITE_VTC = xls{10,2};
p.OVERWRITE_SDM = xls{11,2};

%par info
number_pars = 0;
for row = 14:size(xls,1)
    number_pars = number_pars + 1;
    p.PAR(number_pars).NAME = xls{row,1};
    p.PAR(number_pars).NUMBER_VOLUMES = xls{row,2};
    p.PAR(number_pars).FOLDER = [p.FOLDER_MAIN p.PAR(number_pars).NAME filesep];
end
p.NUMBER_PARS = number_pars;
fprintf('Success\n')

%% 2. Search for existing files
fprintf('\n######### Step 2: searching for existing files #########\n')
for par = 1:p.NUMBER_PARS
    
    fprintf('\nParticiapnt %d (%s):\n',par, p.PAR(par).NAME)
    
    %vmr
    fprintf('-Searching for Anatomical:\n')
    criteria = sprintf('%s_%s-S*_BRAIN_IIHC_MNI.vmr',p.PAR(par).NAME, p.TYPE_NAMES.ANAT);
    p.PAR(par).ANAT_FILENAME = do_search(p.PAR(par).FOLDER, criteria);
    
    for run = 1:p.NUMBER_RUNS
        fprintf('Particiapnt %d (%s), Run %d:\n',par, p.PAR(par).NAME, run)
        
        %prt
        fprintf('-Searching for PRT:\n')
        eval(['criteria = ' p.PRT_FORMAT ';'])
        if isempty(strfind(criteria,'.prt'))
            criteria = [criteria '.prt'];
        end
        p.PAR(par).RUN(run).PRT_FILENAME = do_search(p.PAR(par).FOLDER, criteria);
        
        %vtc raw
        fprintf('-Searching for raw VTC:\n')
        criteria = sprintf('%s_%s-S*R%d_3DMCTS_MNI.vtc', p.PAR(par).NAME, p.TYPE_NAMES.FUNC, run);
        p.PAR(par).RUN(run).VTC_RAW_FILENAME = do_search(p.PAR(par).FOLDER, criteria);
        
        %vtc final
        fprintf('-Searching for final VTC:\n')
        criteria = sprintf('%s_%s-S*R%d_3DMCTS_MNI', p.PAR(par).NAME, p.TYPE_NAMES.FUNC, run);
        if ~isempty(p.THP_CYCLES)
            criteria = sprintf('%s_LTR_THP%dc',criteria,p.THP_CYCLES);
        end
        if ~isempty(p.SPATIAL_SMOOTH_MM)
            criteria = sprintf('%s_SD3DVSS%.2fmm',criteria,p.SPATIAL_SMOOTH_MM);
        end
        criteria = [criteria '.vtc'];
        p.PAR(par).RUN(run).VTC_FINAL_FILENAME = do_search(p.PAR(par).FOLDER, criteria);
        
    end
end

%% 3. Link PRT to VTC

% % % fprintf('\n######### Step 3: Link PRT to VTC #########\n')
% % % 
% % % for par = 1:p.NUMBER_PARS
% % %     for run = 1:p.NUMBER_RUNS
% % %         fprintf('Particiapnt %d (%s), Run %d:\n',par, p.PAR(par).NAME, run)
% % %         if ~isempty(p.PAR(par).RUN(run).PRT_FILENAME)
% % %             fn_to_link = p.PAR(par).RUN(run).PRT_FILENAME;
% % %             if ~isempty(p.PAR(par).RUN(run).VTC_RAW_FILENAME)
% % %                 fn_to_load = p.PAR(par).RUN(run).VTC_RAW_FILENAME;
% % %                 vtc = xff([p.PAR(par).FOLDER fn_to_load]);
% % %                 fprintf('-VTC loaded: %s\n', fn_to_load)
% % %                 vtc.NrOfLinkedPRTs = 1;
% % %                 vtc.NrOfCurrentPRT = 1;
% % %                 vtc.NameOfLinkedPRT = fn_to_link;
% % %                 vtc.Save;
% % %                 vtc.clear;
% % %                 fprintf('-PRT linked: %s\n', fn_to_link)
% % %             else
% % %                 warning('-No VTC found')
% % %             end
% % %         else
% % %             warning('-No PRT found')
% % %         end
% % %     end
% % % end


%% 4. LTR/THP and SS

fprintf('\n######### Step 4: Apply LTR/THP and SS to VTC #########\n')

%are any final vtc missing?
needs_to_run = false;
for par = 1:p.NUMBER_PARS
    if any(cellfun(@isempty, {p.PAR(par).RUN.VTC_FINAL_FILENAME}))
        needs_to_run = true;
    end
end
if ~needs_to_run && ~p.OVERWRITE_VTC
    disp('Nothing new to run.')
else
    try
        bv = actxserver('BrainVoyager.BrainVoyagerScriptAccess.1');
        bv_works = true;
    catch
        bv_works = false;
    end

    if bv_works
        for par = 1:p.NUMBER_PARS
            needs_to_run = cellfun(@isempty, {p.PAR(par).RUN.VTC_FINAL_FILENAME});
            if any(needs_to_run) || p.OVERWRITE_VTC
                fprintf('Particiapnt %d (%s):\n',par, p.PAR(par).NAME)
                
                fp = p.PAR(par).ANAT_FILENAME;
                fprintf('-Opening VMR: %s\n', fp);
                vmr = bv.OpenDocument([p.PAR(par).FOLDER fp]);
                
                for run = 1:p.NUMBER_RUNS
                   if  needs_to_run(run) || p.OVERWRITE_VTC
                       fprintf('Particiapnt %d (%s), Run %d:\n',par, p.PAR(par).NAME, run)
                       
                       fp = p.PAR(par).RUN(run).
                       
                       
                       fprintf('-Searching for final VTC:\n')
                       criteria = sprintf('%s_%s-S*R%d_3DMCTS_MNI', p.PAR(par).NAME, p.TYPE_NAMES.FUNC, run);
                       if ~isempty(p.THP_CYCLES)
                           criteria = sprintf('%s_LTR_THP%dc',criteria,p.THP_CYCLES);
                       end
                       if ~isempty(p.SPATIAL_SMOOTH_MM)
                           criteria = sprintf('%s_SD3DVSS%.2fmm',criteria,p.SPATIAL_SMOOTH_MM);
                       end
                       criteria = [criteria '.vtc'];
                       p.PAR(par).RUN(run).VTC_FINAL_FILENAME = do_search(p.PAR(par).FOLDER, criteria);
                   end
                end
            end
        end
        bv.Exit;
    else
        warning('BV actxserver could not be established. Skipping step 4!')
    end
end


end

function [result] = do_search(folder, criteria)
    fprintf('--Criteria: %s\n',criteria)
    list = dir([folder criteria]);
    if length(list)==1
        result = list(1).name;
        fprintf('--Found: %s\n',result)
    else
        result = [];
        warning('--NOT FOUND')
    end
end