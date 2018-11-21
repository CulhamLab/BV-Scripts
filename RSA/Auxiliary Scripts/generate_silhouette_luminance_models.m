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

FILEPATH_OUTPUT_LUMINANCES = 'luminances.png';
FILEPATH_OUTPUT_LUMINANCE_MODEL_FIGURE = 'luminance_model.png';
FILEPATH_OUTPUT_LUMINANCE_MODEL_MAT = 'luminance_model.mat';

APPROX_LUMINANCE_VALUES = reshape([0.299 0.587 0.114], [1 1 3]);
MAX_LUMINANCE = sqrt(sum( APPROX_LUMINANCE_VALUES .^ 2 ));

%% Prepare Images

%load images
fprintf('\nLoading images...\n')
[images, p] = load_predictor_images;

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
    title(strrep(p.CONDITIONS.DISPLAY_NAMES{i},'_',' '))
end

%save
fprintf('\nSaving foreground selections...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SELECTIONS);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_SELECTIONS);
close(fig);

%% Create silhoueete model

fig = figure('Position', [1 1 1000 1000]);

%sum foregrounds to see which pixels are used
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
    title(strrep(p.CONDITIONS.DISPLAY_NAMES{i},'_',' '))
    
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
fprintf('\nCalculate silhouette model figure...\n')
fig = figure('Position', [1 1 1200 1000]);
imagesc(silhouette_model);
axis image
colormap jet
colorbar
caxis([-1 +1])
set(gca, 'xtick', 1:num_image, 'xticklabel', cell(1,num_image))
set(gca, 'ytick', 1:num_image, 'yticklabel', cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false))
title('Silhouette Model')
fprintf('\nSaving silhouette model figure...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_SILHOUETTE_MODEL_FIGURE);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_SILHOUETTE_MODEL_FIGURE);
close(fig)

%% luminance model

save

%Calculate approx luminance
fprintf('\nCalculate approx luminance...\n')
fig = figure('Position', [1 1 (500*num_col) (500*num_row)]);
luminances = nan(sum(pixels_use(:)), num_image);
for i = 1:num_image
    image = images{i};
    sz = size(image);
    
    luminance = sqrt(sum(  ( single(image/255) .* repmat(APPROX_LUMINANCE_VALUES, [sz(1:2) 1]) ) .^ 2 , 3));
    luminance(~pixels_use) = nan;
       
    subplot(num_row, num_col, i)
    imagesc(luminance)
    axis image
    axis off
    colorbar
    caxis([-0.01 MAX_LUMINANCE])
    colormap([0 0 0; parula(100)])
    title(strrep(p.CONDITIONS.DISPLAY_NAMES{i},'_',' '))
    
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
fprintf('\nCalculate luminance model figure...\n')
fig = figure('Position', [1 1 1200 1000]);
imagesc(luminance_model);
axis image
colormap jet
colorbar
caxis([-1 +1])
set(gca, 'xtick', 1:num_image, 'xticklabel', cell(1,num_image))
set(gca, 'ytick', 1:num_image, 'yticklabel', cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false))
title('Luminance Model')
fprintf('\nSaving luminance model figure...\n')
fprintf('Filepath: %s\n', FILEPATH_OUTPUT_LUMINANCE_MODEL_FIGURE);
imwrite(frame2im(getframe(fig)), FILEPATH_OUTPUT_LUMINANCE_MODEL_FIGURE);
close(fig)

%% Done
disp Done!