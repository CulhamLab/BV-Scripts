%aux_readSDM_displayConditionOrder
%
%INSTRUCTIONS:
%Run the script and select an SDM when prompted. The order of conditions
%will be displayed (may include predictors such as translation, rotation,
%and constant).
%
%NOTE:
%Uses the "FILEPATH_TO_VTC_AND_SDM" parameter from BOTH_setep0_PARAMETERS.
%
function aux_readSDM_displayConditionOrder

%get params
returnPath = pwd;
cd ..
[p] = ALL_STEP0_PARAMETERS;
cd(returnPath)

%select file
[FileName,PathName,FilterIndex] = uigetfile(sprintf('%s*.sdm',p.FILEPATH_TO_VTC_AND_SDM));
if FilterIndex~=1
    error('Must select an SDM.')
end

%load
fpath = [PathName FileName];
fprintf('Reading %s\n',fpath)
sdm = xff(fpath);

conditionNames = sdm.PredictorNames';
fprintf('Found %d conditions. Some of these may be predictors like translation, rotation, or the error constant.\n',length(conditionNames))
for i = 1:length(conditionNames)
    fprintf('%d. %s\n',i,conditionNames{i})
end