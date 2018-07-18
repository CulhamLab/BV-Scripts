function Nii_Parcellation

input_file = 'Parcels_MNI_222.nii';
output_file = 'Parcels_MNI_222_SPLIT.nii'; %gzip will be applied

%read with neuroelf toolbox
nii = xff(input_file);

%get unique, non-zero values
values = unique(nii.VoxelData(nii.VoxelData ~= 0));

%convert to 4D
number_maps = length(values);
for m = 1:number_maps
    map = nii.GetVolume(1);
    ind = map(:) == values(m);
    map(~ind) = 0;
    if any(ind(:))
        map(ind) = 1;
    else
        warning('Did not find map %d!', m)
    end
    maps(:,:,:,m) = map;
    clear map
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
