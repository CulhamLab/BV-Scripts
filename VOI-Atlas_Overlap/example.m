% Filepaths to the 2 VOI files
filepath_VOI_atlas = 'S:\Brain Atlases\BV Julich-Brain Cytoarchitectonic Atlas\Julich_Sort-by-Region_BV2MNI_NoGapMap_withFusGHemis.voi';
filepath_VOI_target = 'D:\Dropbox\Work\Culham\Kress\Cluster_Atlas_Overlap\all_clusters.voi';

% Output filename prefix
output_filename_prefix = 'Clusters_Julich';

% Call function
VOI_atlas_overlap(filepath_VOI_atlas=filepath_VOI_atlas, ...
                  filepath_VOI_target=filepath_VOI_target, ...
                  output_filename_prefix=output_filename_prefix)