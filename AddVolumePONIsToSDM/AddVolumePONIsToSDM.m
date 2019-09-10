%This script adds one or more single-volume PONIs to selected SDM(s)
function AddVolumePONIsToSDM

%% Parameters
VOLUMES_TO_PONI = 1:10;

SEARCH_START_DIRECTORY = '\\bmi-2018n\Carol_MNI\BrainVoyagerData\Carol_MNI_Localizer\'
SEARCH_FILENAME = '*_PRT-and-3DMC.sdm';

PREDICTOR_COLOUR = [255 0 0];

%% Select SDMs
if SEARCH_START_DIRECTORY(end) ~= filesep
    SEARCH_START_DIRECTORY(end+1) = filesep;
end
[files, directory, filter] = uigetfile([SEARCH_START_DIRECTORY SEARCH_FILENAME], 'MultiSelect', 'on');
if isnumeric(files)
    fprintf('No files selected.\n');
    return
elseif filter ~= 1
    error('Invalid file selection')
end
if ~iscell(files)
    files = {files};
end

%% Add PONIs
number_files = length(files);
number_PONI = length(VOLUMES_TO_PONI);
for fid = 1:number_files
    fn = files{fid};
    
    d = find(fn=='.',1,'last');
    fn_out = sprintf('%s_VolumePONIs%s', fn(1:d-1), fn(d:end));
    
    fprintf('Processing file %d of %d: %s ==> %s\n', fid, number_files, fn, fn_out);
    
    if exist([directory fn_out], 'file')
        error('Output file already exists: %s', fn_out)
    end
    
    sdm = xff([directory fn]);
    
    for i = 1:number_PONI
        vol = VOLUMES_TO_PONI(i);
        
        %where to insert
        if sdm.IncludesConstant
            ind = sdm.NrOfPredictors;
        else
            ind = sdm.NrOfPredictors + 1;
        end
        
        %insert colour
        sdm.PredictorColors = [sdm.PredictorColors(1:ind-1,:); PREDICTOR_COLOUR; sdm.PredictorColors(ind:end,:)];
        
        %insert name
        sdm.PredictorNames = [sdm.PredictorNames(1:ind-1) {sprintf('PONIVol%d', vol)} sdm.PredictorNames(ind:end)];
        
        %insert predictor
        predictor = zeros(sdm.NrOfDataPoints,1);
        predictor(vol) = 1;
        sdm.SDMMatrix = [sdm.SDMMatrix(:,1:ind-1) predictor sdm.SDMMatrix(:,ind:end)];
        
        %increment
        sdm.NrOfPredictors = sdm.NrOfPredictors + 1;
        
    end
    
    %save
    sdm.SaveAs([directory fn_out]);
    
    sdm.ClearObject;
    clear sdm
end

%% Done
disp Complete!