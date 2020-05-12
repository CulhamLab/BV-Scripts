function ROI_STEP8_figures_RSMandMDS

%params
p = ALL_STEP0_PARAMETERS;

%paths
readFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '7. ROI Model Correlations' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '8. Figures' filesep];
saveFol_condRSM = [saveFol 'COND RSM' filesep];
saveFol_condRSM_nolabel = [saveFol 'COND RSM nolabels' filesep];
saveFol_condMDS = [saveFol 'COND MDS' filesep];
saveFol_roi = [saveFol 'ROI-to-ROI' filesep];
saveFol_models = [saveFol 'Models' filesep];

%create folders
if ~exist(saveFol)
    mkdir(saveFol)
end
if ~exist(saveFol_condRSM)
    mkdir(saveFol_condRSM)
end
if ~exist(saveFol_condRSM_nolabel)
    mkdir(saveFol_condRSM_nolabel)
end
if ~exist(saveFol_condMDS)
    mkdir(saveFol_condMDS)
end
if ~exist(saveFol_roi)
    mkdir(saveFol_roi)
end
if ~exist(saveFol_models)
    mkdir(saveFol_models)
end

%load ROI RSMs
load([readFol 'VOI_corrs'])

%valid version?
if ~exist('runtime', 'var') || ~isfield(runtime, 'Step6') || runtime.Step6.VERSION<1
    error('The odd//even split method has been improved. Rerun from step 6.')
end

%fig
fig = figure('Position', get(0,'ScreenSize'));

%num voi
numVOI_type = length(voi_names);

%remove underscore from condition names
CONDITIONS = cellfun(@(x) strrep(x,'_',' '),p.CONDITIONS.DISPLAY_NAMES,'UniformOutput',false);

%remove underscore from voi names
voi_names_nounder = cellfun(@(x) strrep(x,'_',' '),voi_names,'UniformOutput',false);

%reorder condition labels
condition_reorder = CONDITIONS(p.RSM_PREDICTOR_ORDER);

%toggles for debugging
do_cond_rsm_split = true;
do_cond_rsm_nonsplit = true;
do_cond_mds_nonsplit = true;
do_voi_mds_split = true;
do_voi_mds_nonsplit = true;
do_voi_rsm_split = true;
do_voi_rsm_nonsplit = true;
do_voi_model_split = true;
do_voi_model_nonsplit = true;
do_model_figures = true;

%toggle off split if not VOI_USE_SPLIT
if ~p.VOI_USE_SPLIT
    do_cond_rsm_split = false;
    do_voi_mds_split = false;
    do_voi_rsm_split = false;
    do_voi_model_split = false;
end

