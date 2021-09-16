% VOIMaskWithVMR(filepath_voi, filepath_save, filepath_vmr, vmr_range)
%
% filepath_voi      char        required        Filepath to read VOI
%
% filepath_vmr      char        required        Filepath to read VMR
%
% vmr_range         [int int]   required        Range of VMR intensities to use as mask
%
% filepath_save     char        default=[]      Filepath to write masked VOI. If empty, defaults to auto-generated.
%
% overwrite         logical     default=false   Allow overwriting if output file already exists
%
function VOIMaskWithVMR(filepath_voi, filepath_vmr, vmr_range, filepath_save, overwrite)

%% Handle inputs

if ~exist('filepath_voi', 'var')
    error('Missing input: filepath_voi');
elseif ~exist(filepath_voi, 'file')
    error('VOI does not exist: %s', filepath_voi);
end

if ~exist('filepath_vmr', 'var')
    error('Missing input: filepath_vmr');
elseif ~exist(filepath_vmr, 'file')
    error('VMR does not exist: %s', filepath_vmr);
end

if ~exist('vmr_range', 'var')
    error('Missing input: vmr_range');
elseif length(vmr_range) ~= 2
    error('VMR range requires exactly 2 values')
elseif ~isint(vmr_range)
    error('VMR range values must be integers')
end

if ~exist('filepath_save', 'var')
    [voi_fol,voi_name] = fileparts(filepath_voi);
    [~,vmr_name] = fileparts(filepath_vmr);
    filepath_save = sprintf('%s%s%s_Mask-%s-%d-to-%d.voi', voi_fol, filesep, voi_name, vmr_name, vmr_range);
end

if ~exist('overwrite', 'var')
    overwrite = false;
end

%% Check Overwrite

if exist(filepath_save, 'file') && ~overwrite
    error('Output file already exists and overwrite is false')
end

%% Make Output Folder

fol = fileparts(filepath_save);
if ~isempty(fol) && ~exist(fol, 'dir')
    mkdir(fol);
end

%% Apply

%load vmr
vmr = xff(filepath_vmr);

%check vmr assumptions
bb = vmr.BoundingBox;
if any(bb.ResXYZ ~= 1)
    error('VMR must be 1mm iso')
elseif any(bb.DimXYZ ~= 256)
    error('VMR must be 256 cube')
end

%load voi
voi = xff(filepath_voi);

%apply masking
for v = 1:voi.NrOfVOIs
    coord = 128 - voi.BVCoords(v, bb) + 1;
    ind = sub2ind(bb.DimXYZ, coord(:,2), coord(:,3), coord(:,1));
    intensities = vmr.VMRData(ind);
    ind_keep = intensities>=vmr_range(1) & intensities<=vmr_range(2);
    voi.VOI(v).Voxels = voi.VOI(v).Voxels(ind_keep,:);
    voi.VOI(v).NrOfVoxels = size(voi.VOI(v).Voxels, 1);
end

%% Save
fprintf('Writing: %s\n', filepath_save);
voi.SaveAs(filepath_save);

%% Cleanup
voi.ClearObject;
vmr.ClearObject;
