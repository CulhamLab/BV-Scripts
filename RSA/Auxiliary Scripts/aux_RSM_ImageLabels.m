function aux_RSM_ImageLabels

%% Parameters

TRANSPARENT_COLOUR_BACKGROUND = [255 255 255]; %0-to-255, leave empty [] to set no background
TRANSPARENT_COLOUR_BACKGROUND_THRESHOLD = 15;

PIXEL_SIZE_RSM_CELLS = 50;
PIXEL_SIZE_LABELS = 150;
NUMBER_OFFSETS_LABELS = 4;

BACKGROUND_COLOUR = [1 1 1]; %0-to-1

FONT_SIZE = 20;

%colour bar's colormap and range are read from the main parameter file
COLOUR_BAR.DRAW = true;
COLOUR_BAR.SHOW_VALUES = true; %setting false removes all ticks (actual range is unchanged)
COLOUR_BAR.TICK_DISTANCE = []; %leave empty [] to use default
COLOUR_BAR.LABEL = 'Similarity'; %leave empty [] for no title

LABEL_LINES.DRAW = true;
LABEL_LINES.TYPE = '-';
LABEL_LINES.COLOUR = [0.8 0.8 0.8]; %0-to-1
LABEL_LINES.WIDTH = 1;

DIRECTORY_NAME_SAVE = 'aux_RSM_ImageLabels';

LABEL_POSITION_PERCENT = 0.5; %1=start, 0.5=middle, 0=end

DRAW_LINES_OVER_MATRIX = []; %leave empty to disable, else array of structures containing WHERE, COLOUR, STYLE, WIDTH

%%EXAMPLE:
% % % DRAW_LINES_OVER_MATRIX(1).WHERE = [24 30 45 60]; %draw after specified cells
% % % DRAW_LINES_OVER_MATRIX(1).COLOUR = [0 0 0]; %0-to-1
% % % DRAW_LINES_OVER_MATRIX(1).STYLE = '-'; %line style
% % % DRAW_LINES_OVER_MATRIX(1).WIDTH = 1; %line width
% % % 
% % % DRAW_LINES_OVER_MATRIX(2).WHERE = [6 12 15 18 21        27      33 36 39 42     48 51 54 57]; %draw after specified cells
% % % DRAW_LINES_OVER_MATRIX(2).COLOUR = [0 0 0]; %0-to-1
% % % DRAW_LINES_OVER_MATRIX(2).STYLE = ':'; %line style
% % % DRAW_LINES_OVER_MATRIX(2).WIDTH = 1; %line width

MAKE_MODEL_FIGUES = true;

%% Load
fprintf('\nLoading images...\n')
[images, p, image_names, image_pred_value, image_is_collapse] = load_predictor_images;

%% Output Directory
directory_save = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep DIRECTORY_NAME_SAVE filesep];
if ~exist(directory_save, 'dir')
    mkdir(directory_save);
end

%% Select Images
ind_image_select = arrayfun(@(x) find(image_pred_value==x,1,'first'), p.RSM_PREDICTOR_ORDER); %order by p.RSM_PREDICTOR_ORDER
images_select = images(ind_image_select);

%% Image Background
if isempty(TRANSPARENT_COLOUR_BACKGROUND)
    image_sizes = cellfun(@size, images_select, 'UniformOutput', false);
    images_select_bgd = cellfun(@(x) false(x(1),x(2)), image_sizes, 'UniformOutput', false);
else
    images_select_bgd = cellfun(@(x) mean(abs(single(x) - repmat(reshape(TRANSPARENT_COLOUR_BACKGROUND,[1 1 3]), [size(x,1) size(x,2) 1])), 3) > TRANSPARENT_COLOUR_BACKGROUND_THRESHOLD, images_select, 'UniformOutput', false);
end


%% Resize Images
images_select_max_dim = cellfun(@(x) max(size(x)), images_select, 'UniformOutput', false);
images_select_resized = cellfun(@(x,y) imresize(x,PIXEL_SIZE_LABELS/y), images_select, images_select_max_dim, 'UniformOutput', false);
images_select_bgd_resized = cellfun(@(x,y) imresize(x,PIXEL_SIZE_LABELS/y), images_select_bgd, images_select_max_dim, 'UniformOutput', false);

