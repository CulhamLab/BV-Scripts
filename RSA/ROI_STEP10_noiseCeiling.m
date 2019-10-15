function ROI_STEP10_noiseCeiling

%params
p = ALL_STEP0_PARAMETERS;

%paths
readFolA = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep];
readFolB = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '7. ROI Model Correlations' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '10. Noise Ceiling' filesep];

%create saveFol
if ~exist(saveFol)
    mkdir(saveFol)
end

%load
load([readFolA 'VOI_RSMs'])
load([readFolB 'VOI_corrs'])

%split?
if p.VOI_USE_SPLIT
    split_type = 'split';
    corrs_use = corrs_split;
    rsms_use = rsms_split;
    models_use = p.MODELS.matrices;
    selection_for_base_ceiling = true(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
else
    split_type = 'nonsplit';
    corrs_use = corrs_nonsplit;
    rsms_use = rsms_nonsplit;
    models_use = p.MODELS.matricesNonsplit;
    selection_for_base_ceiling = false(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
    for i = 1:p.NUMBER_OF_CONDITIONS
        selection_for_base_ceiling(i,(i+1):end) = true;
    end
end

%save directory
if saveFol(1) == '.' %is a relative path
    saveFolUse = ['..' filesep saveFol];
else
    saveFolUse = saveFol;
end

%range
% temp = mean(corrs_split,1);
% ran = [min(temp(:)) max(temp(:))];
% ran = [ran(1)-(range(ran)*0.1) ran(2)+(range(ran)*0.1)];
ran = [-0.4 +1];

%model-specific noise ceiling?
do_model_specifc_ceiling = false; %default to false
submatrix_model_inds = find(cellfun(@(x) any(isnan(x(selection_for_base_ceiling))), models_use));
if ~isempty(submatrix_model_inds)
    if ~isfield(p, 'INDIVIDUAL_MODEL_NOISE_CEILING')
        warning('The parameters file is outdated and does not contain INDIVIDUAL_MODEL_NOISE_CEILING. One or more models uses a subset of RSM cells but current settings will compare all models to a standard noise ceiling based on all cells. Please consider adding this field to your parameters.')
    elseif ~islogical(p.INDIVIDUAL_MODEL_NOISE_CEILING)
        error('The parameter INDIVIDUAL_MODEL_NOISE_CEILING must be true or false')
    elseif ~p.INDIVIDUAL_MODEL_NOISE_CEILING
        warning('One or more models uses a subset of RSM cells but current settings (INDIVIDUAL_MODEL_NOISE_CEILING is false) will compare all models to a standard noise ceiling based on all cells.');
    else
        %enable
        do_model_specifc_ceiling = true;
    end
end

%required methods
try
cd 'Required Methods'

%fig
fig = figure('Position', get(0,'ScreenSize'));
num_model = size(corrs_use, 2);
for voi = 1:length(voi_names)
    RSMs = rsms_use(:,:,:,voi);
    
    [upper,lower,indiv_all,indiv_leaveoneout] = compute_rsm_noise_ceiling(RSMs, selection_for_base_ceiling);
    model_corrs = corrs_use(:,:,voi);
    model_corrs_avg = mean(model_corrs, 1);
    
    s = std(model_corrs,1) / sqrt(size(model_corrs,1));
    eb = 1.96 * s;
    
    if do_model_specifc_ceiling
        model_specific_upper(:,voi) = nan(1, num_model);
        model_specific_lower(:,voi) = nan(1, num_model);
        for m = submatrix_model_inds
            [model_specific_upper(m,voi), model_specific_lower(m,voi), model_specific_corrs_indiv_all(m,voi,:), model_specific_corrs_corrs_indiv_leaveoneout(m,voi,:)] = compute_rsm_noise_ceiling(RSMs, ~isnan(models_use{m}));
        end
    end
    
    if p.CREATE_FIGURE_NOISE_CEILING
        v = [0 num_model+1 ran];
        clf
        hold on
        rectangle('Position', [v(1), lower, v(2), upper-lower], 'FaceColor', [127 127 127]/255)
        if do_model_specifc_ceiling
            for m = submatrix_model_inds
                rectangle('Position', [m-0.5, model_specific_lower(m,voi), 1, model_specific_upper(m,voi)-model_specific_lower(m,voi)], 'FaceColor', [200 200 200]/255)
            end
        end
        bar(model_corrs_avg)
        errorbar(1:length(model_corrs_avg), model_corrs_avg, eb, 'k.')
        hold off
        axis(v);
        set(gca, 'XTick', 1:num_model, 'XTickLabel', strrep(p.MODELS.names,'_',' '));
        xticklabel_rotate([], 30, [], 'Fontsize', 10);
        ylabel('Mean Correlation (r-value)')
        t = [strrep(voi_names{voi},'_',' ') ' (' split_type ')'];
        title(t);
        
        saveas(fig, [saveFolUse t '.png'], 'png')
    end
    
    model_corrs_avg_all(voi,:) = model_corrs_avg;
    errorbars_all(voi,:) = eb;
    upper_all(voi) = upper;
    lower_all(voi) = lower;
    corrs_indiv_all(voi,:) = indiv_all;
    corrs_indiv_leaveoneout(voi,:) = indiv_leaveoneout;
end

%% new figure
if p.CREATE_FIGURE_SUMMARY
    clf
    
    c=0;
    hold on

    c=c+1;
    pl(c) = plot(upper_all, '.--', 'Color', [0 0 0]);
    leg{c} = 'Noise (upper)';

    c=c+1;
    pl(c) = plot(lower_all, '.:', 'Color', [0 0 0]);
    leg{c} = 'Noise (lower)';

    colours = jet(num_model);
    for m = 1:num_model
        c=c+1;
        rvals = model_corrs_avg_all(:,m);
        pl(c) = plot(rvals, '.-', 'Color', colours(m,:));
        leg{c} = strrep(p.MODELS.names{m},'_',' ');

        ebs = errorbars_all(:,m);
        errorbar(1:length(voi_names), rvals, ebs, 'Color', colours(m,:))
    end

    x = [1 length(voi_names)] + [-0.1 +0.1];
    plot(x, [0 0], 'k')

    hold off

    legend(pl, leg, 'Location', 'EastOutside');

    v = axis;
    axis([x v(3:4)]);
    ylabel('r-value')
    set(gca, 'XTick', 1:length(voi_names), 'XTickLabel', strrep(voi_names,'_',' '));
    xticklabel_rotate([], 30, [], 'Fontsize', 10);
    grid on

    saveas(fig, [saveFolUse 'Summary_' split_type '.png'], 'png')
end

%% excel

xls = cell(0);
xls(3:(2+length(voi_names))) = voi_names;
row = 1;
num_voi = length(upper_all);

row = row + 1;
xls{row,1} = 'Noise Ceiling';
xls{row,2} = 'Upper';
xls(row,3:(2+num_voi)) = num2cell(upper_all);

row = row + 1;
xls{row,1} = 'Noise Ceiling';
xls{row,2} = 'Lower';
xls(row,3:(2+num_voi)) = num2cell(lower_all);

for m = 1:num_model
    rvals = model_corrs_avg_all(:,m);
    ebs = errorbars_all(:,m);

    row = row + 1;
    xls{row,1} = p.MODELS.names{m};
    xls{row,2} = 'mean r-value';
    xls(row,3:(2+num_voi)) = num2cell(rvals);

    row = row + 1;
    xls{row,1} = p.MODELS.names{m};
    xls{row,2} = '95% CI +-';
    xls(row,3:(2+num_voi)) = num2cell(ebs);
end

%add model-specific noise ceilings
if do_model_specifc_ceiling
    row = row + 1;
    for m = submatrix_model_inds
        row = row + 1;
        xls{row,1} = p.MODELS.names{m};
        xls{row,2} = 'model-specific noise ceiling upper';
        xls(row,3:(2+num_voi)) = num2cell(model_specific_upper(m,:));
        
        row = row + 1;
        xls{row,1} = p.MODELS.names{m};
        xls{row,2} = 'model-specific noise ceiling lower';
        xls(row,3:(2+num_voi)) = num2cell(model_specific_lower(m,:));
    end
end

%indiv model values
for m = 1:num_model
    row = row + 2;
    xls(row,3:(2+length(voi_names))) = voi_names;
    for pid = 1:p.NUMBER_OF_PARTICIPANTS
        row = row + 1;
        xls{row,1} = sprintf('P%02d', pid);
        xls{row,2} = p.MODELS.names{m};
        xls(row,3:(2+num_voi)) = num2cell(squeeze(corrs_use(pid,m,:))');
    end
end

%indiv corr values from noise ceils
row = row + 2;
xls(row,3:(2+length(voi_names))) = voi_names;
for pid = 1:p.NUMBER_OF_PARTICIPANTS
    row = row + 1;
    xls{row,1} = sprintf('P%02d', pid);
    xls{row,2} = 'Correlation to group (for upper bound)';
    xls(row,3:(2+num_voi)) = num2cell(corrs_indiv_all(:,pid)');
end
row = row + 2;
xls(row,3:(2+length(voi_names))) = voi_names;
for pid = 1:p.NUMBER_OF_PARTICIPANTS
    row = row + 1;
    xls{row,1} = sprintf('P%02d', pid);
    xls{row,2} = 'Correlation to leave-one-out (for lower bound)';
    xls(row,3:(2+num_voi)) = num2cell(corrs_indiv_leaveoneout(:,pid)');
end

if do_model_specifc_ceiling
    for m = submatrix_model_inds
        row = row + 2;
        xls(row,3:(2+length(voi_names))) = voi_names;
        for pid = 1:p.NUMBER_OF_PARTICIPANTS
            row = row + 1;
            xls{row,1} = sprintf('P%02d', pid);
            xls{row,2} = ['model-specific (' p.MODELS.names{m} ') correlation to group (for upper bound)'];
            xls(row,3:(2+num_voi)) = num2cell(model_specific_corrs_indiv_all(m,:,pid));
        end
        
        row = row + 2;
        xls(row,3:(2+length(voi_names))) = voi_names;
        for pid = 1:p.NUMBER_OF_PARTICIPANTS
            row = row + 1;
            xls{row,1} = sprintf('P%02d', pid);
            xls{row,2} = ['model-specific (' p.MODELS.names{m} ') correlation to leave-one-out (for lower bound)'];
            xls(row,3:(2+num_voi)) = num2cell(model_specific_corrs_corrs_indiv_leaveoneout(m,:,pid));
        end
    end
end

xls_fp = [saveFolUse 'Summary_' split_type '.xlsx'];
if exist(xls_fp,'file')
	delete(xls_fp)
end
xlswrite(xls_fp, xls);

%% custom figures
number_custom = length(p.CUSTOM_VOI_SUMMARY_FIGURES);
for c = 1:number_custom
    fprintf('Creating custom summary figure %d of %d: %s\n', c, number_custom, p.CUSTOM_VOI_SUMMARY_FIGURES(c).NAME);
    
    %default to all voi names
    if isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).VOI_NAMES)
        p.CUSTOM_VOI_SUMMARY_FIGURES(c).VOI_NAMES = voi_names;
    end
    
    %select voi
    try
        ind_voi = cellfun(@(x) find(strcmp(voi_names,x)), p.CUSTOM_VOI_SUMMARY_FIGURES(c).VOI_NAMES);
    catch err
        warning('A VOI name in CUSTOM_VOI_SUMMARY_FIGURES might not have been found')
        rethrow(err)
    end
    number_voi = length(ind_voi);
    noise_ceiling_upper = upper_all(ind_voi);
    noise_ceiling_lower = lower_all(ind_voi);
    
    %select model
    try
        ind_model = cellfun(@(x) find(strcmp(p.MODELS.names,x)), {p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL.NAME});
    catch err
        warning('A model name in CUSTOM_VOI_SUMMARY_FIGURES might not have been found')
        rethrow(err)
    end
    number_model = length(ind_model);
    model_corrs_selected = model_corrs_avg_all(ind_voi, ind_model);
    error_bars_selected = errorbars_all(ind_voi, ind_model);
    
    %default model colour to line
    for m = 1:number_model
        if isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_COLOUR)
            p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_COLOUR = p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).LINE_COLOUR;
        end
        if isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_FILLED_COLOUR)
            p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_FILLED_COLOUR = p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).LINE_COLOUR;
        end
    end
    
    %COPY_FROM
    for m = 1:number_model
        if isfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m), 'COPY_FROM') && ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).COPY_FROM) && p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).COPY_FROM
            fs = fields(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m));
            for fid = fs'
                fid = fid{1};
                v = getfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m), fid);
                if isempty(v) & ~ischar(v)
                    p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m) = setfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m), ...
                                                                        fid, ...
                                                                        getfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL( p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).COPY_FROM ), fid) );
                end
            end
        end
    end
    
    %clear figure
    clf
    hold on

    %init
    pl = [];
    pl_legend = cell(0);
    pl_has_ns_upper = false;
    pl_has_ns_lower = false;
    pl_has_model = false(number_model);
    pl_has_model_ns_upper = false(number_model);
    pl_has_model_ns_lower = false(number_model);
    
    %zone
    ax = [1-p.CUSTOM_VOI_SUMMARY_FIGURES(c).SPACING_LEFT_RIGHT , number_voi+p.CUSTOM_VOI_SUMMARY_FIGURES(c).SPACING_LEFT_RIGHT , p.CUSTOM_VOI_SUMMARY_FIGURES(c).YMIN , p.CUSTOM_VOI_SUMMARY_FIGURES(c).YMAX];
    
    %shaded noise ceiling area
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_SHADE_COLOUR)
        for i = 2:number_voi
            ns = fill([-1 0 0 -1]+i , [noise_ceiling_upper(i-1) noise_ceiling_upper(i) noise_ceiling_lower(i) noise_ceiling_lower(i-1)], p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_SHADE_COLOUR, 'EdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_SHADE_COLOUR);
        end
        j = length(pl) + 1;
        pl(j) = ns;
        pl_legend{j} = 'Noise Ceiling';
    end
    
    %do model-specific noise ceilings?
    try_model_specific_noise_ceilings = do_model_specifc_ceiling && isfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(1), 'NOISE_CEILING_ENABLED');
    if try_model_specific_noise_ceilings
        model_specific_noise_ceiling_upper = model_specific_upper(ind_model, ind_voi);
        model_specific_noise_ceiling_lower = model_specific_lower(ind_model, ind_voi);
    end
    
    %model-specific shaded noise ceiling area
    if try_model_specific_noise_ceilings
        for m = 1:number_model
            if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_ENABLED) && p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_ENABLED && ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_SHADE_COLOUR)
                upper = model_specific_noise_ceiling_upper(m,:);
                lower = model_specific_noise_ceiling_lower(m,:);
                if ~any(isnan([upper lower]))
                    for i = 2:number_voi
                        ns = fill([-1 0 0 -1]+i , [upper(i-1) upper(i) lower(i) lower(i-1)], p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_SHADE_COLOUR, 'EdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_SHADE_COLOUR);
                    end
                    j = length(pl) + 1;
                    pl(j) = ns;
                    pl_legend{j} = ['Noise Ceiling (' strrep(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NAME,'_',' ') ')'];
                end
            end
        end
    end
    
    %x lines
    if p.CUSTOM_VOI_SUMMARY_FIGURES(c).DRAW_LINES_VERTICAL
        for i = 1:number_voi
            plot([i i],ax(3:4),p.CUSTOM_VOI_SUMMARY_FIGURES(c).DRAW_LINES_VERTICAL_TYPE,'Color',p.CUSTOM_VOI_SUMMARY_FIGURES(c).DRAW_LINES_VERTICAL_COLOUR,'LineWidth',p.CUSTOM_VOI_SUMMARY_FIGURES(c).DRAW_LINES_VERTICAL_WIDTH);
        end
    end
    
    %y lines
    if p.CUSTOM_VOI_SUMMARY_FIGURES(c).DRAW_LINES_HORIZONTAL
        for i = p.CUSTOM_VOI_SUMMARY_FIGURES(c).YTICKS
            plot(ax(1:2),[i i],p.CUSTOM_VOI_SUMMARY_FIGURES(c).DRAW_LINES_HORIZONTAL_TYPE,'Color',p.CUSTOM_VOI_SUMMARY_FIGURES(c).DRAW_LINES_HORIZONTAL_COLOUR,'LineWidth',p.CUSTOM_VOI_SUMMARY_FIGURES(c).DRAW_LINES_HORIZONTAL_WIDTH);
        end
    end
    
    %zero line
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).ZERO_LINE_TYPE)
        plot(ax(1:2),[0 0], p.CUSTOM_VOI_SUMMARY_FIGURES(c).ZERO_LINE_TYPE, 'Color', p.CUSTOM_VOI_SUMMARY_FIGURES(c).ZERO_LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).ZERO_LINE_WIDTH);
        plot([1 1]*ax(1), ax(3:4), p.CUSTOM_VOI_SUMMARY_FIGURES(c).ZERO_LINE_TYPE, 'Color', p.CUSTOM_VOI_SUMMARY_FIGURES(c).ZERO_LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).ZERO_LINE_WIDTH);
    end
    
    %plot noise ceiling lines
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_LINE_TYPE)
        pli = plot(noise_ceiling_upper, p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_LINE_TYPE, 'Color', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_LINE_WIDTH);
        if ~pl_has_ns_upper
            pl_has_ns_upper = true;
            j = length(pl)+1;
            pl(j) = pli;
            pl_legend{j} = 'Noise Ceiling (upper)';
        end
    end
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_LINE_TYPE)
        pli = plot(noise_ceiling_lower, p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_LINE_TYPE, 'Color', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_LINE_WIDTH);
        if ~pl_has_ns_lower
            pl_has_ns_lower = true;
            j = length(pl)+1;
            pl(j) = pli;
            pl_legend{j} = 'Noise Ceiling (lower)';
        end
    end
    
    %plot noise ceiling markers
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_TYPE)
        if p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_FILLED
            pli = plot(noise_ceiling_upper, p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_TYPE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_COLOUR, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_SIZE, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_LINE_WIDTH, 'MarkerFaceColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_FILL_COLOUR);
        else
            pli = plot(noise_ceiling_upper, p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_TYPE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_COLOUR, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_SIZE, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_UPPER_MARKER_LINE_WIDTH);
        end
        if ~pl_has_ns_upper
            pl_has_ns_upper = true;
            j = length(pl)+1;
            pl(j) = pli;
            pl_legend{j} = 'Noise Ceiling (upper)';
        end
    end
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_TYPE)
        if p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_FILLED
            pli = plot(noise_ceiling_lower, p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_TYPE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_COLOUR, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_SIZE, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_LINE_WIDTH, 'MarkerFaceColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_FILL_COLOUR);
        else
            pli = plot(noise_ceiling_lower, p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_TYPE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_COLOUR, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_SIZE, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).NOISE_CEILING_LOWER_MARKER_LINE_WIDTH);
        end
        if ~pl_has_ns_lower
            pl_has_ns_lower = true;
            j = length(pl)+1;
            pl(j) = pli;
            pl_legend{j} = 'Noise Ceiling (lower)';
        end
    end
    
    %model-specific noise ceiling lines
    if try_model_specific_noise_ceilings
        for m = 1:number_model
            if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_ENABLED) && p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_ENABLED
                upper = model_specific_noise_ceiling_upper(m,:);
                lower = model_specific_noise_ceiling_lower(m,:);
                if ~any(isnan([upper lower]))
                    
                    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_LINE_TYPE)
                        pli = plot(upper, p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_LINE_TYPE, 'Color', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_LINE_WIDTH);
                        if ~pl_has_model_ns_upper(m)
                            pl_has_model_ns_upper(m) = true;
                            j = length(pl)+1;
                            pl(j) = pli;
                            pl_legend{j} = ['Noise Ceiling (upper, ' strrep(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NAME,'_',' ') ')'];
                        end
                    end
                    
                    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_LINE_TYPE)
                        pli = plot(lower, p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_LINE_TYPE, 'Color', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_LINE_WIDTH);
                        if ~pl_has_model_ns_lower(m)
                            pl_has_model_ns_lower(m) = true;
                            j = length(pl)+1;
                            pl(j) = pli;
                            pl_legend{j} = ['Noise Ceiling (lower, ' strrep(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NAME,'_',' ') ')'];
                        end
                    end
                    
                end
            end
        end
    end
    
    %model-specific noise ceiling markers
    if try_model_specific_noise_ceilings
        for m = 1:number_model
            if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_ENABLED) && p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_ENABLED
                upper = model_specific_noise_ceiling_upper(m,:);
                lower = model_specific_noise_ceiling_lower(m,:);
                if ~any(isnan([upper lower]))
                    
                    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_TYPE)
                        if p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_FILLED
                            pli = plot(upper, p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_TYPE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_COLOUR, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_SIZE, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_LINE_WIDTH, 'MarkerFaceColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_FILL_COLOUR);
                        else
                            pli = plot(upper, p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_TYPE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_COLOUR, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_SIZE, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_UPPER_MARKER_LINE_WIDTH);
                        end
                        if ~pl_has_model_ns_upper(m)
                            pl_has_model_ns_upper(m) = true;
                            j = length(pl)+1;
                            pl(j) = pli;
                            pl_legend{j} = ['Noise Ceiling (upper, ' strrep(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NAME,'_',' ') ')'];
                        end
                    end
                    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_TYPE)
                        if p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_FILLED
                            pli = plot(lower, p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_TYPE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_COLOUR, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_SIZE, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_LINE_WIDTH, 'MarkerFaceColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_FILL_COLOUR);
                        else
                            pli = plot(lower, p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_TYPE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_COLOUR, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_SIZE, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NOISE_CEILING_LOWER_MARKER_LINE_WIDTH);
                        end
                        if ~pl_has_model_ns_lower(m)
                            pl_has_model_ns_lower(m) = true;
                            j = length(pl)+1;
                            pl(j) = pli;
                            pl_legend{j} = ['Noise Ceiling (lower, ' strrep(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NAME,'_',' ') ')'];
                        end
                    end
                    
                end
            end
        end
    end
    
    %set overrides
    model_corrs_selected_low = model_corrs_selected - error_bars_selected;
    model_corrs_selected_high = model_corrs_selected + error_bars_selected;
    override_greater_zero = false(number_voi, number_model);
    if p.CUSTOM_VOI_SUMMARY_FIGURES(c).OVERRIDE_MODEL_MARKER_SIGNIF_GREATER_ZERO
        override_greater_zero = model_corrs_selected_low > 0;
    end
    override_signif_highest = false(number_voi, number_model);
    if p.CUSTOM_VOI_SUMMARY_FIGURES(c).OVERRIDE_MODEL_MARKER_SIGNIF_HIGHEST
        for v = 1:number_voi
            [value, index] = max(model_corrs_selected_low(v,:));
            cmp = model_corrs_selected_high(v,:);
            cmp(index) = [];
            if ~any(cmp >= value)
                override_signif_highest(v,index) = true;
            end
        end
    end
    
    %determine model x positions
    if ~isfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c), 'MODEL_OFFSET_RANGE') || isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL_OFFSET_RANGE)
        p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL_OFFSET_RANGE = 0;
    end
    midpoint = mean(1:number_model);
    model_offsets = midpoint - [1:number_model];
    if any(model_offsets)
        model_offsets = model_offsets / max(model_offsets) * p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL_OFFSET_RANGE / 2 * -1;
    end
    for m = 1:number_model
        if isfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m), 'MODEL_OFFSET_OVERRIDE') && ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).MODEL_OFFSET_OVERRIDE)
            model_offsets(m) = p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).MODEL_OFFSET_OVERRIDE;
        end
    end
    
    
    %plot models
    for m = 1:number_model
        %error bars
        if p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).ERROR_BARS
            for v = 1:number_voi
                errorbar(v+model_offsets(m), model_corrs_selected(v,m), error_bars_selected(v,m), 'Color', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).ERROR_BARS_WIDTH);
            end
        end
        
        %line
        if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).LINE_TYPE)
            pli = plot((1:number_voi)+model_offsets(m),model_corrs_selected(:,m), p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).LINE_TYPE, 'Color', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).LINE_WIDTH);
            if ~pl_has_model(m)
                pl_has_model(m) = true;
                j = length(pl)+1;
                pl(j) = pli;
                pl_legend{j} = strrep(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NAME,'_',' ');
            end
        end
        
        %markers
        for v = 1:number_voi
            if override_signif_highest(v,m)
                marker = p.CUSTOM_VOI_SUMMARY_FIGURES(c).OVERRIDE_MODEL_MARKER_SIGNIF_HIGHEST_TYPE;
                marker_filled = p.CUSTOM_VOI_SUMMARY_FIGURES(c).OVERRIDE_MODEL_MARKER_SIGNIF_HIGHEST_FILLED;
            elseif override_greater_zero(v,m)
                marker = p.CUSTOM_VOI_SUMMARY_FIGURES(c).OVERRIDE_MODEL_MARKER_SIGNIF_GREATER_ZERO_TYPE;
                marker_filled = p.CUSTOM_VOI_SUMMARY_FIGURES(c).OVERRIDE_MODEL_MARKER_SIGNIF_GREATER_ZERO_FILLED;
            else
                marker = p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_TYPE;
                marker_filled = p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_FILLED;
            end
            
            if ~isempty(marker)
                if marker_filled
                    pli = plot(v+model_offsets(m), model_corrs_selected(v,m), marker, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_SIZE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_LINE_WIDTH, 'MarkerFaceColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_FILLED_COLOUR);
                else
                    pli = plot(v+model_offsets(m), model_corrs_selected(v,m), marker, 'MarkerSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_SIZE, 'MarkerEdgeColor', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).LINE_COLOUR, 'LineWidth', p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).DEFAULT_MARKER_LINE_WIDTH);
                end
                
                if ~pl_has_model(m)
                    pl_has_model(m) = true;
                    j = length(pl)+1;
                    pl(j) = pli;
                    pl_legend{j} = strrep(p.CUSTOM_VOI_SUMMARY_FIGURES(c).MODEL(m).NAME,'_',' ');
                end
            end
        end
        
    end
    
    %restrict
    axis(ax);
    %yticks
    set(gca, 'ytick', p.CUSTOM_VOI_SUMMARY_FIGURES(c).YTICKS);
    
    
    %xticks
    set(gca, 'xtick', 1:number_voi, 'xticklabel', cell(1,number_voi));
    xticklabel_rotate(1:number_voi, p.CUSTOM_VOI_SUMMARY_FIGURES(c).X_LABEL_ROTATION_DEGREES, strrep(voi_names(ind_voi),'_',' '), 'Fontsize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).FONT_SIZE);
    
    %legend
    if p.CUSTOM_VOI_SUMMARY_FIGURES(c).LEGEND_DISPLAY
        legend(pl, pl_legend, 'Location', p.CUSTOM_VOI_SUMMARY_FIGURES(c).LEGEND_LOCATION);
    end
    
    %title
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).TITLE)
        title(p.CUSTOM_VOI_SUMMARY_FIGURES(c).TITLE);
    end
    
    %yaxis label
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).YLABEL)
        ylabel(sprintf('%s\n',p.CUSTOM_VOI_SUMMARY_FIGURES(c).YLABEL));
    end
    
    %background colour
    if isfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c), 'BACKGROUND_COLOUR_OUTSIDE')
        set(gcf,'color',p.CUSTOM_VOI_SUMMARY_FIGURES(c).BACKGROUND_COLOUR_OUTSIDE);
    end
    if isfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c), 'BACKGROUND_COLOUR_INSIDE')
        set(gca,'color',p.CUSTOM_VOI_SUMMARY_FIGURES(c).BACKGROUND_COLOUR_INSIDE);
    end
    
    %font
    set(gca,'FontSize', p.CUSTOM_VOI_SUMMARY_FIGURES(c).FONT_SIZE);
    
    %re-restrict
    axis(ax);
    
    %done
    hold off
    set(fig, 'PaperPosition', [0 0 15 15]);
    saveas(fig, [saveFolUse 'Summary_' split_type '_' p.CUSTOM_VOI_SUMMARY_FIGURES(c).NAME '.png'], 'png')
    
