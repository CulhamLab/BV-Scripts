function [images] = load_predictor_images

%% Parameters

%where to find all images
IMAGE_FOLDER = [pwd filesep 'images' filesep];

%filetype to look for
IMAGE_FILETYPE = 'jpg';

%Select or define a function to convert predictor display names to image filenames
%
%use this function if predictor names match image filenames (excluding file extension)
PRED_TO_IMG_NAME = (@(x) x);
%
%example of using another function
% PRED_TO_IMG_NAME = @PRED_TO_IMG_NAME_Carol_2018; %see function at bottom of script
%
%example of creating a basic function
% PRED_TO_IMG_NAME = (@(x) strrep(x,' ','_'));


%% Run

%load main parameters
try
    %remember where to come back to
    return_path = pwd;
    
    %move to main folder
    cd ..
    
    %get params
    p = ALL_STEP0_PARAMETERS;
    
    %return
    cd(return_path)
catch err
    warning('Could not load main parameters!')
    if exist('return_path', 'var')
        %if possible, return
        cd(return_path)
    end
    rethrow(err)
end

%load all images
num_pred = length(p.CONDITIONS.DISPLAY_NAMES);
fprintf('Reading images in %s\n', IMAGE_FOLDER);
for i = 1:num_pred
    pred_name = p.CONDITIONS.DISPLAY_NAMES{i};
    fn = [PRED_TO_IMG_NAME(pred_name) '.' IMAGE_FILETYPE];
    fp = [IMAGE_FOLDER fn];
    fprintf('%d of %d: %s ==> %s\n', i, num_pred, pred_name, fn)
    if ~exist(fp,'file')
        error('Cannot find image! (%s)', fp);
    else
        %load
        images{i} = imread(fp);
    end
end

%images is returned

%Example of creating a function to get image names
% function [image_name] = PRED_TO_IMG_NAME_Carol_2018(predictor_name)
% image_name = predictor_name;
% image_name(find(image_name=='_',1,'last')) = '';