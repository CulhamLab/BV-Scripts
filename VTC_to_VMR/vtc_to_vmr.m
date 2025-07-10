function vtc_to_vmr(fp_vtc, fp_vmr, opt)

arguments
    fp_vtc              (1,:) {mustBeTextScalar}                            % filepath to VTC
    fp_vmr              (1,:) {mustBeTextScalar}                            % filepath of VMR to create
    opt.volume          (1,1) {mustBePositive, mustBeInteger}       = 1     % which volume to draw
    opt.data_threshold  (1,1) {mustBeNonnegative}                   = 500   % values below this threshold are ignored
    opt.int_min         (1,1) {mustBeNonnegative, mustBeInteger}    = 0     % minimum insensity of non-missing values in VMR
    opt.int_range       (1,1) {mustBePositive, mustBeInteger}       = 225   % range of intensities for non-missing values in VMR
end

%% Intensity values must be valid
if (opt.int_min + opt.int_range) > 255
    error("(int_min + int_range) must be 255 or less")
end

%% Paths must be char arrays (not strings)
if isstring(fp_vtc)
    fp_vtc = fp_vtc.char;
end
if isstring(fp_vmr)
    fp_vmr = fp_vmr.char;
end

%% Read

vtc = xff(fp_vtc);

%% Run

%sample rate based on resolution
sr = 1 / vtc.Resolution;

%read vol from vtc
data = squeeze(vtc.VTCData(opt.volume,:,:,:));

%meshgrids for trilinear interp
s = size(data);
[x,y,z] = meshgrid(1:s(2), 1:s(1), 1:s(3));
[x2,y2,z2] = meshgrid(1:sr:s(2), 1:sr:s(1), 1:sr:s(3));

%trilinear interp vtc data
data_interp = interp3(x,y,z,data,x2,y2,z2);

%find voxels with valid data
has_value = data_interp >= opt.data_threshold;

%calculate percentile
data_interp_pct = (data_interp - min(data_interp(has_value))) / range(data_interp(has_value));
data_interp_pct(data_interp_pct<0) = 0;

%set intensity
data2 = uint8(opt.int_min + (opt.int_range * data_interp_pct));

%zero-out voxels that had zero
data2(~has_value) = 0;

%add padding
x_range = vtc.XEnd - vtc.XStart;
data2(end+1:x_range, :, :) = opt.int_min;
y_range = vtc.YEnd - vtc.YStart;
data2(:, end+1:y_range, :) = opt.int_min;
z_range = vtc.ZEnd - vtc.ZStart;
data2(:, :, end+1:z_range) = opt.int_min;

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