%cell indices to use
ind_use_nonsplit = false(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
ind_use_split = false(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
for i = 1:p.NUMBER_OF_CONDITIONS
    ind_use_nonsplit(i,i+1:end) = true;
    ind_use_split(i,i:end) = true;
end
num_cell_nonsplit = sum(ind_use_nonsplit(:));
num_cell_split = sum(ind_use_split(:));

%% Indiv Model Support

for mid = 1:length(p.MODELS.matrices)
    if size(p.MODELS.matrices{mid},3) > 1
        warning('Converting indiv models to average model for "%s"', p.MODELS.names{mid});
        p.MODELS.matrices{mid} = nanmean(p.MODELS.matrices{mid}, 3);
        p.MODELS.matricesNonsplit{mid} = nanmean(p.MODELS.matricesNonsplit{mid}, 3);
        p.MODELS.names{mid} = [p.MODELS.names{mid} ' (avg of indiv)'];
    end
end

%% Condition RSM (split)
if do_cond_rsm_split
for vid = 1:numVOI_type
    clf;
    %mean rsm across subs
    rsm = nanmean(rsms_split(:,:,:,vid),3);
    
    %reorder
    rsm_reorder = rsm(p.RSM_PREDICTOR_ORDER,p.RSM_PREDICTOR_ORDER);
    
    imagesc(rsm_reorder);
    caxis(p.RSM_COLOUR_RANGE_COND);
    colormap(p.RSM_COLOURMAP);
    set(gca,'XAxisLocation', 'top','yticklabel',condition_reorder,'ytick',1:p.NUMBER_OF_CONDITIONS);
    
    returnPath = pwd;
    try
        cd('Required Methods')
        hText = xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS,90,condition_reorder);
        cd ..
    catch e
        cd(returnPath)
        rethrow(e)
    end
        
    axis square;
    t = voi_names{vid};
    t(t=='_') = ' ';
    suptitle(t);
    colorbar;
    caxis(p.RSM_COLOUR_RANGE_COND);

    SaveFigure(fig, [saveFol_condRSM 'SPLIT RSM - ' t]); 
    
    clf
    imagesc(rsm_reorder);
    colormap(p.RSM_COLOURMAP);
    caxis(p.RSM_COLOUR_RANGE_COND);
    axis square
    axis off
    SaveFigure(fig, [saveFol_condRSM_nolabel 'SPLIT RSM - ' t]); 
end
end

%% Condition RSM (nonsplit)
if do_cond_rsm_nonsplit
for vid = 1:numVOI_type
    clf;
    %mean rsm across subs
    rsm = nanmean(rsms_nonsplit(:,:,:,vid),3);
    
    %reorder
    rsm_reorder = rsm(p.RSM_PREDICTOR_ORDER,p.RSM_PREDICTOR_ORDER);
    
    imagesc(rsm_reorder);
    caxis(p.RSM_COLOUR_RANGE_COND);
    colormap(p.RSM_COLOURMAP);
    set(gca,'XAxisLocation', 'top','yticklabel',condition_reorder,'ytick',1:p.NUMBER_OF_CONDITIONS);

    returnPath = pwd;
    try
        cd('Required Methods');
        hText = xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS,90,condition_reorder);
        cd ..
    catch e
        cd(returnPath)
        rethrow(e)
    end
    
    axis square;
    t = voi_names{vid};
    t(t=='_') = ' ';
    suptitle(t);
    colorbar;
    caxis(p.RSM_COLOUR_RANGE_COND);

    SaveFigure(fig, [saveFol_condRSM 'NONSPLIT RSM - ' t]); 
        
    clf;
    imagesc(rsm_reorder);
    colormap(p.RSM_COLOURMAP);
    caxis(p.RSM_COLOUR_RANGE_COND);
    axis square;
    axis off;
    SaveFigure(fig, [saveFol_condRSM_nolabel 'NONSPLIT RSM - ' t]); 
end
end

%% Condition MDS (nonsplit)
if do_cond_mds_nonsplit
colours = jet(p.NUMBER_OF_CONDITIONS);
for vid = 1:numVOI_type
    clf;
    
    %mean rsm across subs
    rsm = nanmean(rsms_nonsplit(:,:,:,vid),3);
    
    %convert to rdm
    rdm = (rsm-1) *-0.5; %multiplying by 0.5 doesn't affect mds but fits data 0-1 (unless Fisher is applied)
    
    %apply fisher (if desired)
    if p.DO_FISHER_CONDITION_MDS
        rdm = atanh(rdm);
    end
    
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
    hold on;
    for cond = 1:p.NUMBER_OF_CONDITIONS
        c = colours(cond,:);
        a(cond) = plot(MD2D(cond,1),MD2D(cond,2),'o','color',c);
        set(a(cond),'MarkerFaceColor',c);
        text(MD2D(cond,1)+offset,MD2D(cond,2),CONDITIONS{cond},'color',c);
    end
    hold off;
    axis square;
    v=axis;
    r = max([range(v(1:2)) range(v(3:4))])/10;
    axis([min(v) max(v) min(v) max(v)] + [-r r -r r]);
    grid on;

    t = voi_names{vid};
    t(t=='_') = ' ';
    suptitle(t);
    
    SaveFigure(fig, [saveFol_condMDS 'NONSPLIT MDS - ' t]); 
	
	all_MD2D(:,:,vid) = MD2D;
end
runtime.Step8 = p.RUNTIME;
save([saveFol_condMDS 'mds_data'], 'voi_names', 'all_MD2D', 'CONDITIONS', 'runtime')
end
    
%% VOI-VOI MDS
if do_voi_mds_split
colours = jet(numVOI_type);
%init
rsms = nan(num_cell_split, numVOI_type);

for vid = 1:numVOI_type
    %mean rsm across subs
    rsm = nanmean(rsms_split(:,:,:,vid),3);
    rsm_array = rsm(ind_use_split);
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