%% Load RSMs
try
    return_path = pwd;
    cd ..
    load([p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep 'VOI_RSMs.mat']);
    cd(return_path);
catch err
    cd(return_path);
    warning('Could not load VOI RSMs. Has VOI step6 been run or has data moved?')
    rethrow(err);
end

%% RSM Averaged Across Participants
mean_rsm_vois_split = squeeze(mean(data.RSM_split,3)); %Cond x Cond x VOI
mean_rsm_vois_nonsplit = squeeze(mean(data.RSM_nonsplit,3)); %Cond x Cond x VOI

%% Reorder to p.RSM_PREDICTOR_ORDER
mean_rsm_vois_split = mean_rsm_vois_split(p.RSM_PREDICTOR_ORDER, p.RSM_PREDICTOR_ORDER, :);
mean_rsm_vois_nonsplit = mean_rsm_vois_nonsplit(p.RSM_PREDICTOR_ORDER, p.RSM_PREDICTOR_ORDER, :);

%% Resize RSMs
mean_rsm_vois_split = imresize(mean_rsm_vois_split, PIXEL_SIZE_RSM_CELLS, 'Nearest');
mean_rsm_vois_nonsplit = imresize(mean_rsm_vois_nonsplit, PIXEL_SIZE_RSM_CELLS, 'Nearest');

%% Increase colormap precision
p.RSM_COLOURMAP = max(0,min(1,imresize(p.RSM_COLOURMAP, [1000 3])));

%% Plot
number_voi = length(data.VOInumVox);
fig = figure('Position', get(0,'ScreenSize'));
if MAKE_MODEL_FIGUES
    for mid = 1:length(p.MODELS.names)
        rsm = imresize(p.MODELS.matrices{mid}(p.RSM_PREDICTOR_ORDER,p.RSM_PREDICTOR_ORDER), PIXEL_SIZE_RSM_CELLS, 'Nearest');
        
        rsm = rsm - nanmin(rsm(:));
        rsm = rsm / nanmax(rsm(:));
        
        CreateImageRSM(p, PIXEL_SIZE_LABELS, PIXEL_SIZE_RSM_CELLS, NUMBER_OFFSETS_LABELS, LABEL_LINES, BACKGROUND_COLOUR, COLOUR_BAR, FONT_SIZE, LABEL_POSITION_PERCENT, DRAW_LINES_OVER_MATRIX, rsm, images_select_resized, images_select_bgd_resized, true);
        if any(isnan(rsm(:)))
            colormap([0 0 0; p.RSM_COLOURMAP]);
        else
            colormap(p.RSM_COLOURMAP);
        end
        caxis([nanmin(rsm(:))-(2/size(p.RSM_COLOURMAP,1)) nanmax(rsm(:))])
        set(fig, 'PaperPosition', [0 0 15 15]);
        saveas(fig, [directory_save 'MODEL_' p.MODELS.names{mid} '.png'], 'png');
        
    end
end
for vid = 1:number_voi
    CreateImageRSM(p, PIXEL_SIZE_LABELS, PIXEL_SIZE_RSM_CELLS, NUMBER_OFFSETS_LABELS, LABEL_LINES, BACKGROUND_COLOUR, COLOUR_BAR, FONT_SIZE, LABEL_POSITION_PERCENT, DRAW_LINES_OVER_MATRIX, mean_rsm_vois_split(:,:,vid), images_select_resized, images_select_bgd_resized, false);
    suptitle(strrep(data.VOINames{vid},'_',' '))
    set(fig, 'PaperPosition', [0 0 15 15]);
    saveas(fig, [directory_save 'SPLIT_' data.VOINames{vid} '.png'], 'png');
    
    CreateImageRSM(p, PIXEL_SIZE_LABELS, PIXEL_SIZE_RSM_CELLS, NUMBER_OFFSETS_LABELS, LABEL_LINES, BACKGROUND_COLOUR, COLOUR_BAR, FONT_SIZE, LABEL_POSITION_PERCENT, DRAW_LINES_OVER_MATRIX, mean_rsm_vois_nonsplit(:,:,vid), images_select_resized, images_select_bgd_resized, false);
    suptitle(strrep(data.VOINames{vid},'_',' '))
    set(fig, 'PaperPosition', [0 0 15 15]);
    saveas(fig, [directory_save 'NONSPLIT_' data.VOINames{vid} '.png'], 'png');
