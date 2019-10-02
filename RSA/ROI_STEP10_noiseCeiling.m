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
    selection_for_base_ceiling = ones(p.NUMBER_OF_CONDITIONS, p.NUMBER_OF_CONDITIONS);
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
    
    [upper,lower] = compute_rsm_noise_ceiling(RSMs, selection_for_base_ceiling);
    model_corrs = corrs_use(:,:,voi);
    model_corrs_avg = mean(model_corrs, 1);
    
    s = std(model_corrs,1) / sqrt(size(model_corrs,1));
    eb = 1.96 * s;
    
    if do_model_specifc_ceiling
        model_specific_upper(:,voi) = nan(1, num_model);
        model_specific_lower(:,voi) = nan(1, num_model);
        for m = submatrix_model_inds
            [model_specific_upper(m,voi), model_specific_lower(m,voi)] = compute_rsm_noise_ceiling(RSMs, ~isnan(models_use{m}));
        end
    end
    
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
    
    if saveFol(1) == '.' %is a relative path
        saveFolUse = ['..' filesep saveFol];
    else
        saveFolUse = saveFol;
    end
    
    saveas(fig, [saveFolUse t '.png'], 'png')
    
    model_corrs_avg_all(voi,:) = model_corrs_avg;
    errorbars_all(voi,:) = eb;
    upper_all(voi) = upper;
    lower_all(voi) = lower;
end

%% new figure
clf

xls = cell(0);
xls(3:(2+length(voi_names))) = voi_names;
row = 1;
num_voi = length(upper_all);

c=0;
hold on

c=c+1;
pl(c) = plot(upper_all, '.--', 'Color', [0 0 0]);
leg{c} = 'Noise (upper)';
row = row + 1;
xls{row,1} = 'Noise Ceiling';
xls{row,2} = 'Upper';
xls(row,3:(2+num_voi)) = num2cell(upper_all);

c=c+1;
pl(c) = plot(lower_all, '.:', 'Color', [0 0 0]);
leg{c} = 'Noise (lower)';
row = row + 1;
xls{row,1} = 'Noise Ceiling';
xls{row,2} = 'Lower';
xls(row,3:(2+num_voi)) = num2cell(lower_all);

colours = jet(num_model);
for m = 1:num_model
    c=c+1;
	rvals = model_corrs_avg_all(:,m);
    pl(c) = plot(rvals, '.-', 'Color', colours(m,:));
    leg{c} = strrep(p.MODELS.names{m},'_',' ');
    
	ebs = errorbars_all(:,m);
    errorbar(1:length(voi_names), rvals, ebs, 'Color', colours(m,:))
	
	row = row + 1;
	xls{row,1} = p.MODELS.names{m};
	xls{row,2} = 'mean r-value';
	xls(row,3:(2+num_voi)) = num2cell(rvals);
	
	row = row + 1;
	xls{row,1} = p.MODELS.names{m};
	xls{row,2} = '95% CI +-';
	xls(row,3:(2+num_voi)) = num2cell(ebs);
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

xls_fp = [saveFolUse 'Summary_' split_type '.xlsx'];
if exist(xls_fp,'file')
	delete(xls_fp)
end
xlswrite(xls_fp, xls);

%done
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
function [upper,lower] = compute_rsm_noise_ceiling(RSMs, selection)
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
corrs = arrayfun(@(x) corr(RDMs_pct(:,x), avg, 'Type', 'Pearson'), 1:dim3);
upper = mean(corrs);

%5. calculate upper bound (mean correlation of each matrix to the leave-this-one-out matrix)
d3s = 1:dim3;
selections = arrayfun(@(x) d3s(d3s~=x), d3s, 'UniformOutput', false);
corrs = arrayfun(@(x) corr(RDMs_pct(:,x), nanmean(RDMs_pct(:,selections{x}),2), 'Type', 'Pearson'), 1:dim3);
lower = mean(corrs);