clf;
hold on
for vid = 1:numVOI_type
    c = colours(vid,:);
    t = plot(MD2D(vid,1),MD2D(vid,2),'o','color',c);
    set(t,'MarkerFaceColor',c);
    t = text(MD2D(vid,1),MD2D(vid,2),voi_names_nounder{vid},'color',c);
    set(t,'FontSize',10);
end
hold off

axis square;
v=axis;
r = max([range(v(1:2)) range(v(3:4))])/10;
axis([min(v) max(v) min(v) max(v)] + [-r r -r r]);
grid on;

t = 'VOI-VOI MDS (split)';
suptitle(t);

SaveFigure(fig, [saveFol_roi t]); 
end

%% VOI-VOI MDS (nonsplit)
if do_voi_mds_nonsplit
colours = jet(numVOI_type);
%init
rsms = nan(num_cell_nonsplit,numVOI_type);

for vid = 1:numVOI_type
    %mean rsm across subs
    rsm = nanmean(rsms_nonsplit(:,:,:,vid),3);
    rsm_array = rsm(ind_use_nonsplit);
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

clf;
hold on
for vid = 1:numVOI_type
    c = colours(vid,:);
    t = plot(MD2D(vid,1),MD2D(vid,2),'o','color',c);
    set(t,'MarkerFaceColor',c);
    t = text(MD2D(vid,1),MD2D(vid,2),voi_names_nounder{vid},'color',c);
    set(t,'FontSize',10);
end
hold off

axis square;
v=axis;
r = max([range(v(1:2)) range(v(3:4))])/10;
axis([min(v) max(v) min(v) max(v)] + [-r r -r r]);
grid on;

t = 'VOI-VOI MDS (nonsplit)';
suptitle(t);

SaveFigure(fig, [saveFol_roi t]); 
end

%% VOI-VOI RSM
if do_voi_rsm_split
%init
rsms = nan(num_cell_split, numVOI_type);

for vid = 1:numVOI_type
    %mean rsm across subs
    rsm = nanmean(rsms_split(:,:,:,vid),3);
    rsm_array = rsm(ind_use_split);
    rsms(:,vid) = rsm_array;
end

rsm = corr(rsms,'Type','Spearman');
    
clf
imagesc(rsm)
colormap(p.RSM_COLOURMAP)
colorbar
caxis(p.RSM_COLOUR_RANGE_ROI)

axis square;

set(gca,'XAxisLocation', 'top','yticklabel',voi_names_nounder,'ytick',1:numVOI_type);

returnPath = pwd;
try
    cd('Required Methods');
    hText = xticklabel_rotate(1:numVOI_type,90,voi_names_nounder);
    cd ..
catch e
    cd(returnPath)
    rethrow(e)
end

t = 'VOI-VOI RSM (split)';
suptitle(t);

SaveFigure(fig, [saveFol_roi t]); 

clf;
imagesc(rsm);
caxis(p.RSM_COLOUR_RANGE_ROI);
colormap(p.RSM_COLOURMAP);
axis square;
axis off;
SaveFigure(fig, [saveFol_roi t '_nolabel']); 
end

%% VOI-VOI RSM (nonsplit)
if do_voi_rsm_split
%init
rsms = nan(num_cell_nonsplit, numVOI_type);

for vid = 1:numVOI_type
    %mean rsm across subs
    rsm = nanmean(rsms_nonsplit(:,:,:,vid),3);
    rsm_array = rsm(ind_use_nonsplit);
    rsms(:,vid) = rsm_array;
end

rsm = corr(rsms,'Type','Spearman');
    
clf
imagesc(rsm)
colormap(p.RSM_COLOURMAP)
colorbar
caxis(p.RSM_COLOUR_RANGE_ROI)

axis square;

set(gca,'XAxisLocation', 'top','yticklabel',voi_names_nounder,'ytick',1:numVOI_type);

returnPath = pwd;
try
    cd('Required Methods');
    hText = xticklabel_rotate(1:numVOI_type,90,voi_names_nounder);
    cd ..
catch e
    cd(returnPath)
    rethrow(e)
end

t = 'VOI-VOI RSM (nonsplit)';
suptitle(t);

SaveFigure(fig, [saveFol_roi t]); 

