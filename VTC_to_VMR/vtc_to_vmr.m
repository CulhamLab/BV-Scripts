function vtc_to_vmr(fp_vtc, fp_vmr, vol)

%% Param

%intensities
int_min = 33;
int_range = 192;

%% Read

vtc = xff(fp_vtc);

%% Run

%sample rate based on resolution
sr = 1 / vtc.Resolution;

%read vol from vtc
data = squeeze(vtc.VTCData(vol,:,:,:));

%record voxels with zero
ind_zero = single(~data);

%meshgrids for trilinear interp
s = size(data);
[x,y,z] = meshgrid(1:s(2), 1:s(1), 1:s(3));
[x2,y2,z2] = meshgrid(1:sr:s(2), 1:sr:s(1), 1:sr:s(3));

%trilinear interp vtc data
data2 = interp3(x,y,z,data,x2,y2,z2);

%set intensity
data2 = min(data2 / (max(data2(:))/2), 1);
data2 = uint8(int_min + (data2 * int_range));

%zero-out voxels that had zero
data2_zero = interp3(x,y,z,ind_zero,x2,y2,z2);
data2(data2_zero>0.33) = int_min;

%add padding
x_range = vtc.XEnd - vtc.XStart;
data2(end+1:x_range, :, :) = int_min;
y_range = vtc.YEnd - vtc.YStart;
data2(:, end+1:y_range, :) = int_min;
z_range = vtc.ZEnd - vtc.ZStart;
data2(:, :, end+1:z_range) = int_min;

%xyz coord
xs = (vtc.XStart+1) : vtc.XEnd;
ys = (vtc.YStart+1) : vtc.YEnd;
zs = (vtc.ZStart+1) : vtc.ZEnd;

%save in vmr
vmr = xff('vmr');
vmr.VMRData(xs, ys, zs) = data2;
vmr.SaveAs(fp_vmr);

%% Clean
vmr.ClearObject;
vtc.ClearObject;