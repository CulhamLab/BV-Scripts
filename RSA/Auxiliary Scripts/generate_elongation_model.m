%Elongation is calculated by:
%1. Binarize image
%2. Rotate 0-to-180 degrees (in ROTATION_STEPS-many steps)
%3. Select angle with largest image height
%4. Calculate ratio as height/width (at selected angle)
%
function generate_elongation_model

%% Parameters

DIR_SAVE = pwd;
FILENAME_SAVE = 'elongation_model';
FILETYPE_IMAGE = '.png';

MAKE_ELONGATION_IMAGES = true;
DIR_ELONGATION_IMAGES = ['.' filesep 'ElongationImages' filesep];

FONT_SIZE = 6;

%for binarizing
BACKGROUND_COLOUR = [255 255 255];
BACKGROUND_COLOUR_THRESHOLD = 5;

%number of steps in 180 degree rotation
%higher value = more precise measure but takes longer
ROTATION_STEPS = 360;

%% Checks
if DIR_SAVE(end) ~= filesep
    DIR_SAVE(end+1) = filesep;
end
if DIR_ELONGATION_IMAGES(end) ~= filesep
    DIR_ELONGATION_IMAGES(end+1) = filesep;
end

if ~exist(DIR_SAVE, 'dir')
    mkdir(DIR_SAVE)
end

