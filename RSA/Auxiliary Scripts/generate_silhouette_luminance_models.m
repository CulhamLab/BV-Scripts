function generate_silhouette_luminance_models

%% Parameters

BACKGROUND_COLOUR = [255 255 255];
BACKGROUND_COLOUR_THRESHOLD = 5;

FILEPATH_OUTPUT_SELECTIONS = 'silhouette_foreground.png';
FILEPATH_OUTPUT_SELECTIONS_SUM = 'silhouette_foreground_summation.png';
FILEPATH_OUTPUT_SELECTIONS_PIXELS = 'silhouette_foreground_selection.png';

FILEPATH_OUTPUT_SILHOUETTES = 'silhouettes.png';
FILEPATH_OUTPUT_SILHOUETTE_MODEL_FIGURE = 'silhouette_model.png';
FILEPATH_OUTPUT_SILHOUETTE_MODEL_MAT = 'silhouette_model.mat';
FILEPATH_OUTPUT_SILHOUETTE_MODEL_FIGURE_COLLAPSED = 'silhouette_model_collapsed.png';
FILEPATH_OUTPUT_SILHOUETTE_MODEL_MAT_COLLAPSED = 'silhouette_model_collapsed.mat';

FILEPATH_OUTPUT_LUMINANCES = 'luminances.png';
FILEPATH_OUTPUT_LUMINANCE_MODEL_FIGURE = 'luminance_model.png';
FILEPATH_OUTPUT_LUMINANCE_MODEL_MAT = 'luminance_model.mat';
FILEPATH_OUTPUT_LUMINANCE_MODEL_FIGURE_COLLAPSED = 'luminance_model_collapsed.png';
FILEPATH_OUTPUT_LUMINANCE_MODEL_MAT_COLLAPSED = 'luminance_model_collapsed.mat';

FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_FIGURE = 'mean_luminance_all_model.png';
FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_MAT = 'mean_luminance_all_model.mat';
FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_FIGURE_COLLAPSED = 'mean_luminance_all_collapsed.png';
FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_MAT_COLLAPSED = 'mean_luminance_all_collapsed.mat';

FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_FIGURE = 'mean_luminance_foreground_model.png';
FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_MAT = 'mean_luminance_foreground_model.mat';
FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_FIGURE_COLLAPSED = 'mean_luminance_foreground_collapsed.png';
FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_MAT_COLLAPSED = 'mean_luminance_foreground_collapsed.mat';


APPROX_LUMINANCE_VALUES = reshape([0.299 0.587 0.114], [1 1 3]); %must be 1x1x3
MAX_LUMINANCE = sum(APPROX_LUMINANCE_VALUES);

FONT_SIZE = 6;

MODEL_COLOUR_RANGE = nan; %set nan to use dynamic range, else set [min max], these are r-values so the widest range is [-1 +1]

%% Prepare Images

