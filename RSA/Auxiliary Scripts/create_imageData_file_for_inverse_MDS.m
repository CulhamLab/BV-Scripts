%For use with multi-arrangement-2017 (inverse mds)
%Kriegeskorte N, Mur M (2012)
%
%imageData is a struct with fields:
%filename:  Nx1 cell array of images names
%image:     Nx1 cell array of images (uint8)
%alpha:     optional, Nx1 cell array of image alpha values (binary for transparency)
%predictor: Nx1 cell array of predictor names (not used by inverse mds script,
%           can be used to collapse inverse mds output if there is more than
%           one image per predictor)
function Create_imageData_File_For_Inverse_MDS

%% Parameters

%if set true and if there is more than one image for a predictor, then only 
%the first image will be used
LIMIT_TO_FIRST_IMAGE_IF_MULTIPLE_IMAGES_PER_PREDICTOR = false;

PREDICTORS_TO_EXCLUDE = []; %array of the index numbers of any predictors to exclude

APPLY_TRANSPARENCY = true;
TRANSPARENT_COLOUR = [255 255 255]; %white is [255 255 255]
TRANSPARENT_THRESHOLD = 5;

FILEPATH_OUTPUT = 'imageData.mat';

%% Load (load_predictor_images)
[images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images;

%% Process
c=0;
for pred = 1:p.NUMBER_OF_CONDITIONS
    pred_name = p.CONDITIONS.DISPLAY_NAMES{pred};
    if any(pred == PREDICTORS_TO_EXCLUDE)
        fprintf('Excluding predictor %d (%s)!\n', pred, pred_name);
    else
        ind = find(image_pred_value == pred);

        if isempty(ind)
            error('No images found for predictor %d (%s)!', pred, pred_name)
        elseif LIMIT_TO_ONE_IMAGE_IF_COLLAPSING && length(ind)~=1
            ind = ind(1);
            fprintf('Limiting predictor %d (%s) to first image: %s\n', pred, pred_name, image_names{ind});
        end

        for i = ind
            c=c+1;
            filename{c,1} = image_names{i};
            image{c,1} = uint8(images{i});
            alpha{c,1} = Get_Transparency(image{c,1}, TRANSPARENT_COLOUR, TRANSPARENT_THRESHOLD);
            predictor{c,1} = pred_name;
        end
    end
end

%% Save
if APPLY_TRANSPARENCY
    imageData = struct('filename',filename,'image',image,'alpha',alpha,'predictor',predictor);
else
    imageData = struct('filename',filename,'image',image,'predictor',predictor);
end
fprintf('Saving: %s\n', FILEPATH_OUTPUT);
save(FILEPATH_OUTPUT, 'imageData');

%% Done
disp Done.

function [alpha] = Get_Transparency(image, TRANSPARENT_COLOUR, TRANSPARENT_THRESHOLD)
sz = size(image);
trans_dif = mean(abs(single(image) - repmat(reshape(TRANSPARENT_COLOUR,[1 1 3]), [sz(1:2) 1])), 3);
alpha = trans_dif > TRANSPARENT_THRESHOLD;
