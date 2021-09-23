% VTCTemporalSNR(filename_vtc, filename_vmp)
%
% Creates a VMP with a single map containing the voxelwise temporal SNR
% of the VTC, calculated as [Mean / Standard Deviation] across volumes.
% Ignores 0's and NaN values. Requires NeuroElf toolbox.
%
% INPUTS:
%
%   filename_vtc    char    required    Filepath to VTC.
%
%   filename_vmp    char    optional    Filepath to write output VMP. Defaults to same folder/naming as VTC with "_TemporalSD" suffix.
%
function VTCTemporalSNR(filename_vtc, filename_vmp)

%% Inputs

if ~exist('filename_vtc', 'var')
    error('Missing input: filename_vtc');
end

if ~exist('filename_vmp', 'var') || isempty(filename_vmp)
    filename_vmp = [filename_vtc(1:end-4) '_TemporalSD.vmp'];
end

%% Check Files
if exist(filename_vmp, 'file')
    error('Output file already exists: %s', filename_vmp)
end

if ~exist(filename_vtc, 'file')
    error('Input file does not exist: %s', filename_vtc);
end

%% Process

%load vtc
vtc = xff(filename_vtc);

%set zero to nan
vtc.VTCData(vtc.VTCData==0) = nan;

%new vmp
vmp = xff('new:vmp');

%copy dims
fields_to_copy = {'Resolution' 'XStart' 'XEnd' 'YStart' 'YEnd' 'ZStart' 'ZEnd'};
for f = 1:length(fields_to_copy)
    fname = fields_to_copy{f};
    vmp = setfield(vmp, fname, getfield(vtc, fname));
end

%init map
vmp.Map.Name = 'Temporal SD';
vmp.Map.DF1 = 1; %not needed
vmp.Map.BonferroniValue = 1; %not needed

%calculate temporal SD map
vmp.Map.VMPData = squeeze( nanmean(vtc.VTCData, 1) ./ nanstd(vtc.VTCData, 1) );

%set thresholds
vmp.Map.LowerThreshold = nanmin(vmp.Map.VMPData(:));
vmp.Map.UpperThreshold = nanmax(vmp.Map.VMPData(:));

%set nan to 0
vmp.Map.VMPData(isnan(vmp.Map.VMPData)) = 0;

%% Save
fprintf('Saving: %s\n', filename_vmp);
vmp.SaveAs(filename_vmp);

%% Cleanup
vmp.ClearObject;
vtc.ClearObject;

%% Done
disp Done.
