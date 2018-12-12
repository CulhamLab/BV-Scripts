% Your parameter file must be named "ALL_STEP0_PARAMETERS.m"





%Step0: setting parameters
%
%The first step to using this pipeline is to specify the number of
%particpants, runs, and conditions as well as data and output filepaths.
%
%Note that this pipeline requires NeuroElf v1.0 or newer (successor to BVQX)
%see http://neuroelf.net/
%
%The input VTCs must be in TAL space
%
%
%
%Note about input (VTC and SDM) filenames:
%
%a) Input must have filenames with the format "SUB##_RUN##_*"
%   For example:
%    VTC: SUB04_RUN07_someExtraDetails.vtc
%    SDM: SUB04_RUN07_otherExtraDetails.sdm
%
%b) Subjects must be numbered from 1 to the number of subjects (i.e., no
%   missing values)
%   For example:
%    If you have collected 6 subjects but #2 and #5 are excluded, you would
%    have to rename remaining subjects [1 3 4 6] to be [1 2 3 4] and then
%    enter num_Participants = 4;
%
%c) Missing/excluded runs ARE allowed.
%
%d) All SDMs and VTCs must be in a single folder. This folder is identified
%   by "filepath_BV" below.

function [p] = ALL_STEP0_PARAMETERS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETERS START HERE %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% numbers
%2 subs, 12runs, 4conditions, 2models required just 9minutes to run start to finish on my machine
NUMBER_OF_PARTICIPANTS = 10;
NUMBER_OF_RUNS = 8;
NUMBER_OF_CONDITIONS = 54;

%% file locations (subfolders are automatically created)
%If multiple filepaths are entered, the first valid path will be used. This
%is intended to allow shared scripts to be used on different machines as
%each machine will have its own unique path to the data and output folders.
FILEPATH_TO_VTC_AND_SDM = {'C:\Users\kstubbs4\Documents\BrainVoyagerData\Guy_Aug2018'}; %this is the folder where your VTCs and SDMs are located
FILEPATH_TO_SAVE_LOCATION = {'D:\Users\kstubbs4\Guy\RSA\Temp'}; %this where you would like the output files to be saved - several subfolders will be generated within this folder
SUBFOLDER_SHARED_DATA = 'Both';
SUBFOLDER_SEARCHLIGHT_DATA = 'Searchlight';
SUBFOLDER_ROI_DATA = 'ROI';