clf;
imagesc(rsm);
caxis(p.RSM_COLOUR_RANGE_ROI);
colormap(p.RSM_COLOURMAP);
axis square;
axis off;
SaveFigure(fig, [saveFol_roi t '_nolabel']); 
end

%% VOI+Model
%Model pairs based on different cells show as black in RSM and are treated as 0 in the MDS (not similar or dissimiliar)

if do_voi_model_split
    number_models = length(p.MODELS.matrices);
    matrix_size = numVOI_type + number_models;
    labels = [voi_names_nounder strrep(p.MODELS.names, '_', ' ')];
    
    rsm_voi_model = nan(matrix_size,matrix_size);
    rsm_voi_model_with_nan = nan(matrix_size,matrix_size);
    
    rsms = nan(num_cell_split, matrix_size);
    is_data = false(matrix_size,1);

    for vid = 1:numVOI_type
        %mean rsm across subs
        rsm = nanmean(rsms_split(:,:,:,vid),3); %use split data
        rsm_array = rsm(ind_use_split);
        rsms(:,vid) = rsm_array;
        is_data(vid) = true;
    end
    
    for mid = 1:number_models
        model = p.MODELS.matrices{mid};
        model_array = model(ind_use_split);
        rsms(:,numVOI_type+mid) = model_array;
    end
    
    for row = 1:matrix_size
        rsm_voi_model(row, row) = 1;
        rsm_voi_model_with_nan(row, row) = 1;
        
        row_val = rsms(:,row);
        row_val_ind = ~isnan(row_val);
        
        for col = (row+1):matrix_size
            col_val = rsms(:,col);
            col_val_ind = ~isnan(col_val);
            
            ind = row_val_ind & col_val_ind;
            any_mismatch = any(row_val_ind ~= col_val_ind);
            
            if any_mismatch && ~is_data(col) && ~is_data(row)
                rsm_voi_model(row,col) = 0;
                rsm_voi_model_with_nan(row,col) = nan;
            else
                c = corr(row_val(ind), col_val(ind), 'Type', 'Spearman');
                rsm_voi_model(row,col) = c;
                rsm_voi_model_with_nan(row,col) = c;
            end
            
            rsm_voi_model(col,row) = rsm_voi_model(row,col);
            rsm_voi_model_with_nan(col,row) = rsm_voi_model_with_nan(row,col);
        end
    end
    
    
    %% RSM
    clf
    imagesc(rsm_voi_model_with_nan)
	if any(isnan(rsm_voi_model_with_nan(:)))
		colormap([0 0 0; p.RSM_COLOURMAP])
	else
		colormap(p.RSM_COLOURMAP)
	end
    colorbar
    caxis([-1.01 +1])

    axis square;

    set(gca,'XAxisLocation', 'top','yticklabel',labels,'ytick',1:matrix_size);

    returnPath = pwd;
    try
        cd('Required Methods');
        hText = xticklabel_rotate(1:matrix_size,90,labels);
        cd ..
    catch e
        cd(returnPath)
        rethrow(e)
    end

    t = 'VOI-VOI-and-Models RSM (split)';
    suptitle(t);

    SaveFigure(fig, [saveFol_roi t]); 

    clf;
    imagesc(rsm_voi_model_with_nan);
    caxis([-1.01 +1])

	if any(isnan(rsm_voi_model_with_nan(:)))
		colormap([0 0 0; p.RSM_COLOURMAP])
	else
		colormap(p.RSM_COLOURMAP)
	end
	
    axis square;
    axis off;
    SaveFigure(fig, [saveFol_roi t '_nolabel']); 
    
    
    %% MDS
    colours = jet(matrix_size);
    
    rdm = (rsm_voi_model-1) *-1;
    %set diag to true zero
    for i = 1:size(rdm,1)
        rdm(i,i) = 0;
    end
    rdm = squareform(rdm);
    MD2D = mdscale(rdm,2,'criterion','sstress');

    clf;
    hold on
    for i = 1:matrix_size
        c = colours(i,:);
        t = plot(MD2D(i,1),MD2D(i,2),'o','color',c);
        set(t,'MarkerFaceColor',c);
        t = text(MD2D(i,1),MD2D(i,2),labels{i},'color',c);
        set(t,'FontSize',10);
    end
    hold off

    axis square;
    v=axis;
    r = max([range(v(1:2)) range(v(3:4))])/10;
    axis([min(v) max(v) min(v) max(v)] + [-r r -r r]);
    grid on;

    t = 'VOI-VOI-and-Models MDS (split)';
    suptitle(t);

    SaveFigure(fig, [saveFol_roi t]); 
    
