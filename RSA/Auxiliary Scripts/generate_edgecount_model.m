% function generate_edgecount_model
clear all

%% Parameters

DIR_SAVE = pwd;
FILENAME_SAVE = 'edge_count_model';
FILETYPE_IMAGE = '.png';

MAKE_EDGE_IMAGES = false;
DIR_EDGE_IMAGES = ['.' filesep 'EdgeImages' filesep];

%figure background colour
FIGURE_COLOUR_BACKGROUND = [255 255 255];

%edge method (sobel, prewitt, roberts, log, zerocross, canny, or approxcanny)
EDGE_METHOD = 'prewitt';

FONT_SIZE = 6;

%values for grayscale
APPROX_LUMINANCE_VALUES = [0.299 0.587 0.114];

%% Checks
EDGE_METHOD = lower(EDGE_METHOD);

if DIR_SAVE(end) ~= filesep
    DIR_SAVE(end+1) = filesep;
end
if DIR_EDGE_IMAGES(end) ~= filesep
    DIR_EDGE_IMAGES(end+1) = filesep;
end

if ~exist(DIR_SAVE, 'dir')
    mkdir(DIR_SAVE)
end

%% Load
fprintf('\nLoading images...\n')
[images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images;

%% Find Image Edges
images_grayscale = cellfun(@(x) uint8( single(x(:,:,1))*APPROX_LUMINANCE_VALUES(1) + single(x(:,:,2))*APPROX_LUMINANCE_VALUES(2) + single(x(:,:,3))*APPROX_LUMINANCE_VALUES(3) ) , images, 'UniformOutput', false);
images_edges = cellfun(@(x) edge(x,EDGE_METHOD), images_grayscale, 'UniformOutput', false);

%% Create figure of edges
num_image = length(images);
if MAKE_EDGE_IMAGES
    if ~exist(DIR_EDGE_IMAGES, 'dir'), mkdir(DIR_EDGE_IMAGES); end
    fig = figure('Position', [1 1 1500 500]);
    for i = 1:num_image
        subplot(1,3,1)
        imshow(images{i})

        subplot(1,3,2)
        imshow(images_grayscale{i})

        subplot(1,3,3)
        imshow(images_edges{i})

        suptitle([strrep(image_names{i},'_',' ') ' (' EDGE_METHOD ' method)'])
        saveas(fig, [DIR_EDGE_IMAGES EDGE_METHOD '_' image_names{i}], 'png')
    end
    close(fig)
end

%% Compute EdgeCount Values
edge_counts = cellfun(@(x) sum(x(:)), images_edges);

%% Compute EdgeCount Difference Match
edge_count_diff_matrix = squareform(pdist(edge_counts'));

%% Simmilarity Model
edge_count_model = (edge_count_diff_matrix / -max(edge_count_diff_matrix(:))) + 1;

%% Model Figure
fig = figure('Position', [1 1 1200 1000]);
fprintf('\nCreating edge count model figure...\n')
    clf
    imagesc(edge_count_model)
    axis image
    colormap jet
    colorbar
    caxis([0 1])
    fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES(image_pred_value), 'UniformOutput', false);
    set(gca, 'ytick', 1:num_image, 'yticklabel', fig_labels)
    set(gca, 'FontSize', FONT_SIZE);
    set(gca,'xaxisLocation','top')
    xticklabel_rotate(1:num_image, 90, fig_labels);
fprintf('Saving edge count model figure...\n')
fp = [DIR_SAVE FILENAME_SAVE FILETYPE_IMAGE];
fprintf('Filepath: %s\n', fp);
imwrite(frame2im(getframe(fig)), fp);
close(fig)

%% Save Model
fprintf('\nSaving edge count model...\n')
fp = [DIR_SAVE FILENAME_SAVE '.mat'];
fprintf('Filepath: %s\n', fp);
save(fp, 'edge_count_model');

%% Do Collapse
if any(image_is_collapse)
    fprintf('\nCollapsing images...\n')
    
    %zero the diag
    edge_count_model_nodiag = edge_count_model;
    edge_count_model_nodiag([1:num_image] + [0:num_image:(num_image * (num_image-1))]) = nan;
    
    %init
    edge_count_model_collapsed = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    
    %populate
    for p1 = 1:p.NUMBER_OF_CONDITIONS
        ind_p1 = find(image_pred_value == p1);
        
        for p2 = (p1):p.NUMBER_OF_CONDITIONS
            ind_p2 = find(image_pred_value == p2);
            
            values = edge_count_model_nodiag(ind_p1, ind_p2);
            value = nanmean(values(:));
            
            %if all values are nan then it was same images, set +1
            if isnan(value)
                value = +1; 
            end
            
            edge_count_model_collapsed(p1, p2) = value;
            edge_count_model_collapsed(p2, p1) = value;
        end
    end
    
%% Collapsed Model Figure
    fig = figure('Position', [1 1 1200 1000]);
    fprintf('\nCreating collapsed edge count model figure...\n')
        clf
        imagesc(edge_count_model_collapsed)
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
    fprintf('\nSaving collapsed edge count model...\n')
    fp = [DIR_SAVE FILENAME_SAVE '_collapsed' '.mat'];
    fprintf('Filepath: %s\n', fp);
    save(fp, 'edge_count_model_collapsed');
    
end

%% DOne
fprintf('\nComplete!\n')