function aux_EachSubjectVOIRSMFigures

FONTSIZE = 6;

%% Load Parameters

fprintf('Loading parameters...\n');
%remember where to come back to
return_path = pwd;
try
    %move to main folder
    cd ..

    %get params
    p = ALL_STEP0_PARAMETERS;
    
    %return to aux folder
    cd(return_path);
catch err
    cd(return_path);
    rethrow(err);
end

%% Directories

DIR_IN = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep];
DIR_OUT = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep 'aux_EachSubjectVOIRSMFigures' filesep];

if ~exist(DIR_IN, 'dir')
    error('Cannot located input directory: %s', DIR_IN);
end

if ~exist(DIR_OUT, 'dir')
    mkdir(DIR_OUT);
end

fprintf('Input Directory:\t%s\n', DIR_IN);
fprintf('Output Directory:\t%s\n', DIR_OUT);

%% Load RSMs
fprintf('Loading RSMs...\n')
load([DIR_IN 'VOI_RSMs.mat']);
number_voi = size(data.VOInumVox,2);

%% Plot p.RSM_COLOUR_RANGE_COND
fig = figure('Position', [1 1 1200 1000]);
for pid = 1:p.NUMBER_OF_PARTICIPANTS
    for vid = 1:number_voi
        fprintf('Plotting participant %d of %d, voi %d of %d...\n', pid, p.NUMBER_OF_PARTICIPANTS, vid, number_voi);
        PlotRSM( fig , p , FONTSIZE, data.RSM_split(:,:,pid,vid) , sprintf('SPLIT - %s - P%02d', data.VOINames{vid}, pid), sprintf('%sSPLIT_%s_P%02d.png', DIR_OUT, data.VOINames{vid}, pid) );
        PlotRSM( fig , p , FONTSIZE, data.RSM_nonsplit(:,:,pid,vid) , sprintf('NONSPLIT - %s - P%02d', data.VOINames{vid}, pid), sprintf('%sNONSPLIT_%s_P%02d.png', DIR_OUT, data.VOINames{vid}, pid) );
    end
end
close(fig);



function PlotRSM(fig, p, FONTSIZE, rsm, title_string, fp_out)
labels = strrep(p.CONDITIONS.DISPLAY_NAMES(p.RSM_PREDICTOR_ORDER),'_',' ');

clf
imagesc(rsm(p.RSM_PREDICTOR_ORDER,p.RSM_PREDICTOR_ORDER));
axis square
set(gca,'ytick',1:p.NUMBER_OF_CONDITIONS,'yticklabel',labels,'xtick',1:p.NUMBER_OF_CONDITIONS,'xticklabel',cell(1,p.NUMBER_OF_CONDITIONS),'XAxisLocation', 'top','FontSize',FONTSIZE);
colormap(p.RSM_COLOURMAP);
caxis(p.RSM_COLOUR_RANGE_COND);
colorbar;
xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS,90,labels,'FontSize',FONTSIZE);
suptitle(strrep(title_string,'_',' '));

set(fig, 'PaperPosition', [0 0 15 15]);
saveas(fig,fp_out,'png');