end

%% VOI+Model nonsplit
%Model pairs based on different cells show as black in RSM and are treated as 0 in the MDS (not similar or dissimiliar)

if do_voi_model_nonsplit
    number_models = length(p.MODELS.matrices);
    matrix_size = numVOI_type + number_models;
    labels = [voi_names_nounder strrep(p.MODELS.names, '_', ' ')];
    
    rsm_voi_model = nan(matrix_size,matrix_size);
    rsm_voi_model_with_nan = nan(matrix_size,matrix_size);
    
    rsms = nan(num_cell_nonsplit, matrix_size);
    is_data = false(matrix_size,1);

    for vid = 1:numVOI_type
        %mean rsm across subs
        rsm = nanmean(rsms_nonsplit(:,:,:,vid),3); %use split data
        rsm_array = rsm(ind_use_nonsplit);
        rsms(:,vid) = rsm_array;
        is_data(vid) = true;
    end
    
    for mid = 1:number_models
        model = p.MODELS.matrices{mid};
        model_array = model(ind_use_nonsplit);
        rsms(:,numVOI_type+mid) = model_array;
    end
    
    for row = 1:matrix_size
        rsm_voi_model(row, row) = 1;
        rsm_voi_model_with_nan(row, row) = 1;
        
        row_val = rsms(:,row);
        row_val_ind = ~isnan(row_val);
        
        for col = (row+1):matrix_size
            col_val = rsms(:,col);
            col_val_ind = ~isnan(col_val);
            
            ind = row_val_ind & col_val_ind;
            any_mismatch = any(row_val_ind ~= col_val_ind);
            
            if any_mismatch && ~is_data(col) && ~is_data(row)
                rsm_voi_model(row,col) = 0;
                rsm_voi_model_with_nan(row,col) = nan;
            else
                c = corr(row_val(ind), col_val(ind), 'Type', 'Spearman');
                rsm_voi_model(row,col) = c;
                rsm_voi_model_with_nan(row,col) = c;
            end
            
            rsm_voi_model(col,row) = rsm_voi_model(row,col);
            rsm_voi_model_with_nan(col,row) = rsm_voi_model_with_nan(row,col);
        end
    end
    
    
    %% RSM
    clf
    imagesc(rsm_voi_model_with_nan)

	if any(isnan(rsm_voi_model_with_nan(:)))
		colormap([0 0 0; p.RSM_COLOURMAP])
	else
		colormap(p.RSM_COLOURMAP)
	end
	
    colorbar
    caxis([-1.01 +1])

    axis square;

    set(gca,'XAxisLocation', 'top','yticklabel',labels,'ytick',1:matrix_size);

    returnPath = pwd;
    try
        cd('Required Methods');
        hText = xticklabel_rotate(1:matrix_size,90,labels);
        cd ..
    catch e
        cd(returnPath)
        rethrow(e)
    end

    t = 'VOI-VOI-and-Models RSM (nonsplit)';
    suptitle(t);

    SaveFigure(fig, [saveFol_roi t]); 

    clf;
    imagesc(rsm_voi_model_with_nan);
    caxis([-1.01 +1])

	if any(isnan(rsm_voi_model_with_nan(:)))
		colormap([0 0 0; p.RSM_COLOURMAP])
	else
		colormap(p.RSM_COLOURMAP)
	end
	
    axis square;
    axis off;
    SaveFigure(fig, [saveFol_roi t '_nolabel']); 
    
    
    %% MDS
    colours = jet(matrix_size);
    
    rdm = (rsm_voi_model-1) *-1;
    %set diag to true zero
    for i = 1:size(rdm,1)
        rdm(i,i) = 0;
    end
    rdm = squareform(rdm);
    MD2D = mdscale(rdm,2,'criterion','sstress');

    clf;
    hold on
    for i = 1:matrix_size
        c = colours(i,:);
        t = plot(MD2D(i,1),MD2D(i,2),'o','color',c);
        set(t,'MarkerFaceColor',c);
        t = text(MD2D(i,1),MD2D(i,2),labels{i},'color',c);
        set(t,'FontSize',10);
    end
    hold off

    axis square;
    v=axis;
    r = max([range(v(1:2)) range(v(3:4))])/10;
    axis([min(v) max(v) min(v) max(v)] + [-r r -r r]);
    grid on;

    t = 'VOI-VOI-and-Models MDS (nonsplit)';
    suptitle(t);

    SaveFigure(fig, [saveFol_roi t]); 
    
