% Creates a VMP (1 map) from the specified volume of a VTC

%% Parameters
fp_vtc = 'D:\Culham Lab\Pacman\derivatives\sub-01\ses-01\func\sub-01_ses-01_task-Pacman_run-01_bold_SCCTBL_3DMCTS_MNI.vtc';
vol = 1;
fp_vmp_out = sprintf('%s_Vol-%d.vmp', fp_vtc(1:end-4), vol);

%% Load VTC
vtc = xff(fp_vtc);

%% Create VMP
vmp = xff('vmp');

%resolution and bounding box
for f = ["Resolution" "XStart" "XEnd" "YStart" "YEnd" "ZStart" "ZEnd"]
    vmp = setfield(vmp, f.char, vtc.(f.char));
end

%map name
vmp.Map.Name = sprintf('Vol-%d', vol);

%fill map with volume
vmp.Map.VMPData = squeeze(vtc.VTCData(vol,:,:,:));
vmp.Map.ShowPositiveNegativeFlag = 3;

%set colour limits
vmp.Map.LowerThreshold = nanmin(vmp.Map.VMPData(vmp.Map.VMPData(:) > 0));
vmp.Map.UpperThreshold = nanmax(vmp.Map.VMPData(:));

%% Save
vmp.SaveAs(fp_vmp_out);

%% Cleanup
vmp.ClearObject;
vtc.ClearObject;
