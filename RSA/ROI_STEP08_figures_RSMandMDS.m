function ROI_STEP8_figures_RSMandMDS

%params
p = ALL_STEP0_PARAMETERS;

%paths
readFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '7. ROI Model Correlations' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '8. Figures' filesep];
saveFol_condRSM = [saveFol 'COND RSM' filesep];
saveFol_condMDS = [saveFol 'COND MDS' filesep];
saveFol_roi = [saveFol 'ROI-to-ROI' filesep];

%create folders
if ~exist(saveFol)
    mkdir(saveFol)
end
if ~exist(saveFol_condRSM)
    mkdir(saveFol_condRSM)
end
if ~exist(saveFol_condMDS)
    mkdir(saveFol_condMDS)
end
if ~exist(saveFol_roi)
    mkdir(saveFol_roi)
end

%load ROI RSMs
load([readFol 'VOI_corrs_organized'])

%fig
fig = figure('Position', get(0,'ScreenSize'));

%num voi
numVOI_type = length(VOI_type_names);

%remove underscore from condition names
CONDITIONS = cellfun(@(x) strrep(x,'_',' '),p.CONDITIONS.DISPLAY_NAMES,'UniformOutput',false);

%remove underscore from voi names
voi_names_nounder = cellfun(@(x) strrep(x,'_',' '),VOI_type_names,'UniformOutput',false);

%% Condition RSM (split)
for vid = 1:numVOI_type
    clf
    %mean rsm across subs
    rsm = mean(rsms_split_organized(:,:,:,vid),3);
    imagesc(rsm)
    caxis(p.RSM_COLOUR_RANGE_COND)
    colormap(p.RSM_COLOURMAP)
    set(gca,'XAxisLocation', 'top','yticklabel',CONDITIONS,'ytick',1:p.NUMBER_OF_CONDITIONS)
    
    returnPath = pwd;
    try
        cd('Required Methods')
        hText = xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS,40,CONDITIONS);
        cd ..
    catch e
        cd(returnPath)
        rethrow(e)
    end
        
    axis square
    t = VOI_type_names{vid};
    t(t=='_') = ' ';
    suptitle(t)
    colorbar

    saveas(fig,[saveFol_condRSM 'SPLIT RSM - ' t],'png')
end

%% Condition RSM (nonsplit)
for vid = 1:numVOI_type
    clf
    %mean rsm across subs
    rsm = mean(rsms_nonsplit_organized(:,:,:,vid),3);
    imagesc(rsm)
    caxis(p.RSM_COLOUR_RANGE_COND)
    colormap(p.RSM_COLOURMAP)
    set(gca,'XAxisLocation', 'top','yticklabel',CONDITIONS,'ytick',1:p.NUMBER_OF_CONDITIONS)

    returnPath = pwd;
    try
        cd('Required Methods')
        hText = xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS,40,CONDITIONS);
        cd ..
    catch e
        cd(returnPath)
        rethrow(e)
    end
    
    axis square
    t = VOI_type_names{vid};
    t(t=='_') = ' ';
    suptitle(t)
    colorbar

%     saveas(fig,[saveFol_condRSM 'NONSPLIT RSM - ' t],'png')
    set(fig, 'PaperPosition', [0 0 5 5])
    print(fig, [saveFol_condRSM 'NONSPLIT RSM - ' t], '-dpng', '-r1200' ); 
        
end

%% Condition MDS (nonsplit)
colours = jet(p.NUMBER_OF_CONDITIONS);
for vid = 1:numVOI_type
    clf
    
    %mean rsm across subs
    rsm = mean(rsms_nonsplit_organized(:,:,:,vid),3);

    %apply fisher (if desired)
    if p.DO_FISHER_CONDITION_MDS
        rsm = atanh(rsm);
    end
    
    %convert to rdm
    rdm = (rsm-1) *-0.5; %multiplying by 0.5 doesn't affect mds but fits data 0-1 (unless Fisher is applied)
    
    %set diag to true zero
    for i = 1:p.NUMBER_OF_CONDITIONS
        rdm(i,i) = 0;
    end
    
    %mds 2D
    rdm = squareform(rdm);
    MD2D = mdscale(rdm,2,'criterion','sstress');
    
    %dynamic offset for labels
    offset = range(MD2D(:,1))/40;
    
    %plot
    hold on
    for cond = 1:p.NUMBER_OF_CONDITIONS
        c = colours(cond,:);
        a(cond) = plot(MD2D(cond,1),MD2D(cond,2),'o','color',c);
        set(a(cond),'MarkerFaceColor',c);
        text(MD2D(cond,1)+offset,MD2D(cond,2),CONDITIONS{cond},'color',c);
    end
    hold off
    axis square
    v=axis;
    r = max([range(v(1:2)) range(v(3:4))])/10;
    axis([min(v) max(v) min(v) max(v)] + [-r r -r r])
    grid on

    t = VOI_type_names{vid};
    t(t=='_') = ' ';
    suptitle(t)
    
%     saveas(fig,[saveFol_condMDS 'NONSPLIT MDS - ' t],'png')
    set(fig, 'PaperPosition', [0 0 5 5])
    print(fig, [saveFol_condMDS 'NONSPLIT MDS - ' t], '-dpng', '-r1200' ); 
end
    
%% VOI-VOI MDS
colours = jet(numVOI_type);
%init
rsms = nan(p.NUMBER_OF_CONDITIONS^2,numVOI_type);

for vid = 1:numVOI_type
    %mean rsm across subs
    rsm = mean(rsms_split_organized(:,:,:,vid),3);
    rsm_array = rsm(:);
    rsms(:,vid) = rsm_array;
end

rsm = corr(rsms,'Type','Spearman');
rdm = (rsm-1) *-1;
%set diag to true zero
for i = 1:size(rdm,1)
    rdm(i,i) = 0;
end
rdm = squareform(rdm);
MD2D = mdscale(rdm,2,'criterion','sstress');

clf
hold on
for vid = 1:numVOI_type
    c = colours(vid,:);
    t = plot(MD2D(vid,1),MD2D(vid,2),'o','color',c);
    set(t,'MarkerFaceColor',c);
    t = text(MD2D(vid,1),MD2D(vid,2),voi_names_nounder{vid},'color',c);
    set(t,'FontSize',10)
end
hold off

axis square
v=axis;
r = max([range(v(1:2)) range(v(3:4))])/10;
axis([min(v) max(v) min(v) max(v)] + [-r r -r r])
grid on

t = 'VOI-VOI MDS (split)';
suptitle(t)

% saveas(fig,[saveFol_roi 'ROI MDS'],'png')
set(fig, 'PaperPosition', [0 0 5 5])
print(fig, [saveFol_roi 'ROI MDS'], '-dpng', '-r1200' ); 

%% VOI-VOI RSM
imagesc(rsm)
caxis(p.RSM_COLOUR_RANGE_ROI)
colormap(p.RSM_COLOURMAP)
colorbar

axis square

t = 'VOI-VOI RSM (split)';
suptitle(t)

set(gca,'XAxisLocation', 'top','yticklabel',voi_names_nounder,'ytick',1:numVOI_type)

returnPath = pwd;
try
    cd('Required Methods')
    hText = xticklabel_rotate(1:numVOI_type,40,voi_names_nounder);
    cd ..
catch e
    cd(returnPath)
    rethrow(e)
end

% saveas(fig,[saveFol_roi t],'png')
set(fig, 'PaperPosition', [0 0 5 5])
print(fig, [saveFol_roi t], '-dpng', '-r1200' ); 

%% close figure
close all