end


%% done
close(fig)
disp Done.
cd ..

catch err
    if exist('fig','var') & ishandle(fig)
        close(fig)
    end
    cd ..
    rethrow(err)
end

%RSMs is Cond-by-Cond-by-Particpants, expected range -1 to +1
%(optional) selection is Cond-by-Cond logical where true indicates cells to include and false indicates cells to exclude
function [upper,lower,indiv_all,indiv_leaveoneout] = compute_rsm_noise_ceiling(RSMs, selection)
%checks and prep
if ndims(RSMs) ~= 3
    error('Requires 3D matrix.')
end
if any(isnan(RSMs(:)))
    error('Cannot have nan.')
end
if any(RSMs(:)==0)
    warning('Detected zeros. These are very likely to be unintended!')
end
[dim1, dim2, dim3] = size(RSMs);
n = dim1 * dim2;
if dim1 ~= dim2
    error('Requires square matrices.')
end

%0. reshape from n-by-n matrix to n^2-by-1 array
RSMs_array = cell2mat(arrayfun(@(x) reshape(RSMs(:,:,x), n, 1), 1:dim3, 'UniformOutput', false));

%apply selection
if exist('selection', 'var')
    if any(size(selection) ~= [dim1 dim2])
        error('Selection matrix must be #Cond-by#Cond')
    elseif ~islogical(selection)
        error('Selection matrix must be logical')
    end
    
    selection_index = find(selection(:));
    RSMs_array = RSMs_array(selection_index, :);
