function generate_colour_average_model

%% Parameters

DIR_SAVE = pwd;
FILENAME_SAVE = 'colour average_model';
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

%% Mean Colours
fprintf('\nCalculating average colours...\n')
for rgb = 1:3
    image_rgb = cellfun(@(x) x(:,:,rgb), images, 'UniformOutput', false);
    colour_average(:,rgb) = cellfun(@(x,y) mean(x(y))/255, image_rgb, images_binary);
end

%% 
fprintf('\nCreating image of average colours...\n')
fig = figure('Position', [1 1 1200 1000]);
num_col = ceil(sqrt(num_image));
if (num_col * (num_col-1)) >= num_image
    num_row = num_col - 1;
else
    num_row = num_col;
end
for i = 1:num_image
    subplot(num_row, num_col, i);
    hold on
    imshow(images{i})
    rectangle('Position',[0 0 size(images{i},1)/3 size(images{i},2)/3],'FaceColor',colour_average(i,:),'EdgeColor',colour_average(i,:))
    hold off
    axis image
end
fp = [DIR_SAVE FILENAME_SAVE '_perImage' FILETYPE_IMAGE];
imwrite(frame2im(getframe(fig)), fp);

%% Difference Match
colour_average_diff_matrix = squareform(pdist(colour_average));

%% Simmilarity Model
colour_average_model = (colour_average_diff_matrix / -max(colour_average_diff_matrix(:))) + 1;

%% Model Figure
fprintf('\nCreating colour average model figure...\n')
    clf
    imagesc(colour_average_model)
    axis image
    colormap jet
    colorbar
    caxis([0 1])
    fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES(image_pred_value), 'UniformOutput', false);
    set(gca, 'ytick', 1:num_image, 'yticklabel', fig_labels)
    set(gca, 'FontSize', FONT_SIZE);
    set(gca,'xaxisLocation','top')
    xticklabel_rotate(1:num_image, 90, fig_labels);
fprintf('Saving colour average model figure...\n')
fp = [DIR_SAVE FILENAME_SAVE FILETYPE_IMAGE];
fprintf('Filepath: %s\n', fp);
imwrite(frame2im(getframe(fig)), fp);
close(fig)

%% Save Model
fprintf('\nSaving colour average model...\n')
fp = [DIR_SAVE FILENAME_SAVE '.mat'];
fprintf('Filepath: %s\n', fp);
save(fp, 'colour_average_model');

%% Do Collapse
if any(image_is_collapse)
    fprintf('\nCollapsing images...\n')
    
    %zero the diag
    colour_average_model_nodiag = colour_average_model;
    colour_average_model_nodiag([1:num_image] + [0:num_image:(num_image * (num_image-1))]) = nan;
    
    %init
    colour_average_model_collapsed = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    
    %populate
    for p1 = 1:p.NUMBER_OF_CONDITIONS
        ind_p1 = find(image_pred_value == p1);
        
        for p2 = (p1):p.NUMBER_OF_CONDITIONS
            ind_p2 = find(image_pred_value == p2);
            
            values = colour_average_model_nodiag(ind_p1, ind_p2);
            value = nanmean(values(:));
            
            %if all values are nan then it was same images, set +1
            if isnan(value)
                value = +1; 
            end
            
            colour_average_model_collapsed(p1, p2) = value;
            colour_average_model_collapsed(p2, p1) = value;
        end
    end
    
%% Collapsed Model Figure
    fig = figure('Position', [1 1 1200 1000]);
    fprintf('\nCreating collapsed colour average model figure...\n')
        clf
        imagesc(colour_average_model_collapsed)
        axis image
        colormap jet
        colorbar
        caxis([0 1])
        fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false);
        set(gca, 'ytick', 1:p.NUMBER_OF_CONDITIONS, 'yticklabel', fig_labels)
        set(gca, 'FontSize', FONT_SIZE);
        set(gca,'xaxisLocation','top')
        xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS, 90, fig_labels);
    fprintf('Saving collapsed colour average model figure...\n')
    fp = [DIR_SAVE FILENAME_SAVE '_collapsed' FILETYPE_IMAGE];
    fprintf('Filepath: %s\n', fp);
    imwrite(frame2im(getframe(fig)), fp);
    close(fig)
    
%% Save Collapsed Model
    fprintf('\nSaving collapsed colour average model...\n')
    fp = [DIR_SAVE FILENAME_SAVE '_collapsed' '.mat'];
    fprintf('Filepath: %s\n', fp);
    save(fp, 'colour_average_model_collapsed');
    
end

%% DOne
fprintf('\nComplete!\n')