%load images
fprintf('\nLoading images...\n')
[images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images;

%binarize images
fprintf('\nProcessing images...\n')
num_image = length(images);
num_row = floor(max(sqrt(num_image), 1));
num_col = ceil(max(sqrt(num_image), 1)) + 1;
fig = figure('Position', [1 1 (200*num_col) (200*num_row)]);
for i = 1:num_image
    image = images{i};
    sz = size(image);
    background_diff = mean(abs(single(image) - repmat(reshape(BACKGROUND_COLOUR,[1 1 3]), [sz(1:2) 1])), 3);
    background(:,:,i) = background_diff <= BACKGROUND_COLOUR_THRESHOLD;
    subplot(num_row, num_col, i)
    imagesc(background(:,:,i))
    colormap bone
    axis image
    axis off
    
    if image_is_collapse(i)
        name = image_names{i};
    else
        name = p.CONDITIONS.DISPLAY_NAMES{image_pred_value(i)};
    end
    
    title(strrep(name,'_',' '))
    set(gca, 'FontSize', FONT_SIZE);
end

%save
fprintf('\nSaving foreground selections...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SELECTIONS);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_SELECTIONS);
close(fig);

%% Create silhoueete model

%sum foregrounds to see which pixels are used
fig = figure('Position', [1 1 1000 1000]);
fprintf('\nForeground summation...\n')
foregound_sum = sum(~background, 3);
imagesc(foregound_sum);
axis image
axis off
colorbar
title('Foreground Summation')
fprintf('\nSaving foreground summation...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SELECTIONS_SUM);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_SELECTIONS_SUM);

%select pixels to use
fprintf('\nSelecting pixels...\n')
pixels_use = foregound_sum > 0;
imagesc(~pixels_use);
axis image
axis off
colormap bone
title('Pixel Selection')
fprintf('\nSaving pixel selection...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SELECTIONS_PIXELS);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_SELECTIONS_PIXELS);

close(fig);

%calculate silhouettes
fprintf('\nCalculate silhouettes...\n')
fig = figure('Position', [1 1 (200*num_col) (200*num_row)]);
silhouettes = false(sum(pixels_use(:)), num_image);
for i = 1:num_image
    %for output fig
    image = 1 - single(~background(:,:,i));
    image(pixels_use & image) = 0.5;
    subplot(num_row, num_col, i)
    imshow(image)
    colormap bone
    axis image
    axis off
    
    if image_is_collapse(i)
        name = image_names{i};
    else
        name = p.CONDITIONS.DISPLAY_NAMES{image_pred_value(i)};
    end
    
    title(strrep(name,'_',' '))
    set(gca, 'FontSize', FONT_SIZE);
    
    %actual silhouette
    foreground = ~background(:,:,i);
    silhouettes(:,i) = foreground(pixels_use);
end
fprintf('\nSaving silhouettes...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SILHOUETTES);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_SILHOUETTES);
close(fig)

%correlate
fprintf('\nCalculate silhouette model...\n')
silhouette_model = corr(silhouettes,'type', 'Spearman');
fprintf('\nSaving silhouette model...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SILHOUETTE_MODEL_MAT);
save(FILEPATH_OUTPUT_SILHOUETTE_MODEL_MAT, 'silhouette_model');

%silhoueete model figure
fprintf('\nCreate silhouette model figure...\n')
fig = figure('Position', [1 1 1200 1000]);
    imagesc(silhouette_model)
    axis image
    colormap jet
    colorbar
    if ~any(isnan(MODEL_COLOUR_RANGE))
        caxis([-1 +1])
    end
    fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES(image_pred_value), 'UniformOutput', false);
    set(gca, 'ytick', 1:num_image, 'yticklabel', fig_labels)
    set(gca, 'FontSize', FONT_SIZE);
    set(gca,'xaxisLocation','top')
    xticklabel_rotate(1:num_image, 90, fig_labels);
fprintf('\nSaving silhouette model figure...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SILHOUETTE_MODEL_FIGURE);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_SILHOUETTE_MODEL_FIGURE);

%collapse
if any(image_is_collapse)
    fprintf('\nCollapsing images...\n')
    silhouette_model_nodiag = silhouette_model;
    silhouette_model_nodiag([1:num_image] + [0:num_image:(num_image * (num_image-1))]) = nan;
    
    silhouette_model_collapsed = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    
    for p1 = 1:p.NUMBER_OF_CONDITIONS
        ind_p1 = find(image_pred_value == p1);
        
        for p2 = (p1):p.NUMBER_OF_CONDITIONS
            ind_p2 = find(image_pred_value == p2);
            
            values = silhouette_model_nodiag(ind_p1, ind_p2);
            value = nanmean(values(:));
            
            %if all values are nan then it was same images, set +1
            if isnan(value)
                value = +1; 
            end
            
            silhouette_model_collapsed(p1, p2) = value;
            silhouette_model_collapsed(p2, p1) = value;
        end
    end
    
    %collapsed silhoueete model figure
    fprintf('\nCreate collapsed silhouette model figure...\n')
        clf
        imagesc(silhouette_model_collapsed)
        axis image
        colormap jet
        colorbar
        if ~any(isnan(MODEL_COLOUR_RANGE))
            caxis([-1 +1])
        end
        fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false);
        set(gca, 'ytick', 1:p.NUMBER_OF_CONDITIONS, 'yticklabel', fig_labels)
        set(gca, 'FontSize', FONT_SIZE);
        set(gca,'xaxisLocation','top')
        xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS, 90, fig_labels);
    fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SILHOUETTE_MODEL_FIGURE_COLLAPSED);
    imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_SILHOUETTE_MODEL_FIGURE_COLLAPSED);
    
    %save model
    fprintf('\nSaving collapsed silhouette model...\n')
    fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SILHOUETTE_MODEL_MAT_COLLAPSED);
    save(FILEPATH_OUTPUT_SILHOUETTE_MODEL_MAT_COLLAPSED, 'silhouette_model_collapsed');
    
end

close(fig)

%% luminance model

%Calculate approx luminance
fprintf('\nCalculate approx luminance...\n')
fig = figure('Position', [1 1 (500*num_col) (500*num_row)]);
luminances = nan(sum(pixels_use(:)), num_image);
for i = 1:num_image
    image = images{i};
    sz = size(image);
    
    luminance = sqrt(sum(  ((single(image)/255).^ 2) .* repmat(APPROX_LUMINANCE_VALUES, [sz(1:2) 1])  , 3));
    luminance(~pixels_use) = nan;
       
    subplot(num_row, num_col, i)
    imagesc(luminance)
    axis image
    axis off
    colorbar
    caxis([-0.01 MAX_LUMINANCE])
    colormap bone %colormap([0 0 0; parula(100)])
    
    if image_is_collapse(i)
        name = image_names{i};
    else
        name = p.CONDITIONS.DISPLAY_NAMES{image_pred_value(i)};
    end
    
    title(strrep(name,'_',' '))
    set(gca, 'FontSize', FONT_SIZE);
    
    luminances(:,i) = luminance(pixels_use);
end
fprintf('\nSaving luminances...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_LUMINANCES);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_LUMINANCES);
close(fig)

%correlate
fprintf('\nCalculate luminance model...\n')
luminance_model = corr(luminances,'type', 'Spearman');
fprintf('\nSaving luminance model...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_LUMINANCE_MODEL_MAT);
save(FILEPATH_OUTPUT_LUMINANCE_MODEL_MAT, 'luminance_model');

%luminance model figure
fprintf('\nCreate luminance model figure...\n')
fig = figure('Position', [1 1 1200 1000]);
    imagesc(luminance_model)
    axis image
    colormap jet
    colorbar
    if ~any(isnan(MODEL_COLOUR_RANGE))
        caxis([-1 +1])
    end
    fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES(image_pred_value), 'UniformOutput', false);
    set(gca, 'ytick', 1:num_image, 'yticklabel', fig_labels)
    set(gca, 'FontSize', FONT_SIZE);
    set(gca,'xaxisLocation','top')
    xticklabel_rotate(1:num_image, 90, fig_labels);
fprintf('\nSaving luminance model figure...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_LUMINANCE_MODEL_FIGURE);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_LUMINANCE_MODEL_FIGURE);

%collapse
if any(image_is_collapse)
    fprintf('\nCollapsing images...\n')
    luminance_model_nodiag = luminance_model;
    luminance_model_nodiag([1:num_image] + [0:num_image:(num_image * (num_image-1))]) = nan;
    
    luminance_model_collapsed = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    
    for p1 = 1:p.NUMBER_OF_CONDITIONS
        ind_p1 = find(image_pred_value == p1);
        
        for p2 = (p1):p.NUMBER_OF_CONDITIONS
            ind_p2 = find(image_pred_value == p2);
            
            values = luminance_model_nodiag(ind_p1, ind_p2);
            value = nanmean(values(:));
            
            %if all values are nan then it was same images, set +1
            if isnan(value)
                value = +1; 
            end
            
            luminance_model_collapsed(p1, p2) = value;
            luminance_model_collapsed(p2, p1) = value;
        end
    end
    
    %collapsed luminance model figure
    fprintf('\nCreate collapsed luminance model figure...\n')
        clf
        imagesc(luminance_model_collapsed)
        axis image
        colormap jet
        colorbar
        if ~any(isnan(MODEL_COLOUR_RANGE))
            caxis([-1 +1])
        end
        fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false);
        set(gca, 'ytick', 1:p.NUMBER_OF_CONDITIONS, 'yticklabel', fig_labels)
        set(gca, 'FontSize', FONT_SIZE);
        set(gca,'xaxisLocation','top')
        xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS, 90, fig_labels);
    fprintf('Filepath: %s\n', FILEPATH_OUTPUT_LUMINANCE_MODEL_FIGURE_COLLAPSED);
    imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_LUMINANCE_MODEL_FIGURE_COLLAPSED);
    
    %save model
    fprintf('\nSaving collapsed luminance model...\n')
    fprintf('Filepath: %s\n', FILEPATH_OUTPUT_LUMINANCE_MODEL_MAT_COLLAPSED);
    save(FILEPATH_OUTPUT_LUMINANCE_MODEL_MAT_COLLAPSED, 'luminance_model_collapsed');
    
