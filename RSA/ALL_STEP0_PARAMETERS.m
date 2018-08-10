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
NUMBER_OF_PARTICIPANTS = 23;
NUMBER_OF_RUNS = 8;
NUMBER_OF_CONDITIONS = 8;

%% file locations (subfolders are automatically created)
%If multiple filepaths are entered, the first valid path will be used. This
%is intended to allow shared scripts to be used on different machines as
%each machine will have its own unique path to the data and output folders.
FILEPATH_TO_VTC_AND_SDM = {'..\..\Rita-Kevin_BigFiles\Large RSA Files\BV Files' 'C:\Users\kmstu\Downloads\RitaRSA'}; %this is the folder where your VTCs and SDMs are located
FILEPATH_TO_SAVE_LOCATION = {'..\..\Rita-Kevin_BigFiles\Large RSA Files' 'C:\Users\kmstu\Downloads\RitaRSA'}; %this where you would like the output files to be saved - several subfolders will be generated within this folder
SUBFOLDER_SHARED_DATA = 'Both';
SUBFOLDER_SEARCHLIGHT_DATA = 'Searchlight';
SUBFOLDER_ROI_DATA = 'ROI';

%Path to VOI file used in ROI steps. If left as NaN, "ROI_STEP6_extractROI"
%will prompt you to choose a VOI file with a file selector.
VOI_FILE = 'neurosynth_Rubik_final_radius_7mm.voi';

%% file list (for vtc/sdm)
FILELIST_FILENAME = 'filelist.xls';
FILELIST_PAR_ID = arrayfun(@(x) sprintf('P%d',x), 1:NUMBER_OF_PARTICIPANTS, 'UniformOutput', false); %must be strings
FILELIST_RUN_ID = arrayfun(@(x) sprintf('func-S1R%d',x), 1:NUMBER_OF_RUNS, 'UniformOutput', false); %must be strings
FILELIST_FORMAT_VTC = '[PAR]_[RUN]_3DMCTS_LTR_THPGLMF2c_MNI.vtc'; %replaces [PAR] from PAR_ID and [RUN] from RUN_ID
FILELIST_FORMAT_SDM = '[PAR]_[RUN]_PredWithMotion_NoBaseline.sdm'; %replaces [PAR] from PAR_ID and [RUN] from RUN_ID

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

%DEFAULT: name conditions numerically (e.g., 1 to 10)
%CONDITIONS = cellfun(@num2str,num2cell(1:NUMBER_OF_CONDITIONS),'UniformOutput',false);

% % % %psych9223
% % % face = [1 1 1 0 0 0];
% % % dir = [-1 0 +1 -1 0 +1];
% % % CONDITIONS.PREDICTOR_NAMES = {'Face_Left',
% % %                                 'Face_Center',
% % %                                 'Face_Right',
% % %                                 'Hand_Left',
% % %                                 'Hand_Center',
% % %                                 'Hand_Right'};
% % % CONDITIONS.DISPLAY_NAMES = strrep(CONDITIONS.PREDICTOR_NAMES,'_','');

%RITA

cond_size = [1 1 2 2 1 1 2 2]; %1=small, 2=large
cond_distance = [1 1 1 1 2 2 2 2]; %1=near, 2=far
cond_id = [1 2 1 2 1 2 1 2]; %1=die, 2=rubik
cond_retinal = [5 5 15 15 1 1 5 5];
cond_congruent = [1 0 0 1 1 0 0 1]; %1=true, 0=false
cond_fullid = [1 2 3 4 1 2 3 4]; %id + size
cond_squares = [1 1 2 2 3 3 4 4];

CONDITIONS.PREDICTOR_NAMES = {  'SP SF N 5 (Small Die Near)'
                                'SP LF N 5 (Small Rubik Near)'
                                'LP SF N 15 (Big Die Near)'
                                'LP LF N 15 (Big Rubik Near)'
                                'SP SF F 1.4 (Small Die Far)'
                                'SP LF F 1.4 (Small Rubik Far)'
                                'LP SF F 5 (Big Die Far)'
                                'LP LF F 5 (Big Rubik Far)'
                                };
                            
CONDITIONS.DISPLAY_NAMES = {    'Sm Die N'
                                'Sm Rubik N'
                                'Lg Die N'
                                'Lg Rubik N'
                                'Sm Die F'
                                'Sm Rubik F'
                                'Lg Die F'
                                'Lg Rubik F'
                                };

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

