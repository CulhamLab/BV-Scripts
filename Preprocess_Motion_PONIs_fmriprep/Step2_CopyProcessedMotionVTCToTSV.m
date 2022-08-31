function Step2_CopyProcessedMotionVTCToTSV

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

fol_out = [pwd filesep 'TSV' p.SUFFIX filesep];
if ~exist(fol_out, 'dir')
    mkdir(fol_out);
end

[~,filenames] = fileparts(tsv_paths);
tsv_paths_out = cellfun(@(x) [fol_out x p.SUFFIX '.tsv'], filenames, 'UniformOutput', false);

cond_names_out = cellfun(@(x) [x p.SUFFIX], cond_names, 'UniformOutput', false);

%% Adjust

preprocessed_motion = preprocessed_motion(:,:,:,1);
preprocessed_motion(~preprocessed_motion) = nan;
preprocessed_motion = preprocessed_motion - p.ADJUST_ADD;
preprocessed_motion = preprocessed_motion / p.ADJUST_MULTIPLY;

%% Z-score

preprocessed_motion_zscore = nan(size(preprocessed_motion));
for m = 1:size(preprocessed_motion,2)
    for s = 1:size(preprocessed_motion,3)
        measure = preprocessed_motion(1:tsv_vol(s), m, s);
        measure = zscore(measure);
        preprocessed_motion_zscore(1:tsv_vol(s), m, s) = measure;
    end
end

%% Create New SDMs

for s = 1:tsv_count
    tsv = readtable(tsv_paths{s}, 'FileType', 'text');
    
    for i = 1:length(cond_names)
        values = preprocessed_motion_zscore(1:tsv_vol(s), i, s);
        tsv = setfield(tsv, cond_names_out{i}, values);
    end
    
    writetable(tsv, tsv_paths_out{s}, 'FileType', 'text' ,'Delimiter', '\t');
end

%% Done
save('Step2_CopyProcessedMotionVTCToSDM', 'p', 'tsv_paths', 'tsv_count', 'tsv_vol', 'all_motion', 'tsv_paths_out', 'preprocessed_motion', 'preprocessed_motion_zscore', 'cond_names_out');
disp Done.