end
close(fig);

%% Done
disp Done.

function CreateImageRSM(p, PIXEL_SIZE_LABELS, PIXEL_SIZE_RSM_CELLS, NUMBER_OFFSETS_LABELS, LABEL_LINES, BACKGROUND_COLOUR, COLOUR_BAR, FONT_SIZE, LABEL_POSITION_PERCENT, DRAW_LINES_OVER_MATRIX, rsm, images, images_alpha, is_model)
%check size
rsm_size = size(rsm,1);

%clear
clf

%white background
set(gcf,'color',BACKGROUND_COLOUR);

%draw matrix
imagesc(rsm);
colormap(p.RSM_COLOURMAP)

%colour range
if ~is_model
    caxis(p.RSM_COLOUR_RANGE_COND);
end

%colour bar
if COLOUR_BAR.DRAW
    c = colorbar;
    
    if ~COLOUR_BAR.SHOW_VALUES
        set(c, 'ytick', []);
    elseif ~isempty(COLOUR_BAR.TICK_DISTANCE)
        set(c, 'ytick', p.RSM_COLOUR_RANGE_COND(1) : COLOUR_BAR.TICK_DISTANCE : p.RSM_COLOUR_RANGE_COND(2));
    end
    
    if ~isempty(COLOUR_BAR.LABEL)
        ylabel(c, COLOUR_BAR.LABEL);
    end
end

%measure images
image_sizes = cellfun(@size, images, 'UniformOutput', false);

hold on

%lines over matrix
for j = 1:length(DRAW_LINES_OVER_MATRIX)
    for k = DRAW_LINES_OVER_MATRIX(j).WHERE
        plot([0 rsm_size],[k k]*PIXEL_SIZE_RSM_CELLS, DRAW_LINES_OVER_MATRIX(j).STYLE, 'Color', DRAW_LINES_OVER_MATRIX(j).COLOUR, 'LineWidth', DRAW_LINES_OVER_MATRIX(j).WIDTH);
        plot([k k]*PIXEL_SIZE_RSM_CELLS,[0 rsm_size], DRAW_LINES_OVER_MATRIX(j).STYLE, 'Color', DRAW_LINES_OVER_MATRIX(j).COLOUR, 'LineWidth', DRAW_LINES_OVER_MATRIX(j).WIDTH);
    end
end

%draw lines?
if LABEL_LINES.DRAW
    for c = 1:p.NUMBER_OF_CONDITIONS
        x_center = (mod(c - 1, NUMBER_OFFSETS_LABELS) + 0.5) * -PIXEL_SIZE_LABELS;
        y_center = ((c-LABEL_POSITION_PERCENT) * PIXEL_SIZE_RSM_CELLS);
        
        plot([x_center 0],[y_center y_center],LABEL_LINES.TYPE,'Color',LABEL_LINES.COLOUR,'LineWidth',LABEL_LINES.WIDTH);
        plot([y_center y_center],[x_center 0],LABEL_LINES.TYPE,'Color',LABEL_LINES.COLOUR,'LineWidth',LABEL_LINES.WIDTH);
    end
end

%draw each image
for c = 1:p.NUMBER_OF_CONDITIONS
    x_center = (mod(c - 1, NUMBER_OFFSETS_LABELS) + 0.5) * -PIXEL_SIZE_LABELS;
    y_center = ((c-LABEL_POSITION_PERCENT) * PIXEL_SIZE_RSM_CELLS);
    
    x = x_center - image_sizes{c}(2)/2;
    y = y_center - image_sizes{c}(1)/2;

    image(x,y,images{c},'AlphaData',images_alpha{c});
    image(y,x,images{c},'AlphaData',images_alpha{c});
    
end

hold off

axis square
axis([(NUMBER_OFFSETS_LABELS *-PIXEL_SIZE_LABELS) rsm_size+PIXEL_SIZE_LABELS (NUMBER_OFFSETS_LABELS *-PIXEL_SIZE_LABELS) rsm_size+PIXEL_SIZE_LABELS]);
axis off

set(gca, 'FontSize', FONT_SIZE);