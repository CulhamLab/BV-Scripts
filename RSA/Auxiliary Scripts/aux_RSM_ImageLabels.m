function aux_RSM_ImageLabels

%% Parameters

PIXEL_SIZE_RSM_CELLS = 50;
PIXEL_SIZE_LABELS = 100;
NUMBER_OFFSETS_LABELS = 3;

DIRECTORY_NAME_SAVE = 'aux_RSM_ImageLabels';

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

%% Resize Images
images_select_max_dim = cellfun(@(x) max(size(x)), images_select, 'UniformOutput', false);
images_select_resized = cellfun(@(x,y) imresize(x,PIXEL_SIZE_LABELS/y), images_select, images_select_max_dim, 'UniformOutput', false);

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
fig = figure('Position', [1 1 1000 1000]);
for vid = 1:number_voi
    CreateImageRSM(p, PIXEL_SIZE_LABELS, PIXEL_SIZE_RSM_CELLS, NUMBER_OFFSETS_LABELS, mean_rsm_vois_split(:,:,vid), images_select_resized);
    suptitle(strrep(data.VOINames{vid},'_',' '))
    saveas(fig, [directory_save 'SPLIT_' data.VOINames{vid} '.png'], 'png');
    
    CreateImageRSM(p, PIXEL_SIZE_LABELS, PIXEL_SIZE_RSM_CELLS, NUMBER_OFFSETS_LABELS, mean_rsm_vois_nonsplit(:,:,vid), images_select_resized);
    suptitle(strrep(data.VOINames{vid},'_',' '))
    saveas(fig, [directory_save 'NONSPLIT_' data.VOINames{vid} '.png'], 'png');
end
close(fig);

%% Done
disp Done.

function CreateImageRSM(p, PIXEL_SIZE_LABELS, PIXEL_SIZE_RSM_CELLS, NUMBER_OFFSETS_LABELS, rsm, images)
%check size
rsm_size = size(rsm,1);

%clear
clf

%white background
set(gcf,'color','w');

%draw matrix
imagesc(rsm);
colormap(p.RSM_COLOURMAP)
caxis([p.RSM_COLOUR_RANGE_COND]);
colorbar

%measure images
image_sizes = cellfun(@size, images, 'UniformOutput', false);

%draw each image
hold on
for c = 1:p.NUMBER_OF_CONDITIONS
    %TODO - solve for center and draw lines
    
    x = (mod(c - 1, NUMBER_OFFSETS_LABELS) + 1) * -PIXEL_SIZE_LABELS;
    y = (c * PIXEL_SIZE_RSM_CELLS) - (PIXEL_SIZE_RSM_CELLS/2) - (image_sizes{c}(1)/2);
    image(x,y,images{c});
    image(y,x,images{c});
end
hold off

axis square
axis([(NUMBER_OFFSETS_LABELS *-PIXEL_SIZE_LABELS) rsm_size+PIXEL_SIZE_LABELS (NUMBER_OFFSETS_LABELS *-PIXEL_SIZE_LABELS) rsm_size+PIXEL_SIZE_LABELS]);
axis off