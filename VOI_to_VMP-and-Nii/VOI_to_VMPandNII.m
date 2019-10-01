function VOI_to_VMPandNII

[fn_in,fol] = uigetfile('*.voi','Select VOI(s)','voi(s)');
filename = fn_in(1:find(fn_in=='.',1,'last')-1);
fp_out = [fol filename '.vmp'];
fp_out_nii = [fol filename '.nii'];

voi = xff([fol fn_in]);

vmp = xff('vmp');

vmp.Resolution = voi.OriginalVMRResolutionX;
%vmp.NativeResolutionFile = 0;
vmp.FileVersion = 5;

vmp.XStart = 0;
vmp.XEnd = 256;

vmp.YStart = 0;
vmp.YEnd = 256;

vmp.ZStart = 0;
vmp.ZEnd = 256;

% map_empty = zeros(length(vmp.XStart:vmp.XEnd),length(vmp.YStart:vmp.YEnd),length(vmp.ZStart:vmp.ZEnd));
map_empty = zeros(256, 256, 256);

for v = 1:voi.NrOfVOIs
    if v>1
        vmp.Map(v) = vmp.Map(v-1);
    end
    
    name = voi.VOI(v).Name;
    voxels = voi.VOI(v).Voxels;
    
    voxels=(voxels*-1) + (256/2);
    voxels=[voxels(:,2)-vmp.XStart voxels(:,3)-vmp.YStart voxels(:,1)-vmp.ZStart]+1;
    
    map = map_empty;
    ind = sub2ind(size(map),voxels(:,1),voxels(:,2),voxels(:,3));
    map(ind) = 1;
    
    vmp.Map(v).Name = name;
    vmp.Map(v).LowerThreshold = 0;
    vmp.Map(v).UpperThreshold = 1;
    vmp.Map(v).ShowPositiveNegativeFlag = 1;
    vmp.Map(v).VMPData = map;
end

vmp.NrOfMaps = length(vmp.Map);

vmp.SaveAs(fp_out);
vmp.ExportNifti(fp_out_nii);

vmp = xff('vmp');
voi.ClearObject;