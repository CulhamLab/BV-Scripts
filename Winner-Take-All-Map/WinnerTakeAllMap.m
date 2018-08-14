% Inputs:
% filepath_glm - filepath to the glm to extract betas from
% filepath_vtc - filepath to any related vtc to get dimensions for output vmp
% filepath_vmp - filepath to write output vmp to
%
% Output:
% A vmp with a map for each predictor of interest indicating voxels where
% it has the highest beta. Excludes voxels with max betas < thresh.
function WinnerTakeAllMap(filepath_glm, filepath_vtc, filepath_vmp)

%%
thresh = 3;

%%
glm = xff(filepath_glm);
vtc = xff(filepath_vtc);
vmp = xff('vmp');

copy_fields = {'Resolution' 'XStart' 'XEnd' 'YStart' 'YEnd' 'ZStart' 'ZEnd'};
for f = 1:length(copy_fields)
    eval(sprintf('vmp.%s = vtc.%s;', copy_fields{f}, copy_fields{f}));
end

num_pred_use = glm.NrOfPredictors - glm.NrOfConfounds;
preds = arrayfun(@(x) glm.Predictor(x).Name2, 1:num_pred_use, 'UniformOutput', false);

betas = glm.GLMData.BetaMaps(:,:,:,1:num_pred_use);
winners = CalcWinners(betas, thresh);

colours = round(jet(num_pred_use) * 255);

for p = 1:num_pred_use
    vmp.Map(p) = vmp.Map(1); %defaults
    
    vmp.Map(p).Name = preds{p};
    vmp.Map(p).LowerThreshold = 0;
    vmp.Map(p).UseRGBColor = true;
    vmp.Map(p).RGBLowerThreshPos = colours(p,:);
    vmp.Map(p).RGBUpperThreshPos = colours(p,:);
    
    vmp.Map(p).VMPData = (winners == p);
end

vmp.NrOfMaps = num_pred_use;

vmp.SaveAs(filepath_vmp);

function [winners] = CalcWinners(betas, thresh)
[sx, sy, sz, num_pred_use] = size(betas);
winners = zeros(sx,sy,sz);

for x = 1:sx
    for y = 1:sy
        for z = 1:sz
            b = betas(x,y,z,:);
            [m, ind] = max(b);
            if m >= thresh
                winners(x,y,z) = ind;
            end
        end
    end
end