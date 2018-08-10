function ROI_STEP9_figure_barGraph

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
load([readFolB 'VOI_corrs_organized'])

%range
% temp = mean(corrs_split_organized,1);
% ran = [min(temp(:)) max(temp(:))];
% ran = [ran(1)-(range(ran)*0.1) ran(2)+(range(ran)*0.1)];
ran = [-0.4 +1];

%required methods
try
cd 'Required Methods'

%fig
fig = figure('Position', get(0,'ScreenSize'));
num_model = size(corrs_split_organized, 2);
for voi = 1:length(VOI_type_names)
    RSMs = rsms_split_organized(:,:,:,voi);
    
    [upper,lower] = compute_rsm_noise_ceiling(RSMs);
    model_corrs = corrs_split_organized(:,:,voi);
    model_corrs_avg = mean(model_corrs, 1);
    
    s = std(model_corrs,1) / sqrt(size(model_corrs,1));
    eb = 1.96 * s;
    
    v = [0 num_model+1 ran];
    clf
    hold on
    rectangle('Position', [v(1), lower, v(2), upper-lower], 'FaceColor', [127 127 127]/255)
    bar(model_corrs_avg)
    errorbar(1:length(model_corrs_avg), model_corrs_avg, eb, 'k.')
    hold off
    axis(v);
    set(gca, 'XTick', 1:num_model, 'XTickLabel', strrep(p.MODELS.names,'_',' '));
    xticklabel_rotate([], 30, [], 'Fontsize', 10);
    ylabel('Mean Correlation (r-value)')
    title(strrep(VOI_type_names{voi},'_',' '))
    
    if saveFol(1) == '.' %is a relative path
        saveFolUse = ['..' filesep saveFol];
    else
        saveFolUse = saveFol;
    end
    
    saveas(fig, [saveFolUse strrep(VOI_type_names{voi},' ','_') '.png'], 'png')
end

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

%RSMs is C-by-C-by-P for C-many conditions and P-many participants, expected range -1 to +1
function [upper,lower] = compute_rsm_noise_ceiling(RSMs)
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