%% Load
fprintf('\nLoading images...\n')
[images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images;

%% Binarize Images
fprintf('\nBinarizing images...\n')
images_binary = cellfun(@(x) mean(abs(single(x) - repmat(reshape(BACKGROUND_COLOUR,[1 1 3]), [size(x,1) size(x,2) 1])), 3) > BACKGROUND_COLOUR_THRESHOLD, images, 'UniformOutput', false);

%% Calculate Elongation
fprintf('\nCalculating elongation ratios (%d rotation steps each)...\n', ROTATION_STEPS)
num_image = length(images);
step_size = 180 / ROTATION_STEPS;
for i = 1:num_image
    fprintf('-Processing %d of %d: %s\n', i, num_image, image_names{i});
    longest = 0;
    longest_angle = 0;
    
    for a = 0:step_size:180
        img = imrotate(images_binary{i}, a);
        valid_rows = any(img,2);
        first = find(valid_rows,1,'first');
        last = find(valid_rows,1,'last');
        len = last - first + 1;
        
        if (len > longest)
            longest = len;
            longest_angle = a;
        end
    end
    
    if (longest <= 0)
        error('Could not find longest dimension')
    end
    
    img = imrotate(images_binary{i}, longest_angle);
    elongation_data(i).angle = longest_angle;
    
    valid_rows = any(img,2);
    elongation_data(i).first_row = find(valid_rows,1,'first');
    elongation_data(i).last_row = find(valid_rows,1,'last');
    elongation_data(i).height = elongation_data(i).last_row - elongation_data(i).first_row  + 1;
    
    valid_cols = any(img,1);
    elongation_data(i).first_col = find(valid_cols,1,'first');
    elongation_data(i).last_col = find(valid_cols,1,'last');
    elongation_data(i).width = elongation_data(i).last_col - elongation_data(i).first_col  + 1;
    
    elongation_data(i).ratio = elongation_data(i).height / elongation_data(i).width;
end

%% Make Rotated Figures
if MAKE_ELONGATION_IMAGES
    if ~exist(DIR_ELONGATION_IMAGES, 'dir')
        mkdir(DIR_ELONGATION_IMAGES)
    end
    fig = figure('Position', [1 1 1500 500]);
    for i = 1:num_image
        subplot(1,3,1)
        imshow(images{i})

        subplot(1,3,2)
        img = imrotate(images_binary{i}, elongation_data(i).angle);
        img = img(elongation_data(i).first_row:elongation_data(i).last_row, elongation_data(i).first_col:elongation_data(i).last_col, :);
        imshow(img)

        subplot(1,3,3)
        img = imrotate(images{i}, elongation_data(i).angle);
        img = img(elongation_data(i).first_row:elongation_data(i).last_row, elongation_data(i).first_col:elongation_data(i).last_col, :);
        imshow(img)

        suptitle(sprintf('%s (ratio = %g)', strrep(image_names{i},'_',' '), elongation_data(i).ratio))
        saveas(fig, [DIR_ELONGATION_IMAGES image_names{i}], 'png')
        
    end
    close(fig);
end

%% Make Model

%% Difference Match
elongation_diff_matrix = squareform(pdist([elongation_data.ratio]'));

%% Simmilarity Model
elongation_model = (elongation_diff_matrix / -max(elongation_diff_matrix(:))) + 1;

%% Model Figure
fig = figure('Position', [1 1 1200 1000]);
fprintf('\nCreating elongation model figure...\n')
    clf
    imagesc(elongation_model)
    axis image
    colormap jet
    colorbar
    caxis([0 1])
    fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES(image_pred_value), 'UniformOutput', false);
    set(gca, 'ytick', 1:num_image, 'yticklabel', fig_labels)
    set(gca, 'FontSize', FONT_SIZE);
    set(gca,'xaxisLocation','top')
    xticklabel_rotate(1:num_image, 90, fig_labels);
fprintf('Saving elongation model figure...\n')
fp = [DIR_SAVE FILENAME_SAVE FILETYPE_IMAGE];
fprintf('Filepath: %s\n', fp);
imwrite(frame2im(getframe(fig)), fp);
close(fig)

%% Save Model
fprintf('\nSaving elongation model...\n')
fp = [DIR_SAVE FILENAME_SAVE '.mat'];
fprintf('Filepath: %s\n', fp);
save(fp, 'elongation_model');

%% Do Collapse
if any(image_is_collapse)
    fprintf('\nCollapsing images...\n')
    
    %zero the diag
    elongation_model_nodiag = elongation_model;
    elongation_model_nodiag([1:num_image] + [0:num_image:(num_image * (num_image-1))]) = nan;
    
    %init
    elongation_model_collapsed = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    
    %populate
    for p1 = 1:p.NUMBER_OF_CONDITIONS
        ind_p1 = find(image_pred_value == p1);
        
        for p2 = (p1):p.NUMBER_OF_CONDITIONS
            ind_p2 = find(image_pred_value == p2);
            
            values = elongation_model_nodiag(ind_p1, ind_p2);
            value = nanmean(values(:));
            
            %if all values are nan then it was same images, set +1
            if isnan(value)
                value = +1; 
            end
            
            elongation_model_collapsed(p1, p2) = value;
            elongation_model_collapsed(p2, p1) = value;
        end
    end
    
%% Collapsed Model Figure
    fig = figure('Position', [1 1 1200 1000]);
    fprintf('\nCreating collapsed elongation model figure...\n')
        clf
        imagesc(elongation_model_collapsed)
        axis image
        colormap jet
        colorbar
        caxis([0 1])
        fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false);
        set(gca, 'ytick', 1:p.NUMBER_OF_CONDITIONS, 'yticklabel', fig_labels)
        set(gca, 'FontSize', FONT_SIZE);
        set(gca,'xaxisLocation','top')
        xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS, 90, fig_labels);
    fprintf('Saving collapsed edge count model figure...\n')
    fp = [DIR_SAVE FILENAME_SAVE '_collapsed' FILETYPE_IMAGE];
    fprintf('Filepath: %s\n', fp);
    imwrite(frame2im(getframe(fig)), fp);
    close(fig)
    
%% Save Collapsed Model
    fprintf('\nSaving collapsed elongation model...\n')
    fp = [DIR_SAVE FILENAME_SAVE '_collapsed' '.mat'];
    fprintf('Filepath: %s\n', fp);
    save(fp, 'elongation_model_collapsed');
    
end

%% DOne
fprintf('\nComplete!\n')