%Identity
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Identity';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_id(c1) == cond_id(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%Identity no diag
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Identity_NoDiag';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_id(c1) == cond_id(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%Identity NoDiagSquare
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Identity_NoDiagSquare';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_squares(c1)==cond_squares(c2)
        %leave nan
    elseif cond_id(c1) == cond_id(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end
%Identity Half/Between Distances
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Identity_BtDist';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if (c1 == c2)
    elseif cond_id(c1) == cond_id(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
    
    %%% removes top right and bot left
    if cond_distance(c1) ~= cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = nan;
    end
end
end

%Identity Half/Within Distances
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Identity_WtDist';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if (c1 == c2)
    elseif cond_id(c1) == cond_id(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
    
    %%% removes top right and bot left
    if cond_distance(c1) == cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = nan;
    end
end
end

%physical size
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'PhysicalSize';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_size(c1) == cond_size(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end


%physical size no diag
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'PhysicalSize_NoDiag';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_size(c1) == cond_size(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%physical size NoDiagSquare
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'PhysicalSize_NoDiagSquare';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_squares(c1)==cond_squares(c2)
        %leave nan
    elseif cond_size(c1) == cond_size(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%Physical Size Half/Between Distances
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'PhysicalSize_BtDist';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_size(c1) == cond_size(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
    
    %%% removes top right and bot left
    if cond_distance(c1) ~= cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = nan;
    end
end
end

%Physical Size Half/Within Distances
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'PhysicalSize_WtDist';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_size(c1) == cond_size(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
    
    %%% removes top left and bot right
    if cond_distance(c1) == cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = nan;
    end
end
end

%SameSize_SameLocation_DifID
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'SameSize_SameDistance_DifID';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif (cond_size(c1) == cond_size(c2)) && (cond_distance(c1) == cond_distance(c2))
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%Distance
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Distance';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_distance(c1) == cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%Distance no diag
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Distance_NoDiag';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_distance(c1) == cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%Distance NoDiagSquare
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Distance_NoDiagSquare';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_squares(c1)==cond_squares(c2)
        %leave nan
    elseif cond_distance(c1) == cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

% % % %Distance Half/Between Distances
% % % m = m+1;
% % % MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
% % % MODELS.names{m} = 'Distance_BtDist';
% % % for c1 = 1:NUMBER_OF_CONDITIONS
% % % for c2 = 1:NUMBER_OF_CONDITIONS
% % %     if c1==c2
% % %         %leave nan
% % %     elseif cond_distance(c1) == cond_distance(c2)
% % %         MODELS.matrices{m}(c1,c2) = 1;
% % %     else
% % %         MODELS.matrices{m}(c1,c2) = 0;
% % %     end
% % %     
% % %     
% % % %%% removes top right and bot left
% % %     if cond_distance(c1) ~= cond_distance(c2)
% % %         MODELS.matrices{m}(c1,c2) = nan;
% % %     end
% % % end
% % % end

% % % %Distance Half/Within Distances
% % % m = m+1;
% % % MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
% % % MODELS.names{m} = 'Distance_WtDist';
% % % for c1 = 1:NUMBER_OF_CONDITIONS
% % % for c2 = 1:NUMBER_OF_CONDITIONS
% % %     if c1==c2
% % %         %leave nan
% % %     elseif cond_distance(c1) == cond_distance(c2)
% % %         MODELS.matrices{m}(c1,c2) = 1;
% % %     else
% % %         MODELS.matrices{m}(c1,c2) = 0;
% % %     end
% % %     
% % % %%% removes top left and bot right
% % %     if cond_distance(c1) == cond_distance(c2)
% % %         MODELS.matrices{m}(c1,c2) = nan;
% % %     end
% % % end
% % % end

%RetinalSize
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'RetinalSize';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    MODELS.matrices{m}(c1,c2) = (14 - abs(cond_retinal(c1) - cond_retinal(c2))) / 14;
end
end

%RetinalSize NoDiag
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'RetinalSize_NoDiag';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    else
        MODELS.matrices{m}(c1,c2) = (14 - abs(cond_retinal(c1) - cond_retinal(c2))) / 14;
    end
end
end

%RetinalSize NoDiagSquare
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'RetinalSize_NoDiagSquare';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_squares(c1)==cond_squares(c2)
        %leave nan
    else
        MODELS.matrices{m}(c1,c2) = (14 - abs(cond_retinal(c1) - cond_retinal(c2))) / 14;
    end
end
end

%RetinalSize Half/Between Distances
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'RetinalSize_BtDist';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    else
        MODELS.matrices{m}(c1,c2) = (14 - abs(cond_retinal(c1) - cond_retinal(c2))) / 14;
    end
    
%%% removes top right and bot left
    if cond_distance(c1) ~= cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = nan;
    end
end
end

%RetinalSize Half/Within Distances
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'RetinalSize_WtDist';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    else
        MODELS.matrices{m}(c1,c2) = (14 - abs(cond_retinal(c1) - cond_retinal(c2))) / 14;
    end
    
%%% removes top left and bot right
    if cond_distance(c1) == cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = nan;
    end
end
end

%Congruency
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Congruency';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_congruent(c1) == cond_congruent(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%Congruency NoDiag
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Congruency_NoDiag';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_congruent(c1) == cond_congruent(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%Congruency NoDiagSquare
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Congruency_NoDiagSquare';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_squares(c1)==cond_squares(c2)
        %leave nan
    elseif cond_congruent(c1) == cond_congruent(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%Congruency Half/Between Distances
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Congruency_BtDist';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_congruent(c1) == cond_congruent(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
    
%%% removes top right and bot left
    if cond_distance(c1) ~= cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = nan;
    end
end
end

%Congruency Half/Within Distances
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'Congruency_WtDist';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_congruent(c1) == cond_congruent(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
    
%%% removes top left and bot right
    if cond_distance(c1) == cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = nan;
    end
end
end

%SizeConstancy
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'SizeConstancy';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_fullid(c1) == cond_fullid(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%SizeConstancy NoDiag
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'SizeConstancy_NoDiag';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_fullid(c1) == cond_fullid(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

%SizeConstancy NoDiagSquare
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'SizeConstancy_NoDiagSquare';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if cond_squares(c1)==cond_squares(c2)
        %leave nan
    elseif cond_fullid(c1) == cond_fullid(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
end
end

% % % %SizeConstancy Half/Between Distances
% % % m = m+1;
% % % MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
% % % MODELS.names{m} = 'SizeConstancy_BtDist';
% % % for c1 = 1:NUMBER_OF_CONDITIONS
% % % for c2 = 1:NUMBER_OF_CONDITIONS
% % %     if c1==c2
% % %         %leave nan
% % %     elseif cond_fullid(c1) == cond_fullid(c2)
% % %         MODELS.matrices{m}(c1,c2) = 1;
% % %     else
% % %         MODELS.matrices{m}(c1,c2) = 0;
% % %     end
% % %     
% % % %%% removes top right and bot left
% % %     if cond_distance(c1) ~= cond_distance(c2)
% % %         MODELS.matrices{m}(c1,c2) = nan;
% % %     end
% % % end
% % % end

%SizeConstancy Half/Within Distances
m = m+1;
MODELS.matrices{m} = nan(NUMBER_OF_CONDITIONS,NUMBER_OF_CONDITIONS);
MODELS.names{m} = 'SizeConstancy_WtDist';
for c1 = 1:NUMBER_OF_CONDITIONS
for c2 = 1:NUMBER_OF_CONDITIONS
    if c1==c2
        %leave nan
    elseif cond_fullid(c1) == cond_fullid(c2)
        MODELS.matrices{m}(c1,c2) = 1;
    else
        MODELS.matrices{m}(c1,c2) = 0;
    end
    
%%% removes top left and bot right
    if cond_distance(c1) == cond_distance(c2)
        MODELS.matrices{m}(c1,c2) = nan;
    end
end
end


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

%% Create filelist if it doesn't yet exist
if ~exist(FILELIST_FILENAME,'file')
    create_filelist(p);
end

%ids must be strings in cell array
if ~iscell(p.FILELIST_PAR_ID) | ~iscell(p.FILELIST_RUN_ID) | any(~cellfun(@isstr, p.FILELIST_PAR_ID)) | any(~cellfun(@isstr, p.FILELIST_RUN_ID))
    error('IDs must be strings.')
end

end

function create_filelist(p)

%% checks
if length(p.FILELIST_PAR_ID) ~= p.NUMBER_OF_PARTICIPANTS
    error('Invalid number of participants ids.');
end

%% run
%delete prior filelist if any
if exist(p.FILELIST_FILENAME,'file')
    delete(p.FILELIST_FILENAME);
end

%run
xls = {'Participant' 'Run' 'VTC' 'SDM'};
for par = 1:p.NUMBER_OF_PARTICIPANTS
    for run = 1:p.NUMBER_OF_RUNS
        fn_vtc = strrep(strrep(p.FILELIST_FORMAT_VTC,'[PAR]',p.FILELIST_PAR_ID{par}),'[RUN]',p.FILELIST_RUN_ID{run});
        fn_sdm = strrep(strrep(p.FILELIST_FORMAT_SDM,'[PAR]',p.FILELIST_PAR_ID{par}),'[RUN]',p.FILELIST_RUN_ID{run});
        
        fp_vtc = [p.FILEPATH_TO_VTC_AND_SDM fn_vtc];
        fp_sdm = [p.FILEPATH_TO_VTC_AND_SDM fn_sdm];
        
        %check if files exist
        if ~exist(fp_vtc,'file')
            warning(sprintf('Cannot Find VTC: %s\n',fp_vtc));
        end
        if ~exist(fp_sdm,'file')
            warning(sprintf('Cannot Find SDM: %s\n',fp_sdm));
        end
        
        xls(end+1,:) = {par run fp_vtc fp_sdm};
    end
end

xlswrite(p.FILELIST_FILENAME,xls);

end