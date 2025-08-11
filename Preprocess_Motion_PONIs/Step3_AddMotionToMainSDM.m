% function Step3_AddMotionToMainSDM

%% Parameters
MAX_SUB = 24;
MAX_SES = 1;
MAX_RUN = 10;

INDEX_FIRST_CONFOUND = 6; % set NaN to skip overwrite

DIR_MAIN = '..\Other BV Files\SDMs\';
FORMAT_MAIN = 'sub-[SUB]_ses-[SES]_task-3DReach_run-[RUN].sdm';

DIR_MOTION = '..\Other BV Files\SDMs\3DMC\';
FORMAT_MOTION = 'sub-[SUB]_ses-[SES]_task-3DReach_run-[RUN]_bold_SCCTBL_3DMC_THPGLMF3c_ZSCORE.sdm';

DIR_OUT = '..\RSA Files\BV Files\';
SUFFIX_OUT = '_AddTHPZMotion';


%% Make output folder
if DIR_OUT(end)~=filesep
    DIR_OUT(end+1) = filesep;
end
if ~exist(DIR_OUT, 'dir')
    mkdir(DIR_OUT)
end


%% Shortcut function
get_expected_filename = @(format,sub,ses,run) strrep(strrep(strrep(format,'[SUB]',sprintf('%02d',sub)),'[SES]',sprintf('%02d',ses)),'[RUN]',sprintf('%02d',run));


%% Run
for sub = 1:MAX_SUB
    for ses = 1:MAX_SES
        for run = 1:MAX_RUN
            % fprintf("Processing sub-%02d ses-%02d run-%02d...\n", sub, ses, run);

            % generate expected filenames
            fn_main = get_expected_filename(FORMAT_MAIN, sub, ses, run);
            fn_motion = get_expected_filename(FORMAT_MOTION, sub, ses, run);

            % find inputs
            file_main = dir(fullfile(DIR_MAIN, '**', fn_main));
            if length(file_main)~=1
                warning('Expected 1 result for [%s] but found %d. This run will be skipped!', fn_main, length(file_main))
                continue
            else
                fp_main = [file_main.folder filesep file_main.name];
            end
            file_motion = dir(fullfile(DIR_MOTION, '**', fn_motion));
            if length(file_motion)~=1
                warning('Expected 1 result for [%s] but found %d. This run will be skipped!', fn_motion, length(file_motion))
                continue
            else
                fp_motion = [file_motion.folder filesep file_motion.name];
            end

            % load inputs
            sdm_main = xff(fp_main);
            sdm_motion = xff(fp_motion);

            % main should include constant and motion should not
            if ~sdm_main.IncludesConstant || sdm_motion.IncludesConstant
                error('This script requires the main SDM to already include a constant and the motion SDM to not include a constant (could be supported with minor script changes')
            end

            % overwrite first confound index
            if ~isnan(INDEX_FIRST_CONFOUND)
                sdm_main.FirstConfoundPredictor = INDEX_FIRST_CONFOUND;
                sdm_main.RTCMatrix(:,sdm_main.FirstConfoundPredictor:end) = [];
            end

            % move the constant to the new end
            ind_constant_before = sdm_main.NrOfPredictors;
            ind_constant_after = ind_constant_before + sdm_motion.NrOfPredictors;
            sdm_main.PredictorColors(ind_constant_after,:) = sdm_main.PredictorColors(ind_constant_before,:);
            sdm_main.PredictorNames{ind_constant_after} = sdm_main.PredictorNames{ind_constant_before};
            sdm_main.SDMMatrix(:,ind_constant_after) = sdm_main.SDMMatrix(:,ind_constant_before);
            sdm_main.NrOfPredictors = ind_constant_after;

            % copy over motion PONIs
            inds = ind_constant_before : (ind_constant_before + sdm_motion.NrOfPredictors - 1);
            sdm_main.PredictorColors(inds,:) = sdm_motion.PredictorColors;
            sdm_main.PredictorNames(inds) = sdm_motion.PredictorNames;
            sdm_main.SDMMatrix(:,inds) = sdm_motion.SDMMatrix;

            % save
            fp_out = [DIR_OUT strrep(fn_main,'.sdm',[SUFFIX_OUT '.sdm'])];
            if strcmp(fp_out, fp_main)
                error('Output would overwrite input')
            end
            sdm_main.SaveAs(fp_out);
        end
    end
end


%% Done
disp Done!