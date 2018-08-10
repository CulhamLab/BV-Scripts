function correlate_models

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
        corrs(m1,m2) = nan;
    else
        corrs(m1,m2) = corr(mat1(notnans),mat2(notnans),'Type','Spearman');
    end
end
end

corrs