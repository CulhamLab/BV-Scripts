function [corrs] = correlate_models

p = ALL_STEP0_PARAMETERS;

num_model = length(p.MODELS.names);

%prepare half matrices WITH DIAGONAL
for m = 1:num_model
    for i = 1:p.NUMBER_OF_CONDITIONS
        p.MODELS.matrices{m}((i+1):end,i) = nan;
    end
end

for m1 = 1:num_model
    mat1 = p.MODELS.matrices{m1};
for m2 = 1:num_model
    mat2 = p.MODELS.matrices{m2};
    
    notnans = ~isnan(mat1(:)) & ~isnan(mat2(:));
    
    if ~any(notnans(:))
        corrs(m1,m2) = inf;
    elseif ~any(diff(mat1(notnans))) | ~any(diff(mat2(notnans)))
        corrs(m1,m2) = inf;
    else
        corrs(m1,m2) = corr(mat1(notnans),mat2(notnans),'Type','Spearman');
        if isnan(corrs(m1,m2))
            corrs(m1,m2) = 1;
        end
    end
    
end
end

fig = figure('Position', get(0,'ScreenSize'));
imagesc(corrs)
axis image
colorbar
caxis([-1 +1.05])

cmap = jet(100);
cmap(end+1,:) = [0 0 0];
colormap(cmap)

labels = arrayfun(@(x) sprintf('%d-%s', x, strrep(p.MODELS.names{x},'_','-')), 1:num_model, 'UniformOutput', false); 
set(gca,'ytick',1:num_model,'yticklabel',labels,'xtick',1:num_model)

saveas(fig, 'model_corrs.png', 'png')
close(fig);

%excel output
xls = cell(size(corrs)+1);
xls(2:end,2:end) = num2cell(corrs);
xls(2:end,1) = labels;
xls(1,2:end) = labels;
xlswrite('model_corrs.xls', xls);
