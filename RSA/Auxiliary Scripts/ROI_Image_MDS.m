function ROI_Image_MDS

%% parameters

%output path
OUTPUT_PATH = [pwd filesep 'image_mds' filesep];

%resize images (1 = no resize)
IMAGE_SCALE = 0.25;

%image transparency (which colour to treat as transparent and range of
%similar colours to also exclude)
TRANSPARENT_COLOUR = [255 255 255]; %white is [255 255 255]
TRANSPARENT_THRESHOLD = 5;

%figure width/height in pixels
FIGURE_SIZE = 2000;

%figure background colour
FIGURE_COLOUR_BACKGROUND = [255 255 255];

%% prepare images

%load
fprintf('\nLoading images...\n')
images = load_predictor_images;

%resize and get transparency
fprintf('\nProcessing images...\n')
for i = 1:length(images)
    image = images{i};
    sz = size(image);
    
    %transparency
    trans_dif = mean(abs(single(image) - repmat(reshape(TRANSPARENT_COLOUR,[1 1 3]), [sz(1:2) 1])), 3);
    trans = trans_dif <= TRANSPARENT_THRESHOLD;
    
    %resize
    images{i} = imresize(image, IMAGE_SCALE);
    foreground{i} = imresize(~trans, IMAGE_SCALE);
end

%largest image dimension 
largest_image_dim = max(cellfun(@(x) max(size(x)), images));
adj = ((largest_image_dim / 2) / FIGURE_SIZE) + 0.05;

%% output folder

%make output folder if needed
if ~exist(OUTPUT_PATH, 'dir')
    mkdir(OUTPUT_PATH)
end

%% load mds data

%load mds data
fprintf('\nLoading MDS data...\n')
try
    %remember where to come back to
    return_path = pwd;
    
    %move to main folder
    cd ..
    
    %get params
    p = ALL_STEP0_PARAMETERS;
    
    %load coords
    fp_data = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '8. Figures' filesep 'COND MDS' filesep 'mds_data.mat'];
    fprintf('MDS Data Filepath: MAIN_FOLDER_PATH%s%s\n', filesep, fp_data);
    if ~exist(fp_data,'file')
        error('MDS data file not found! (%s)', fp_data)
    else
        load(fp_data);
    end
    
    %return to aux folder
    cd(return_path);
catch err
    warning('Could not load MDS data!')
    rethrow(err)
end
    
%% create figures

fprintf('\nCreating figures...\n');

num_pred = length(images);
fig = figure('Position',get(0,'screensize'));
num_voi = length(voi_names);
fprintf('Create voi image mds in %s\n', OUTPUT_PATH);
for v = 1:num_voi
    voi_name = voi_names{v};
    fprintf('%d of %d: %s\n', v, num_voi, voi_name);

    MD2D = all_MD2D(:, :, v);

    %set range 0-1
    MD2D = MD2D - min(MD2D(:));
    MD2D = MD2D / max(MD2D(:));

    %adjust range so that no image is cutoff on the sides
    MD2D = round(((MD2D * (1 - (adj*2))) + adj) * FIGURE_SIZE);

    %default figure
    output = uint8(repmat(reshape(FIGURE_COLOUR_BACKGROUND, [1 1 3]), [FIGURE_SIZE FIGURE_SIZE]));

    %add condition images
    for i = 1:num_pred
        x = MD2D(i, 1);
        y = MD2D(i, 2);

        img = images{i};
        sz = size(img);
        ind = find(repmat(foreground{i}, [1 1 3]));
        [x_foreground, y_foreground, z_foreground] = ind2sub(sz, ind);
        x_foreground = round(x_foreground - (sz(1)/2) + x);
        y_foregorund = round(y_foreground - (sz(2)/2) + y);

        ind_fig = sub2ind(size(output), x_foreground, y_foregorund, z_foreground);

        output(ind_fig) = img(ind);

    end

    imagesc(output)
    title(strrep(voi_name,'_',' '));
    axis image
    drawnow

    fn = [OUTPUT_PATH voi_name '.png'];
    fprintf('Writing: %s\n', fn);
    imwrite(output, fn, 'png');
end
close(fig);

%% Done
disp Complete!
    
