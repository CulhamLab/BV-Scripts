function [images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images

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
% PRED_TO_IMG_NAME = (@(x) strrep(x,' ','_'));

%image collapsing
%
%cell array of size [# predictor to expand] x 2
%first column has predictor name
%second column has image names of all images to use for that predictor
IMAGE_COLLAPSE = cell(0,2); %leave this line
% IMAGE_COLLAPSE(end+1,:) = {'Scrambled' , [arrayfun(@(x) sprintf('scramble_Food_1H%d', x), 1:6, 'UniformOutput', false) ... 
%                                     arrayfun(@(x) sprintf('scramble_Food_2H%d', x), 1:6, 'UniformOutput', false) ... 
%                                     arrayfun(@(x) sprintf('scramble_Food_Chopstick%d', x), 1:3, 'UniformOutput', false) ... 
%                                     arrayfun(@(x) sprintf('scramble_Food_Fork%d', x), 1:3, 'UniformOutput', false) ... 
%                                     arrayfun(@(x) sprintf('scramble_Food_Knife%d', x), 1:3, 'UniformOutput', false) ... 
%                                     arrayfun(@(x) sprintf('scramble_Food_Spoon%d', x), 1:3, 'UniformOutput', false)]};

%% Get main parameters

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

%% Image names

num_pred = length(p.CONDITIONS.PREDICTOR_NAMES);

image_names = cell(0);
image_pred_value = [];
image_is_collapse = [];

for pred = 1:num_pred
    pred_name = p.CONDITIONS.PREDICTOR_NAMES{pred};
    
    ind = find(strcmp(IMAGE_COLLAPSE(:,1), pred_name));
    if isempty(ind)
        image_names{end+1} = PRED_TO_IMG_NAME(pred_name);
        image_pred_value(end+1) = pred;
        image_is_collapse(end+1) = false;
    elseif length(ind) == 1
        
        subimages = IMAGE_COLLAPSE{ind,2};
        if ~iscell(subimages), subimages = {subimages};, end
        
        for i = 1:length(subimages);
            image_names{end+1} = subimages{i};
            image_pred_value(end+1) = pred;
            image_is_collapse(end+1) = true;
        end
        
    else
        error('A predictor matches more than one IMAGE_COLLAPSE!')
    end
    
end

%check that all are unique
if length(image_names) ~= length(unique(image_names))
    image_names'
    error('One or more image name is not unique!')
end

%% Load all images

num_image = length(image_pred_value);
fprintf('Reading images in %s\n', IMAGE_FOLDER);
for i = 1:num_image
    pred_name = p.CONDITIONS.DISPLAY_NAMES{image_pred_value(i)};
    
    fn = [image_names{i} '.' IMAGE_FILETYPE];
    fp = [IMAGE_FOLDER fn];
    
    fprintf('%03d of %03d: Pred%03d=%s ==> %s\n', i, num_image, image_pred_value(i), pred_name, fn)
    if ~exist(fp,'file')
        error('Cannot find image! (%s)', fp);
    else
        %load
        images{i} = imread(fp);
    end
end

%images is returned

function [image_name] = PRED_TO_IMG_NAME_Carol_2018(predictor_name)
% image_name = [predictor_name '_1'];
image_name = predictor_name;
image_name(find(image_name=='_',1,'last')) = '';