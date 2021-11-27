function Step1_CopyMotionMeasuresTSVToVTC

%% Parameters
p.DIR_TSV = 'D:\OneDrive - The University of Western Ontario\Jaana\SDM_v2\fmriprep_regressors';

p.NUMBER_VOLUMES = 452;
p.TR = 1000;
p.ADJUST_MULTIPLY = 1;
p.ADJUST_ADD = 500;

p.ALLOW_FEWER_VOL = true; %USES IMPERFECT WORKAROUND, NOT SUITABLE FOR LARGE DIFFERENCES

%% Prep
if p.DIR_TSV(end) ~= filesep
    p.DIR_TSV(end+1) = filesep;
end

%% Find
tsv_paths = dir([p.DIR_TSV '*.tsv']);
tsv_paths = arrayfun(@(x) [x.folder filesep x.name], tsv_paths, 'UniformOutput', false);
tsv_count = length(tsv_paths);
fprintf('Found %d TSVs to process...\n', tsv_count);

%% Load SDM Data

fprintf('Loading TSVs into VTC...\n');

vtc = xff('vtc');
vtc.NameOfSourceFMR = 'test.fmr';
vtc.NameOfLinkedPRT = 'test.prt';
vtc.FileVersion = 3;
vtc.DataType = 2;
vtc.Resolution = 1;
vtc.ReferenceSpace = 4;
vtc.TR = p.TR;
vtc.NrOfVolumes = p.NUMBER_VOLUMES;
vtc.VTCData = nan(p.NUMBER_VOLUMES, 6, tsv_count, 2, 'single');
vtc.XStart = 1;
vtc.YStart = 1;
vtc.ZStart = 1;
vtc.XEnd = vtc.XStart + size(vtc.VTCData,2);
vtc.YEnd = vtc.YStart + size(vtc.VTCData,3);
vtc.ZEnd = vtc.ZStart + size(vtc.VTCData,4);

all_motion = nan(p.NUMBER_VOLUMES, 6, tsv_count);

cond_names = {'trans_x' 'trans_y' 'trans_z' 'rot_x' 'rot_y' 'rot_z'};

for s = 1:tsv_count
    tsv = readtable(tsv_paths{s}, 'FileType', 'text');
    motion = cell2mat(cellfun(@(x) getfield(tsv, x), cond_names, 'UniformOutput', false));
    
    tsv_vol(s) = size(motion,1);
    
    if (tsv_vol(s) < p.NUMBER_VOLUMES) && p.ALLOW_FEWER_VOL
        nvol_add = p.NUMBER_VOLUMES - tsv_vol(s);
        motion(end+1:p.NUMBER_VOLUMES,:) = repmat(motion(end,:), [nvol_add 1]);
        fprintf('WARNING: added %d duplicate volumes at the end of %s\n', nvol_add, tsv_paths{s})
    elseif tsv_vol(s) ~= p.NUMBER_VOLUMES
        error('sdm contains incrrect number of volumes (%d): %s\n', tsv_vol(s), tsv_paths{s});
    end
    
    all_motion(:, :, s) = motion;
    
    motion = (motion * p.ADJUST_MULTIPLY) + p.ADJUST_ADD;
    vtc.VTCData(:, :, s, 1) = motion;
end

%% Save

fprintf('Writing VTC file...\n');
vtc.SaveAs('Step1_CopyMotionMeasuresSDMToVTC.vtc');
save('Step1_CopyMotionMeasuresSDMToVTC', 'p', 'tsv_paths', 'tsv_count', 'tsv_vol', 'all_motion', 'cond_names');

%% Cleanup
vtc.ClearObject;
fprintf('VTC must be preprocessed before running step 2.\n');