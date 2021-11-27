function Step1_CopyMotionMeasuresSDMToVTC

%% Parameters
p.DIR_BIDS = 'D:\Psych9223\Data\Localizer';

p.NUMBER_VOLUMES = 340;
p.TR = 1000;
p.ADJUST_MULTIPLY = 1;
p.ADJUST_ADD = 500;

p.ALLOW_FEWER_VOL = true; %USES IMPERFECT WORKAROUND, NOT SUITABLE FOR LARGE DIFFERENCES

%% Prep
if p.DIR_BIDS(end) ~= filesep
    p.DIR_BIDS(end+1) = filesep;
end

%% Find

%participants
list = dir([p.DIR_BIDS 'sub-*']);
list = list([list.isdir]);
participant_names = {list.name};
participant_count = length(participant_names);

%runs per participants
sdm_paths = cell(0);
for par = 1:participant_count
    list = dir([p.DIR_BIDS 'derivatives' filesep participant_names{par} filesep 'ses-01' filesep 'func' filesep participant_names{par} '_ses-01_task-Localizer_run-*_bold_SCCTBL_3DMC.sdm']);
    sdm_paths = [sdm_paths ;arrayfun(@(x) [x.folder filesep x.name], list, 'UniformOutput', false)];
end
sdm_count = length(sdm_paths);
fprintf('Found %d SDMs to process...\n', sdm_count);

%% Load SDM Data

fprintf('Loading SDMs into VTC...\n');

vtc = xff('vtc');
vtc.NameOfSourceFMR = 'test.fmr';
vtc.NameOfLinkedPRT = 'test.prt';
vtc.FileVersion = 3;
vtc.DataType = 2;
vtc.Resolution = 1;
vtc.ReferenceSpace = 4;
vtc.TR = p.TR;
vtc.NrOfVolumes = p.NUMBER_VOLUMES;
vtc.VTCData = nan(p.NUMBER_VOLUMES, 6, sdm_count, 2, 'single');
vtc.XStart = 1;
vtc.YStart = 1;
vtc.ZStart = 1;
vtc.XEnd = vtc.XStart + size(vtc.VTCData,2);
vtc.YEnd = vtc.YStart + size(vtc.VTCData,3);
vtc.ZEnd = vtc.ZStart + size(vtc.VTCData,4);

all_motion = nan(p.NUMBER_VOLUMES, 6, sdm_count);

for s = 1:sdm_count
    sdm = xff(sdm_paths{s});
    motion = sdm.SDMMatrix;
    sdm.ClearObject;
    
    sdm_vol(s) = size(motion,1);
    
    if (sdm_vol(s) < p.NUMBER_VOLUMES) && p.ALLOW_FEWER_VOL
        nvol_add = p.NUMBER_VOLUMES - sdm_vol(s);
        motion(end+1:p.NUMBER_VOLUMES,:) = repmat(motion(end,:), [nvol_add 1]);
        fprintf('WARNING: added %d duplicate volumes at the end of %s\n', nvol_add, sdm_paths{s})
    elseif sdm_vol(s) ~= p.NUMBER_VOLUMES
        error('sdm contains incrrect number of volumes (%d): %s\n', sdm_vol(s), sdm_paths{s});
    end
    
    all_motion(:, :, s) = motion;
    
    motion = (motion * p.ADJUST_MULTIPLY) + p.ADJUST_ADD;
    vtc.VTCData(:, :, s, 1) = motion;
end

%% Save

fprintf('Writing VTC file...\n');
vtc.SaveAs('Step1_CopyMotionMeasuresSDMToVTC.vtc');
save('Step1_CopyMotionMeasuresSDMToVTC', 'p', 'sdm_paths', 'sdm_count', 'sdm_vol', 'all_motion');

%% Cleanup
vtc.ClearObject;
fprintf('VTC must be preprocessed before running step 2.\n');