function ROI_Image_MDS

%% parameters

%Parameters must also be set in "load_predictor_images.m"

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

%select subset of conditions
%-cell array of predictor names
%-or leave empty [] to use all conditions
CONDITION_SUBSET = [];
% % CONDITION_SUBSET = [arrayfun(@(x) sprintf('Food_1H_%d', x), 1:6, 'UniformOutput', false) ...
% %         arrayfun(@(x) sprintf('Food_2H_%d', x), 1:6, 'UniformOutput', false) ...
% %         arrayfun(@(x) sprintf('Food_Fork_%d', x), 1:3, 'UniformOutput', false) ...
% %         arrayfun(@(x) sprintf('Food_Chopstick_%d', x), 1:3, 'UniformOutput', false) ...
% %         arrayfun(@(x) sprintf('Food_Spoon_%d', x), 1:3, 'UniformOutput', false) ...
% %         arrayfun(@(x) sprintf('Food_Knife_%d', x), 1:3, 'UniformOutput', false)];

%% prepare images

%load
fprintf('\nLoading images...\n')
[images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images;

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
fprintf('\nLoading data for MDS...\n')
try
    %remember where to come back to
    return_path = pwd;
    
    %move to main folder
    cd ..
    
    %get params
    p = ALL_STEP0_PARAMETERS;
    
    %calc new MDS?
    custom_mds = ~isempty(CONDITION_SUBSET);
    if ~custom_mds
        %use all conditions - load existing MDS
        fp_data = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '8. Figures' filesep 'COND MDS' filesep 'mds_data.mat'];
        fprintf('MDS Data Filepath: MAIN_FOLDER_PATH%s%s\n', filesep, fp_data);
        if ~exist(fp_data,'file')
            error('MDS data file not found! (%s)', fp_data)
        else
            load(fp_data);
        end
    else
        %condition subset - calculate new MDS
        fp_data = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep 'VOI_RSMs.mat'];
        fprintf('VOI RSM Data Filepath: MAIN_FOLDER_PATH%s%s\n', filesep, fp_data);
        if ~exist(fp_data,'file')
            error('VOI RSM data file not found! (%s)', fp_data)
        else
            load(fp_data);
        end
    end
    
    %return to aux folder
    cd(return_path);
catch err
    warning('Could not load MDS data!')
    rethrow(err)
end

%% Handle Condition Subset
if custom_mds
    voi_names = data.VOINames;
    num_voi = length(voi_names);
    num_pred = length(CONDITION_SUBSET);
    
    fprintf('Generating condition subset data...\n');
    try
        ind_pred = cellfun(@(x) find(strcmp(p.CONDITIONS.PREDICTOR_NAMES, x)), CONDITION_SUBSET);
    catch
        error('Error matching CONDITION_SUBSET to p.CONDITIONS.PREDICTOR_NAMES. Each value should find exactly one match.');
    end
    rsms_nonsplit = data.RSM_nonsplit(ind_pred, ind_pred, :, :);
        
    fprintf('Calculating custom MDS for condition subset...\n');
    for vid = 1:num_voi
        %mean rsm across subs
        rsm = mean(rsms_nonsplit(:,:,:,vid),3);
        
        %convert to rdm
        rdm = (rsm-1) *-0.5; %multiplying by 0.5 doesn't affect mds but fits data 0-1 (unless Fisher is applied)
        
        %apply fisher (if desired)
        if p.DO_FISHER_CONDITION_MDS
            rdm = atanh(rdm);
        end
        
        %set diag to true zero (prevent rounding issues)
        for i = 1:p.NUMBER_OF_CONDITIONS
            rdm(i,i) = 0;
        end
        
        %mds 2D
        rdm = squareform(rdm);
        all_MD2D(:,:,vid) = mdscale(rdm,2,'criterion','sstress');
    end
else
    num_pred = p.NUMBER_OF_CONDITIONS;
    ind_pred = 1:num_pred;
    num_voi = length(voi_names);
end
    
%% create figures

fprintf('\nCreating figures...\n');
fig = figure('Position',get(0,'screensize'));
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
		
		ind_img = find(image_pred_value == ind_pred(i), 1, 'first');
		
		fprintf('  %s => %s\n', p.CONDITIONS.DISPLAY_NAMES{ind_pred(i)}, image_names{ind_img});

        img = images{ind_img};
        sz = size(img);
        ind = find(repmat(foreground{ind_pred(i)}, [1 1 3]));
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
    