%If runs number does not correspond with chronological order, enter actual run order here [#participant x #runs]
%Otherwise, set to empty or nan
%Example:
%RUN_ORDER = [1 2 3;
%             3 2 1]; %P1 run order was 1,2,3 and P2 order was 3,2,1
RUN_ORDER = nan;

%Path to VOI file used in ROI steps. If left as NaN, "ROI_STEP6_extractROI"
%will prompt you to choose a VOI file with a file selector.
%To merge multiple VOI files, provide a cell array of strings containing the names (or pahts)
%e.g., VOI_FILE = {'.\VOI\file1.voi' '.\VOI\file2.voi'};
VOI_FILE = nan;

%% file list (for vtc/sdm)
FILELIST_FILENAME = 'filelist.xls';
FILELIST_PAR_ID = arrayfun(@(x) sprintf('P%d',x), 1 + (1:NUMBER_OF_PARTICIPANTS), 'UniformOutput', false); %must be strings
FILELIST_RUN_ID = arrayfun(@(x) sprintf('Func-S1R%d',x), 1:NUMBER_OF_RUNS, 'UniformOutput', false); %must be strings
FILELIST_FORMAT_VTC = '[PAR]_[RUN]_3DMCTS_LTR_THPGLMF2c_MNI.vtc'; %replaces [PAR] from PAR_ID and [RUN] from RUN_ID
FILELIST_FORMAT_SDM = '[PAR]_[RUN]_PRT-and-3DMC_Video.sdm'; %replaces [PAR] from PAR_ID and [RUN] from RUN_ID
FILELIST_SUBFOLDERS = true; %set true if vtc/sdm files are in subfolders named the same as PAR_ID, else set false if all files are in a single directory

%% Searchlight - Memory Available
%
%IMPORTANT: if you change this value then you must rerun the searchlight
%from the start (SEARCHLIGHT_STEP06_createRSMs)
%
%Searchlight requires quite a bit of memory especially for creation of the
%noise ceiling maps. To keep RAM requirements reasonable, searchlight data
%is divided into multiple files.
%
%Both the number of participants and the number of predictors affects this:
%When calculating the noise ceiling of a sphere, the sphere's RSM from each
%participant must be held in memory. The size of these RSM matrices is
%proportional to the number of predictors.
%
%The amount of memory (in gigabytes) needed to hold a file in memory is approximately:
%number_voxels * ((10 + (number_voxels/5555)) + (8 * (number_predictors^2))) / (1024^3)
%
%NOTE:
%The size of the mat file on the harddrive is less than the amount of RAM
%needed to hold the contents in memory.
%
%NOTE2:
%If you run out of RAM, the script probably won't crash but will instead
%slow down so much that it would take years to finish (because it switches
%to using harddrive as memory instead). In this event, you would need to
%notice that the system is out of memory and close the script manually
%(CTRL+C in the command window).
%
%NOTE3:
%Setting this value too low will prevent out-of-memory issues, but will
%also cause several scripts to take much longer. This is because loading
%files has some overhead. There is a sweet spot where the files are small
%enough to work with but not so small that they become too many.
%
%NOTE4:
%Even if running on a sever with considerable memory, will may still need to
%do this calculation. If a large value were entered so that data was not
%divided into separate files, then the memory needed can be excessive. For
%example, 20 subjects with 50 predictors in 2mm data would require >187 GB
%of RAM!
%
%Step-by-step Example:
%
%
%1. Close all programs except MATLAB.
%
%2. Check how much memory is available in Task Manager. I am at 7.3GB/16GB
%so I have 8.7GB to work with, but I will round down to 8GB to be safe.
%
%3. Suppose the project has 10 subjects now, but might have as many as 25
%at completion. I will use 25 subjects in the calculations.
%
%4. With 8GB available and as many as 25 subjects, each file must require
%less than 0.32 GB of RAM.
%
%8 GB / 25 subjects = 0.32 GB of RAM per file max
%
%5. Calculate the number of voxels to store in each file by solving the
%quadratic form of the equation above:
%0 = (1/5555)voxels^2 + (10 + (8 * number_predictors^2))voxels - (memory_per_file_in_GB * 1024^3)
%
%number_predictors = 50;
%memory_per_file_in_GB = 0.32;
%voxels_per_file = max(roots([(1/5555) (10 + (8 * number_predictors^2)) (-memory_per_file_in_GB * 1024^3)]));
%
%6. This tells me that I should be able to store 17,169 voxels in each data
%file without issue, but I might choose to store just 15,000 instead.
%
SEARCHLIGHT_NUMBER_VOXELS_PER_FILE = 10000; %%TODO - NOT YET IMPLEMENTED

%% options

%searchlight radius (not including center voxel) in function voxels
%For example, radius 2 equates to diameters of 5 function voxels.
SEARCHLIGHT_RADIUS = 3;

%if your VMP output is flipped Left/Right, set this to true
%most of the time this should be false
USE_OLD_LEFT_RIGHT_CONVENTION = false; 

%if you are removing (setting as nan) certain conditions from certain runs,
%set this to true. To remove remove these conditions, you will need to run
%"BOTH_step1_PREPARE3_OPTIONAL_removeFlaggedErrors" after
%"BOTH_step1_PREPARE2_fillMissingRuns". You will also need to create a
%matlab save/data file called "toRemove" containing a 2D (3-by-N) matrixs
%called "toRemoveMatrix". The first column is the subject number, the
%second column is the run number, and the third column is the condition
%number. Conditions are numbered by their order in the SDMs. 
REMOVE_CERTAIN_CONDITIONS = false;

%Option to append new models and not recalculate pre-existing ones (turn
%this OFF if you make any changes prior to searchlight model correlation)
SEACHLIGHT_MODEL_APPEND = true;

%If there are subjects who lack a condition, you will have to use a slower
%method of RSM calculation. In this method, each comparison is made
%individually. Consequently, some parts of the RSM will be available while
%others (those comparing a missing condition) will be NaN. Model
%correlations will use as much of the RSM is available. THIS MEANS THAT
%SOME SUBJECTS MAY USE LESS OF THE RSM THAN OTHERS, WHICH IS NOT
%RECOMMENDED. THIS SHOULD ONLY BE USED FOR PILOT TESTING!
USE_SLOW_RSM_CALCULATION = false; %not recommended (see above)

%If your bounding box is correct and the VMP is still scrambled (you'll see
%lines - everything will be displaced in 1D array positions), set this to
%true and rerun the VMP scripts. Sometimes, the BBOX extends out 1
%functional voxel beyond the data, which would be okay except that the BV
%functions for saving VMPs ignore these extra zeros causing everything to
%be displaced. The fix will circumvent this by artificially increasing the
%BBOX range during VMP saving thereby causing the correct BBOX to be used.
LAST_DITCH_EFFORT_VMP_FIX = false;

%r-map VMP default lower threshold (absolute)
VMP_RMAP_LOWER_THRESHOLD = 0.05;

%r-map VMP show positives (1), negatives (2), or both (3)
VMP_RMAP_SHOW_POS_NEG = 3;

%TTest t-map/p-map VMP default upper threshold (in units of p)
%this value is converted to t for t-map and to 1-minus-p for 1-minus-p-map
VMP_TTEST_UPPER_P_THRESHOLD = 0.05;

%threshold for TTest t-map (in t)
VMP_TTEST_LOWER_T_THRESHOLD = 2;

%TTest t-map/p-map VMP show positives (1), negatives (2), or both (3)
VMP_TTEST_SHOW_POS_NEG = 3;

%The "correlateModels" step uses a parallel feature of Matlab to speed up
%the process. New versions have renamed certain parameters of this feature
%so you may encounter an error. If you encounter this error, set this
%false. If you do not have the toolbox, this setting will be ignored.
USE_PARALLEL_POOLS = true;

%Option to use split or default to nonsplit data in searchlight RSM
SEARCHLIGHT_USE_SPLIT  = true;

%mask for vmp
p.MSK_FILE = nan;

%% Fisher Transformation Options
%Apply Fisher to the subject-average RSM prior to condition-condition
%MDS calculation (not VOI-VOI MDS)
DO_FISHER_CONDITION_MDS = true;

%% Figures

%the range of values contained in the colour map
RSM_COLOUR_RANGE_COND = [-1 +1];
RSM_COLOUR_RANGE_ROI = [-1 +1];

%colourmap used in RSM
RSM_COLOURMAP = jet(64);

%% bounding box for entire brain (affects how data is stored)
%-You can use "aux_readVTC_displayBoundingBox.m" to read the box from a VTC
% if you are unsure.
%-Often, this will not need to be changed

%psych9223 (same for Rita)
BBOX.XStart = 57;
BBOX.XEnd = 237;
BBOX.YStart = 49;
BBOX.YEnd = 181;
BBOX.ZStart = 53;
BBOX.ZEnd = 203;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETERS END HERE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% List of param variables
%do not add to or change this section
%all variables above this point will be saved into "p"
paramList = who;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CONDITION NAMES START HERE %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Condition names
%you may create these however you like, but in the end you need a cell
%array called "CONDITIONS" which has one cell per condition, which contain
%the condition names.

CONDITIONS.PREDICTOR_NAMES = {'105_PULL_ARM'
                                '108_PUSH_ARM'
                                '86_CATCH_ARM'
                                '107_PULL_MOUTH'
                                '87_CATCH_HEAD'
                                '106_PULL_LEG'
                                '109_PUSH_LEG'
                                '88_CATCH_LEG'
                                '110_PUSH_WB'
                                '49_PULL_WB'
                                '89_CATCH_WB'
                                '06_CLIMB_ARM'
                                '101_LADDER_ARM'
                                '115_WALL_ARM'
                                '102_LADDER_HEAD'
                                '09_CLIMB_LEG'
                                '103_LADDER_LEG'
                                '116_WALL_LEG'
                                '104_LADDER_WB'
                                '117_WALL_WB'
                                '118_CLIMB_WB'
                                '19_BLOCKSTICK_ARM'
                                '72_TREE_ARM'
                                '90_DEFBALL_ARM'
                                '114_TREE_HEAD'
                                '20_BLOCKSTICK_HEAD'
                                '91_DEFBALL_HEAD'
                                '21_BLOCKSTICK_LEG'
                                '74_TREE_LEG'
                                '92_DEFBALL_LEG'
                                '22_BLOCKSTICK_WB'
                                '77_TREE_WB'
                                '93_DEFBALL_WB'
                                '25_DRINK_ARM'
                                '34_FORK_ARM'
                                '96_EAT_ARM'
                                '94_DRINK_MOUTH'
                                '97_EAT_MOUTH'
                                '99_FORK_MOUTH'
                                '100_FORK_WB'
                                '95_DRINK_WB'
                                '98_EAT_WB'
                                '111_RUN_ARM'
                                '60_STAIRS_ARM'
                                '79_WALK_ARM'
                                '112_RUN_HEAD'
                                '62_STAIRS_HEAD'
                                '81_WALK_HEAD'
                                '113_RUN_LEG'
                                '64_STAIRS_LEG'
                                '82_WALK_LEG'
                                '58_RUN_WB'
                                '66_STAIRS_WB'
                                '84_WALK_WB'
                                };
CONDITIONS.DISPLAY_NAMES = CONDITIONS.PREDICTOR_NAMES;

% DEFAULT EXAMPLE
% CONDITIONS.PREDICTOR_NAMES = cellfun(@num2str,num2cell(1:NUMBER_OF_CONDITIONS),'UniformOutput',false);
% CONDITIONS.DISPLAY_NAMES = CONDITIONS.PREDICTOR_NAMES;

% %NON-DEFAULT EXAMPLE
% taskNames = {'View' 'P2' 'P5' 'WH'};
% sizeNames = {'Small' 'Med' 'Large'};
% shapeNames = {'Square' 'Circle'};
% isoNames = {'Flat' 'Iso' 'Long'};
% CONDITIONS = cell(0);
% for task = 1:4
%     for osize = 3:-1:1
%         for shape = 1:2
%             for iso = 3:-1:1
%                 CONDITIONS{end+1} = sprintf('%s_%s_%s_%s',taskNames{task},sizeNames{osize},shapeNames{shape},isoNames{iso});
%             end
%         end
%     end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% CONDITION NAMES END HERE %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% models
%Create matrices of size #Conditions-by-#Conditions. Set cell to 0 for
%low/negative correlation, 1 for high/positive correlation, and nan to
%exclude the comparison. Complete the entire matrix. Half of the matrix
%excluding the diagonal is used in nonsplit analyis. The entire matrix is
%used in split analysis. (Split refers to odd even run splitting). The order
%of conditions is the order they are found in the SDM files.
%
%You do not need to balance the number of low/high values. You can use any
%values for low and high (it doesn't have to be zero and one). The numbers
%used will have no affect so long as one number is lower and one is higher.
%For example,
%corr([0 1 1]',[0 0 1]')=0.5 AND corr([17 42 42]',[17 17 42]')=0.5
%
%You may use more than 2 non-nan values, but this can become difficult to
%interpret. If using more than 2 values, the magnitude of the middle values
%DOES matter. For example, using [0 1 2] will give different results from
%using [0 .5 2].
%
%You may create any variables here so long as they do not share a name with
%any of the variables created in the parameters section above. Only the
%"MODELS" structure will be included in the final parameters.
%
%The "MODELS" structure must contain a field called "matrices" with the
%model and a field called "names" with the models' names. The names should
%use underscores in place of spaces.

%Below is an example of a 4 condition model where conditions 1 and 2 are
%similar, conditions 3 and 4 are similar, and conditions 1/2 are different
%from 3/4. Additionally, the "fundamental diagonal" is not included in the
%model (i.e., contains no hypothesis about how each condition relates to
%itself).
% 
% %start model counter at zero
% m = 0;
% 
% %Model 1: 1/2 similar, 3/4 similar, 1/2 dif from 3/4, no diag
% m = m+1;
% MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
% MODELS.names{m} = '1and2_VS_3and4_NoDiag';
% for c1 = 1:NUMBER_OF_CONDITIONS
% for c2 = 1:NUMBER_OF_CONDITIONS
%     if c1==c2
%         %leave it. already set to nan.
%     elseif (c1<=2 & c2<=2) | (c1>2 & c2>2)
%         %similar
%         MODELS.matrices{m}(c1,c2) = 1;
%     else
%         %not/less similar
%         MODELS.matrices{m}(c1,c2) = 0;
%     end
% end
% end

%% 

%%%%%%%%%%%%
%%%
%%% IMPORTANT:
%%%
%%% Models must be symmetrical and use the entire matrix. Only exclude (set nan)
%%% cells that you do not wish to consider. I.e., do not create a model that is
%%% half of the matrix even if you are only planning use nonsplit data.
%%%
%%% Nonsplit models (half of matrix and the diagonal excluded) are automatrically
%%% generated from these full models as needed.
%%%
%%%%%%%%%%%%

%always start with this
MODELS = struct;
m = 0;

%enter models here:

%diag
m = m+1;
MODELS.matrices{m} = zeros(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Diag';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        MODELS.matrices{m}(c1,c2) = 1;
    end
end
end

% % % %example: actor
% % % actor = round(rand(1,54)*4); %<-----should be actual values (not rand)
% % % MODELS.matrices{m} = zeros(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
% % % MODELS.names{m} = 'Actor_NoDiag';
% % % for c1 = 1:NUMBER_OF_CONDITIONS
% % % for c2 = 1:NUMBER_OF_CONDITIONS
% % %     if c1==c2
% % %         MODELS.matrices{m}(c1,c2) = nan;
% % %     elseif actor(c1)==actor(c2)
% % %         MODELS.matrices{m}(c1,c2) = 1;
% % %     end
% % % end
% % % end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MODELS END HERE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% THERE IS NO NEED TO EDIT BELOW %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% add condition names to params kept
paramList{end+1} = 'CONDITIONS';

%% Organize model information and create nonsplit versions
%add nonsplit versions (top half excluding diag)
[row,col] = ind2sub([NUMBER_OF_CONDITIONS NUMBER_OF_CONDITIONS],1:(NUMBER_OF_CONDITIONS^2));
indClear = find(col <= row);
for i = 1:length(MODELS.matrices)
    MODELS.matricesNonsplit{i} = MODELS.matrices{i};
    MODELS.matricesNonsplit{i}(indClear) = nan;
end

%add models to saved params
paramList{end+1} = 'MODELS';

%% Select first valid filepath, ensure that the correct file separators are
%% used (/ or \), and ensure that filepaths end in a file separator
ind_filepathVars = find(cellfun(@(x) any(strfind(x,'FILEPATH_')),paramList));
for ind = ind_filepathVars'
    temp = eval(paramList{ind});
    if ~iscell(temp)
        error('Filepaths should be cell arrays.')
    end
    foundPath = false;
    for i = 1:length(temp)
        filepath = temp{i};
        filepath(filepath=='\' | filepath=='/') = filesep;
        if filepath(end)~=filesep
            filepath = [filepath filesep];
        end
        if exist(filepath,'dir')
            foundPath = true;
            break
        end
    end
    if ~foundPath
        error(sprintf('No valid path was found in %s.\n',paramList{ind}))
    else
        eval([paramList{ind} ' = filepath;']);
    end
end

%% Create subfolders if they do not yet exist
ind_subfolderVars = find(cellfun(@(x) any(strfind(x,'SUBFOLDER_')),paramList));
for ind = ind_subfolderVars'
    if ~eval(['exist([FILEPATH_TO_SAVE_LOCATION ' paramList{ind} '],''dir'')'])
        eval(['mkdir([FILEPATH_TO_SAVE_LOCATION ' paramList{ind} '])'])
    end
end

%% place param variables in a structure called "p"
for i = 1:length(paramList)
    eval(['p.' paramList{i} '=' paramList{i} ';'])
end

%ids must be strings in cell array
if ~iscell(p.FILELIST_PAR_ID) | ~iscell(p.FILELIST_RUN_ID) | any(~cellfun(@isstr, p.FILELIST_PAR_ID)) | any(~cellfun(@isstr, p.FILELIST_RUN_ID))
    error('IDs must be strings.')
end

end