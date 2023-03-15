% function SDM_Reorder(filepath_in, filepath_out, new_order, first_confound)
%
% -Reads SDM from filepath_in
% -Adjust predictor order to the list of predictor names in new_order
%       All POI must exist
%       Specified PONI may be absent if allow_variable_PONI is set true
%       You may fully exclude predictors to remove them
% -Update the FirstConfoundPredictor field as first_confound
% -Write SDM to filepath_out
%
function SDM_Reorder(filepath_in, filepath_out, new_order, first_confound, allow_variable_PONI)

%% Parse
% Get folder path
[folder,filename,ext] = fileparts(filepath_in);
filename = [filename ext];
if isempty(folder)
    folder = pwd;
end

%% Read
% Cannot read from extremely long filepaths so navigate, load directly, and
% then return.
return_path = pwd;
try
    cd(folder)
    sdm = xff(filename);
    cd(return_path)
catch err
    cd(return_path)
    rethrow(err)
end

%% Reorder
number_predictors = length(new_order);
order = nan(1,number_predictors);
for i = 1:number_predictors
    ind = find(strcmp(sdm.PredictorNames,new_order{i}));
    if length(ind) ~= 1
        if (i >= first_confound) && allow_variable_PONI
            %allow missing PONI
        else
            error('Did not find exactly one match for: %s', new_order{i})
        end
    else
        order(i) = ind;
    end
end

%account for missing
found = ~isnan(order);
order = order(found);
new_order = new_order(found);
number_predictors = sum(found);

sdm.PredictorColors = sdm.PredictorColors(order,:);
sdm.PredictorNames = sdm.PredictorNames(order);

matrix = sdm.SDMMatrix(:,order);
sdm.SDMMatrix = matrix;
sdm.RTCMatrix = matrix(:,1:(first_confound-1));

sdm.NrOfPredictors = number_predictors;
sdm.FirstConfoundPredictor = first_confound;


%% Write
sdm.SaveAs(filepath_out);