end

%1. convert to RDM
RDMs = 1 - RSMs_array;

%2. percentile transform
RDMs_pct = cell2mat(arrayfun(@(x) tiedrank(RDMs(:,x)) / n, 1:dim3, 'UniformOutput', false));

%this is not needed (and requires neuroelf toolbox)
% % %3. z transform
% % ne = neuroelf;
% % RDMs_pct_z = cell2mat(arrayfun(@(x) ne.ztrans(RDMs_pct(:,x)), 1:dim3, 'UniformOutput', false));

%4. calculate upper bound (mean correlation of each matrix to the mean matrix)
avg = nanmean(RDMs_pct, 2);
indiv_all = arrayfun(@(x) corr(RDMs_pct(:,x), avg, 'Type', 'Pearson'), 1:dim3);
upper = mean(indiv_all);

%5. calculate lower bound (mean correlation of each matrix to the leave-this-one-out matrix)
d3s = 1:dim3;
selections = arrayfun(@(x) d3s(d3s~=x), d3s, 'UniformOutput', false);
indiv_leaveoneout = arrayfun(@(x) corr(RDMs_pct(:,x), nanmean(RDMs_pct(:,selections{x}),2), 'Type', 'Pearson'), 1:dim3);
lower = mean(indiv_leaveoneout);