end

close(fig)

%% mean luminance models

%Calculate approx luminance
fprintf('\nCalculate approx mean luminances...\n')
mean_luminance_all = nan(num_image, 1);
mean_luminance_foreground = nan(num_image, 1);
for i = 1:num_image
    %calculate approx pixel luminance
    image = images{i};
    sz = size(image);
    luminance = sqrt(sum(  ((single(image)/255).^ 2) .* repmat(APPROX_LUMINANCE_VALUES, [sz(1:2) 1])  , 3));
    
    %mean of all pixels
    mean_luminance_all(i) = mean(luminance(:));
    
    %mean of all foreground pixels
    luminance(background(:,:,i)) = nan;
    mean_luminance_foreground(i) = nanmean(luminance(:));
end

%create models
fprintf('\nCalculate mean luminance models...\n')
mean_luminance_all_model = squareform(pdist(mean_luminance_all));
mean_luminance_all_model = (mean_luminance_all_model / max(mean_luminance_all_model(:)) * -2) + 1;

mean_luminance_foreground_model = squareform(pdist(mean_luminance_foreground));
mean_luminance_foreground_model = (mean_luminance_foreground_model / max(mean_luminance_foreground_model(:)) * -2) + 1;

fprintf('\nSaving mean luminance (all) model...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_MAT);
save(FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_MAT, 'mean_luminance_all_model');

fprintf('\nSaving mean luminance (foreground) model...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_MAT);
save(FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_MAT, 'mean_luminance_foreground_model');

%start of figures
fig = figure('Position', [1 1 1200 1000]);

%mean luminance model (all) figure
fprintf('\nCreate mean luminance model (all) figure...\n')
    clf
    imagesc(mean_luminance_all_model)
    axis image
    colormap jet
    colorbar
    caxis([-1 +1])
    fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES(image_pred_value), 'UniformOutput', false);
    set(gca, 'ytick', 1:num_image, 'yticklabel', fig_labels)
    set(gca, 'FontSize', FONT_SIZE);
    set(gca,'xaxisLocation','top')
    xticklabel_rotate(1:num_image, 90, fig_labels);
fprintf('\nSaving mean luminance model (all) figure...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_FIGURE);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_FIGURE);

%mean luminance model (foreground) figure
fprintf('\nCreate mean luminance model (foreground) figure...\n')
    clf
    imagesc(mean_luminance_foreground_model)
    axis image
    colormap jet
    colorbar
    caxis([-1 +1])
    fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES(image_pred_value), 'UniformOutput', false);
    set(gca, 'ytick', 1:num_image, 'yticklabel', fig_labels)
    set(gca, 'FontSize', FONT_SIZE);
    set(gca,'xaxisLocation','top')
    xticklabel_rotate(1:num_image, 90, fig_labels);
fprintf('\nSaving mean luminance model (foreground) figure...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_FIGURE);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_FIGURE);

%collapse
if any(image_is_collapse)
    fprintf('\nCollapsing images...\n')
    
    mean_luminance_all_model_nodiag = mean_luminance_all_model;
    mean_luminance_all_model_nodiag([1:num_image] + [0:num_image:(num_image * (num_image-1))]) = nan;
    
    mean_luminance_all_model_collapsed = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    
    mean_luminance_foreground_model_nodiag = mean_luminance_foreground_model;
    mean_luminance_foreground_model_nodiag([1:num_image] + [0:num_image:(num_image * (num_image-1))]) = nan;
    
    mean_luminance_foreground_model_collapsed = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    
    for p1 = 1:p.NUMBER_OF_CONDITIONS
        ind_p1 = find(image_pred_value == p1);
        
        for p2 = (p1):p.NUMBER_OF_CONDITIONS
            ind_p2 = find(image_pred_value == p2);
            
            values = mean_luminance_all_model_nodiag(ind_p1, ind_p2);
            value = nanmean(values(:));
            
            %if all values are nan then it was same images, set +1
            if isnan(value)
                value = +1; 
            end
            
            mean_luminance_all_model_collapsed(p1, p2) = value;
            mean_luminance_all_model_collapsed(p2, p1) = value;
            
            
            
            values = mean_luminance_foreground_model_nodiag(ind_p1, ind_p2);
            value = nanmean(values(:));
            
            %if all values are nan then it was same images, set +1
            if isnan(value)
                value = +1; 
            end
            
            mean_luminance_foreground_model_collapsed(p1, p2) = value;
            mean_luminance_foreground_model_collapsed(p2, p1) = value;
        end
    end
    
    %save models
    fprintf('\nSaving collapsed mean luminance (all) model...\n')
    fprintf('Filepath: %s\n', FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_MAT_COLLAPSED);
    save(FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_MAT_COLLAPSED, 'mean_luminance_all_model_collapsed');
    
    fprintf('\nSaving collapsed mean luminance (foreground) model...\n')
    fprintf('Filepath: %s\n', FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_MAT_COLLAPSED);
    save(FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_MAT_COLLAPSED, 'mean_luminance_foreground_model_collapsed');
    
    %figures
    
    fprintf('\nCreate collapsed mean luminance model (all) figure...\n')
        clf
        imagesc(mean_luminance_all_model_collapsed)
        axis image
        colormap jet
        colorbar
        caxis([-1 +1])
        fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false);
        set(gca, 'ytick', 1:p.NUMBER_OF_CONDITIONS, 'yticklabel', fig_labels)
        set(gca, 'FontSize', FONT_SIZE);
        set(gca,'xaxisLocation','top')
        xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS, 90, fig_labels);
    fprintf('\nSaving collapsed mean luminance model (all) figure...\n')
    fprintf('Filepath: %s\n', FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_FIGURE_COLLAPSED);
    imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_MEAN_LUMINANCE_ALL_FIGURE_COLLAPSED);
    
    fprintf('\nCreate collapsed mean luminance model (foreground) figure...\n')
        clf
        imagesc(mean_luminance_foreground_model_collapsed)
        axis image
        colormap jet
        colorbar
        caxis([-1 +1])
        fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false);
        set(gca, 'ytick', 1:p.NUMBER_OF_CONDITIONS, 'yticklabel', fig_labels)
        set(gca, 'FontSize', FONT_SIZE);
        set(gca,'xaxisLocation','top')
        xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS, 90, fig_labels);
    fprintf('\nSaving collapsed mean luminance model (foreground) figure...\n')
    fprintf('Filepath: %s\n', FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_FIGURE_COLLAPSED);
    imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_MEAN_LUMINANCE_FOREGROUND_FIGURE_COLLAPSED);
    
end

close(fig)

%% Done
disp Done!