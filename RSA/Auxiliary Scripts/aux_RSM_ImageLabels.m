function aux_RSM_ImageLabels

%% Parameters

PIXEL_SIZE_RSM_CELLS = 50;
PIXEL_SIZE_LABELS = 80;

%% Load
fprintf('\nLoading images...\n')
% [images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images;

%% Resize Images
images_max_dim = cellfun(@(x) max(size(x)), images, 'UniformOutput', false);
images_resized = cellfun(@(x,y) imresize(x,PIXEL_SIZE_LABELS/y), images, images_max_dim);

%% Load RSMs
try
    load([main_path p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep 'VOI_RSMs.mat']);
catch err
    warning('Could not load VOI RSMs. Has VOI step6 been run or has data moved?')
    rethrow(err);
end

%% Resize RSMs
%imresize(~~, #, 'Nearest');

%% Plot
%image(x_left,y_bottom,image);