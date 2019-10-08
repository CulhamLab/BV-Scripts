function generate_pixelcount_model

%% Parameters

DIR_SAVE = pwd;
FILENAME_SAVE = 'pixel_count_model';
FILETYPE_IMAGE = '.png';

FONT_SIZE = 6;

%for binarizing
BACKGROUND_COLOUR = [255 255 255];
BACKGROUND_COLOUR_THRESHOLD = 5;

%% Check
if DIR_SAVE(end) ~= filesep
    DIR_SAVE(end+1) = filesep;
end

%% Load
fprintf('\nLoading images...\n')
[images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images;
num_image = length(images);

%% Binarize Images
fprintf('\nBinarizing images...\n')
images_binary = cellfun(@(x) mean(abs(single(x) - repmat(reshape(BACKGROUND_COLOUR,[1 1 3]), [size(x,1) size(x,2) 1])), 3) > BACKGROUND_COLOUR_THRESHOLD, images, 'UniformOutput', false);

%% PixelCount Values
pixel_counts = cellfun(@(x) sum(x(:)), images_binary);

%% Difference Match
pixel_count_diff_matrix = squareform(pdist(pixel_counts'));

%% Simmilarity Model
pixel_count_model = (pixel_count_diff_matrix / -max(pixel_count_diff_matrix(:))) + 1;

%% Model Figure
fig = figure('Position', [1 1 1200 1000]);
fprintf('\nCreating pixel count model figure...\n')
    clf
    imagesc(pixel_count_model)
    axis image
    colormap jet
    colorbar
    caxis([0 1])
    fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES(image_pred_value), 'UniformOutput', false);
    set(gca, 'ytick', 1:num_image, 'yticklabel', fig_labels)
    set(gca, 'FontSize', FONT_SIZE);
    set(gca,'xaxisLocation','top')
    xticklabel_rotate(1:num_image, 90, fig_labels);
fprintf('Saving pixel count model figure...\n')
fp = [DIR_SAVE FILENAME_SAVE FILETYPE_IMAGE];
fprintf('Filepath: %s\n', fp);
imwrite(frame2im(getframe(fig)), fp);
close(fig)

%% Save Model
fprintf('\nSaving pixel count model...\n')
fp = [DIR_SAVE FILENAME_SAVE '.mat'];
fprintf('Filepath: %s\n', fp);
save(fp, 'pixel_count_model');

%% Do Collapse
if any(image_is_collapse)
    fprintf('\nCollapsing images...\n')
    
    %zero the diag
    pixel_count_model_nodiag = pixel_count_model;
    pixel_count_model_nodiag([1:num_image] + [0:num_image:(num_image * (num_image-1))]) = nan;
    
    %init
    pixel_count_model_collapsed = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    
    %populate
    for p1 = 1:p.NUMBER_OF_CONDITIONS
        ind_p1 = find(image_pred_value == p1);
        
        for p2 = (p1):p.NUMBER_OF_CONDITIONS
            ind_p2 = find(image_pred_value == p2);
            
            values = pixel_count_model_nodiag(ind_p1, ind_p2);
            value = nanmean(values(:));
            
            %if all values are nan then it was same images, set +1
            if isnan(value)
                value = +1; 
            end
            
            pixel_count_model_collapsed(p1, p2) = value;
            pixel_count_model_collapsed(p2, p1) = value;
        end
    end
    
%% Collapsed Model Figure
    fig = figure('Position', [1 1 1200 1000]);
    fprintf('\nCreating collapsed pixel count model figure...\n')
        clf
        imagesc(pixel_count_model_collapsed)
        axis image
        colormap jet
        colorbar
        caxis([0 1])
        fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false);
        set(gca, 'ytick', 1:p.NUMBER_OF_CONDITIONS, 'yticklabel', fig_labels)
        set(gca, 'FontSize', FONT_SIZE);
        set(gca,'xaxisLocation','top')
        xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS, 90, fig_labels);
    fprintf('Saving collapsed pixel count model figure...\n')
    fp = [DIR_SAVE FILENAME_SAVE '_collapsed' FILETYPE_IMAGE];
    fprintf('Filepath: %s\n', fp);
    imwrite(frame2im(getframe(fig)), fp);
    close(fig)
    
%% Save Collapsed Model
    fprintf('\nSaving collapsed pixel count model...\n')
    fp = [DIR_SAVE FILENAME_SAVE '_collapsed' '.mat'];
    fprintf('Filepath: %s\n', fp);
    save(fp, 'pixel_count_model_collapsed');
    
end

%% DOne
fprintf('\nComplete!\n')