end

%% Model Figures (split)
if do_model_figures
    number_models = length(p.MODELS.names);
    
    for m = 1:number_models
        model = p.MODELS.matrices{m}(p.RSM_PREDICTOR_ORDER, p.RSM_PREDICTOR_ORDER);
        
        for c1 = 1:p.NUMBER_OF_CONDITIONS
        for c2 = 1:p.NUMBER_OF_CONDITIONS
            if isnan(model(c1,c2)) && ~isnan(model(c2,c1))
                model(c1,c2) = model(c2,c1);
            elseif ~isnan(model(c1,c2)) && isnan(model(c2,c1))
                model(c2,c1) = model(c1,c2);
            end
        end
        end
        
        clf
        PlotModel(model , p.RSM_COLOURMAP)
        colorbar
        
        set(gca,'XAxisLocation', 'top','yticklabel',condition_reorder,'ytick',1:p.NUMBER_OF_CONDITIONS);
        
        returnPath = pwd;
        try
            cd('Required Methods');
            hText = xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS,90,condition_reorder);
            cd ..
        catch e
            cd(returnPath)
            rethrow(e)
        end
        
        t = [strrep(p.MODELS.names{m},'_',' ')];
        suptitle(t);
        
        SaveFigure(fig, [saveFol_models t]);
        
        clf
        PlotModel(model , p.RSM_COLOURMAP)
        axis off;
        SaveFigure(fig, [saveFol_models t '_nolabel']); 
    end
    
end

% %% Model Figures (nonsplit)
% if do_model_figures_nonsplit
%     number_models = length(p.MODELS.names);
%     
%     for m = 1:number_models
%         model = p.MODELS.matrices{m}(p.RSM_PREDICTOR_ORDER, p.RSM_PREDICTOR_ORDER);
%         
%         for c1 = 1:p.NUMBER_OF_CONDITIONS
%         for c2 = 1:p.NUMBER_OF_CONDITIONS
%             if isnan(model(c1,c2)) && ~isnan(model(c2,c1))
%                 model(c1,c2) = model(c2,c1);
%             elseif ~isnan(model(c1,c2)) && isnan(model(c2,c1))
%                 model(c2,c1) = model(c1,c2);
%             end
%         end
%         end
%         
%         for i = 1:p.NUMBER_OF_CONDITIONS
%             model(i,1:i) = nan;
%         end
%         
%         clf
%         PlotModel(model , p.RSM_COLOURMAP)
%         colorbar
%         
%         set(gca,'XAxisLocation', 'top','yticklabel',condition_reorder,'ytick',1:p.NUMBER_OF_CONDITIONS);
%         
%         returnPath = pwd;
%         try
%             cd('Required Methods');
%             hText = xticklabel_rotate(1:p.NUMBER_OF_CONDITIONS,90,condition_reorder);
%             cd ..
%         catch e
%             cd(returnPath)
%             rethrow(e)
%         end
%         
%         t = ['NONSPLIT-' strrep(p.MODELS.names{m},'_',' ')];
%         suptitle(t);
%         
%         SaveFigure(fig, [saveFol_models t]);
%         
%         clf
%         PlotModel(model , p.RSM_COLOURMAP)
%         axis off;
%         SaveFigure(fig, [saveFol_models t '_nolabel']); 
%     end
% end

%% close figure
close all

function SaveFigure(fig, filepath)
set(fig, 'PaperPosition', [0 0 15 15]);
% print(fig, filepath, '-dpng', '-r1200' ); 
saveas(fig,filepath,'png');

function PlotModel(model,cmap)
if any(isnan(model(:)))
	cmap = [0 0 0; cmap];
end
imagesc(model)
caxis([nanmin(model(:))-(2/size(cmap,1)) nanmax(model(:))])
colormap(cmap);
axis square;
