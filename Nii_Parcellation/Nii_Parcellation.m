function Nii_Parcellation

input_file = 'Yeo2011_7Networks_MNI152_FreeSurferConformed1mm.nii.gz';
output_file = 'Yeo2011_7Networks_MNI152_FreeSurferConformed1mm_Split.nii'; %gzip will be applied

%read with neuroelf toolbox
nii = xff(input_file);

%get unique, non-zero values
values = unique(nii.VoxelData(nii.VoxelData ~= 0));

%convert to 4D
number_maps = length(values);
for m = 1:number_maps
    map = nii.VoxelData;
    map(map ~= values(m)) = 0;
    maps(:,:,:,m) = map;
end
nii.VoxelData = maps;

%save and close
nii.SaveAs(output_file);
nii.clear;

%gzip
gzip(output_file);
delete(output_file);

%done
disp Done.
