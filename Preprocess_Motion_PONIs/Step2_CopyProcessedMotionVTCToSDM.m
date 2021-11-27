function Step2_CopyProcessedMotionVTCToSDM

%% Load
load('Step1_CopyMotionMeasuresSDMToVTC.mat');

vtc = xff('Step1_CopyMotionMeasuresSDMToVTC_THPGLMF3c.vtc');
preprocessed_motion = vtc.VTCData;
vtc.ClearObject;

p.SUFFIX = '_THPGLMF3c';
p.ZSCORE = true;

if p.ZSCORE
    p.SUFFIX = [p.SUFFIX '_ZSCORE'];
end

sdm_paths_out = cellfun(@(x)[x(1:end-4) p.SUFFIX '.sdm'], sdm_paths, 'UniformOutput', false);

%% Adjust

preprocessed_motion(~preprocessed_motion) = nan;
preprocessed_motion = preprocessed_motion - p.ADJUST_ADD;
preprocessed_motion = preprocessed_motion / p.ADJUST_MULTIPLY;
preprocessed_motion = preprocessed_motion(:,:,:,1);

%% Z-score

preprocessed_motion_zscore = nan(size(preprocessed_motion));
for m = 1:size(preprocessed_motion,2)
    for s = 1:size(preprocessed_motion,3)
        measure = preprocessed_motion(1:sdm_vol(s), m, s);
        measure = zscore(measure);
        preprocessed_motion_zscore(1:sdm_vol(s), m, s) = measure;
    end
end

%% Create New SDMs

for s = 1:sdm_count
    fprintf('Processsing %d of %d: %s\n', s, sdm_count, sdm_paths_out{s});
    
    if p.ZSCORE
        motion = preprocessed_motion_zscore(1:sdm_vol(s), :, s);
    else
        motion = preprocessed_motion(1:sdm_vol(s), :, s);
    end
    
    sdm = xff(sdm_paths{s});
    sdm.SDMMatrix = motion;
    sdm.SaveAs(sdm_paths_out{s});
    sdm.ClearObject;
end

%% Done
save('Step2_CopyProcessedMotionVTCToSDM', 'p', 'sdm_paths', 'sdm_count', 'sdm_vol', 'all_motion', 'sdm_paths_out', 'preprocessed_motion', 'preprocessed_motion_zscore');
disp Done.