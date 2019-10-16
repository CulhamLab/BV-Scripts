function generate_colour_profile_model

%% Parameters

DIR_SAVE = pwd;
DIR_SAVE_INDIV = [pwd filesep 'ColourProfiles' filesep];

FILENAME_SAVE = 'colour_profile_model';
FILETYPE_IMAGE = '.png';

FONT_SIZE = 6;

NUMBER_RGB_VALUES = 4; %total number of colours is NUMBER_RGB_VALUES^3

CREATE_INDIV = true;

%for binarizing
BACKGROUND_COLOUR = [255 255 255];
BACKGROUND_COLOUR_THRESHOLD = 5;

%% Check
if DIR_SAVE(end) ~= filesep
    DIR_SAVE(end+1) = filesep;
end
if DIR_SAVE_INDIV(end) ~= filesep
    DIR_SAVE_INDIV(end+1) = filesep;
end

if CREATE_INDIV && ~exist(DIR_SAVE_INDIV, 'dir')
    mkdir(DIR_SAVE_INDIV);
end

%% Load
fprintf('\nLoading images...\n')
[images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images;
num_image = length(images);

%% Binarize Images (for foreground)
fprintf('\nBinarizing images...\n')
images_binary = cellfun(@(x) mean(abs(single(x) - repmat(reshape(BACKGROUND_COLOUR,[1 1 3]), [size(x,1) size(x,2) 1])), 3) > BACKGROUND_COLOUR_THRESHOLD, images, 'UniformOutput', false);

%% Colour Map
fprintf('\nCreating colour map...\n')
number_colours = NUMBER_RGB_VALUES^3;
colour_map = nan(number_colours,3);
colour_stepsize = 256/NUMBER_RGB_VALUES;
colour_stepsize_half = colour_stepsize / 2;
for r = colour_stepsize-1:colour_stepsize:255
    for g = colour_stepsize-1:colour_stepsize:255
        for b = colour_stepsize-1:colour_stepsize:255
            
            vr = floor(r / colour_stepsize);
            vg = floor(g / colour_stepsize);
            vb = floor(b / colour_stepsize);
            ind = 1 + vr + (vg*NUMBER_RGB_VALUES) + (vb*(NUMBER_RGB_VALUES^2));
            
            colour_map(ind,:) = [r g b] / 255;
        end
    end
end
if any(isnan(colour_map(:))) || (size(colour_map,1)~=number_colours)
    error('colour map issue')
end

%% Reduce Image Colours
fprintf('\nReducing image colours...\n')
for i = 1:num_image
    img = single(images{i});
    
    vr = floor(img(:,:,1) / colour_stepsize);
    vg = floor(img(:,:,2) / colour_stepsize);
    vb = floor(img(:,:,3) / colour_stepsize);
    
    images_reduced{i} = 1 + vr + (vg*NUMBER_RGB_VALUES) + (vb*(NUMBER_RGB_VALUES^2));
end

%% Calculate Colour Profiles
fprintf('\nCalculating colour profiles...\n')
colour_profile_foreground = cell2mat(cellfun(@(x,y) hist(x(y),1:number_colours)', images_reduced, images_binary, 'UniformOutput', false));
colour_profile_all = cell2mat(cellfun(@(x) hist(x(:),1:number_colours)', images_reduced, 'UniformOutput', false));

%% Figure

%% Create Indiv Figures
if CREATE_INDIV
    fprintf('\nCreating individual figures...\n')
    fig = figure('Position',get(0,'screensize'));
    for i = 1:num_image
        clf
        subplot(2,3,1)
        imshow(images{i});
        title(strrep(image_names{i},'_',' '))
        
        subplot(2,3,4)
        imagesc(images_reduced{i});
        axis image
        axis off
        colormap(colour_map);
        caxis([1 number_colours])
        title('Reduced Colours')
        
        subplot(2,3,[2 3])
        b = bar(colour_profile_foreground(:,i),'FaceColor','flat');
        b.CData = colour_map;
        title('Colour Profile (foreground)')
        xlabel('Colour')
        ylabel('Number Pixels')
        
        subplot(2,3,[5 6])
        b = bar(colour_profile_all(:,i),'FaceColor','flat');
        b.CData = colour_map;
        title('Colour Profile (all pixels)')
        xlabel('Colour')
        ylabel('Number Pixels')
        
        imwrite(frame2im(getframe(fig)), [DIR_SAVE_INDIV image_names{i} FILETYPE_IMAGE]);
    end
    close(fig)
end

%% All Pixels
GenerateModel('colour profile (all pixels)', colour_profile_all, p, DIR_SAVE, [FILENAME_SAVE '_all'], FILETYPE_IMAGE, image_is_collapse, image_pred_value, num_image, FONT_SIZE);

%% Foreground
GenerateModel('colour profile (foreground)', colour_profile_foreground, p, DIR_SAVE, [FILENAME_SAVE '_foreground'], FILETYPE_IMAGE, image_is_collapse, image_pred_value, num_image, FONT_SIZE);

%% Done
fprintf('\nComplete!\n')



function GenerateModel(text, values, p, DIR_SAVE, FILENAME_SAVE, FILETYPE_IMAGE, image_is_collapse, image_pred_value, num_image, FONT_SIZE)

%% Simmilarity Model
model = corr(values, 'Type', 'Spearman');
model = model - min(model(:));
model = model / max(model(:));

%% Figure
fig = figure('Position',get(0,'screensize'));

%% Model Figure
fprintf('\nCreating %s model figure...\n', text)
    clf
    imagesc(model)
    axis image
    colormap jet
    colorbar
    caxis([0 1])
    fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES(image_pred_value), 'UniformOutput', false);
    set(gca, 'ytick', 1:num_image, 'yticklabel', fig_labels)
    set(gca, 'FontSize', FONT_SIZE);
    set(gca,'xaxisLocation','top')
    xticklabel_rotate(1:num_image, 90, fig_labels);
fprintf('Saving %s model figure...\n', text)
fp = [DIR_SAVE FILENAME_SAVE FILETYPE_IMAGE];
fprintf('Filepath: %s\n', fp);
imwrite(frame2im(getframe(fig)), fp);
close(fig)

%% Save Model
fprintf('\nSaving %s model...\n', text)
fp = [DIR_SAVE FILENAME_SAVE '.mat'];
fprintf('Filepath: %s\n', fp);

eval(sprintf('%s = model;', FILENAME_SAVE))
eval(sprintf('save(fp, ''%s'');', FILENAME_SAVE))

%% Do Collapse
if any(image_is_collapse)
    fprintf('\nCollapsing images...\n')
    
    %zero the diag
    model_nodiag = model;
    model_nodiag([1:num_image] + [0:num_image:(num_image * (num_image-1))]) = nan;
    
    %init
    model_collapsed = nan(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    
    %populate
    for p1 = 1:p.NUMBER_OF_CONDITIONS
        ind_p1 = find(image_pred_value == p1);
        
        for p2 = (p1):p.NUMBER_OF_CONDITIONS
            ind_p2 = find(image_pred_value == p2);
            
            values = model_nodiag(ind_p1, ind_p2);
            value = nanmean(values(:));
            
            %if all values are nan then it was same images, set +1
            if isnan(value)
                value = +1; 
            end
            
            model_collapsed(p1, p2) = value;
            model_collapsed(p2, p1) = value;
        end
    end
    
%% Collapsed Model Figure
    fig = figure('Position',get(0,'screensize'));
    fprintf('\nCreating collapsed %s model figure...\n', text)
        clf
        imagesc(model_collapsed)
        axis image
        colormap jet
        colorbar
        caxis([0 1])
        fig_labels = cellfun(@(x) strrep(x,'_',' '), p.CONDITIONS.DISPLAY_NAMES, 'UniformOutput', false);
        set(gca, 'ytick', 1:p.NUMBER_OF_CONDITIONS, 'yticklabel', fig_labels)
        set(gca, 'FontSize', FONT_SIZE);
        set(gca,'xaxisLocation','top')
        xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS, 90, fig_labels);
    fprintf('Saving collapsed %s model figure...\n', text)
    fp = [DIR_SAVE FILENAME_SAVE '_collapsed' FILETYPE_IMAGE];
    fprintf('Filepath: %s\n', fp);
    imwrite(frame2im(getframe(fig)), fp);
    close(fig)
    
%% Save Collapsed Model
    fprintf('\nSaving collapsed %s model...\n', text)
    fp = [DIR_SAVE FILENAME_SAVE '_collapsed' '.mat'];
    fprintf('Filepath: %s\n', fp);

    eval(sprintf('%s = model_collapsed;', [FILENAME_SAVE '_collapsed']))
    eval(sprintf('save(fp, ''%s'');', [FILENAME_SAVE '_collapsed']))
    
end
    