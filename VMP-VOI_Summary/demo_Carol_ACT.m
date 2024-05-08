%% output folder
fol_out = "D:\Synology\CulhamLab\Projects\CurrentProjects\CC_fMRI_FoodImages\ACT\BV-Files\VMP-VOI_Summary\";
if ~exist(fol_out, "dir")
    mkdir(fol_out)
end

%% shared parameters
min_pct_voxels = 10;

%% run
for voi = ["Glasser" "JulichLH"]
    switch voi
        case "Glasser"
            fp_in_voi = "D:\Synology\CulhamLab\Projects\CurrentProjects\CC_fMRI_FoodImages\ACT\BV-Files\MNI_Glasser_HCP_v1.0_Sort-by-Region.voi";
        case "JulichLH"
            fp_in_voi = "D:\Synology\CulhamLab\Projects\CurrentProjects\CC_fMRI_FoodImages\ACT\BV-Files\Julich_v29_ICBM152_LH_reorder_RenameRecolour_BV2MNI.voi";
        otherwise
            error
    end

    for vmp = ["Searchlight" "FoodMinusOther" "FoodObjAnimalMinusScambled"]
        switch vmp
            case "Searchlight"
                fp_in_vmp = "D:\Synology\CulhamLab\Projects\CurrentProjects\CC_fMRI_FoodImages\ACT\BV-Files\Searchlight_TTEST_TMAP_CoSMoMVPA_MSK-ICBM452-IN-MNI152-SPACE_BRAIN.vmr_FDR_MultiMap.vmp";
                map_index = 1;
                vmp_threshold = 3.0930;
                vmp_threshold_suffix = "(FDR)";
            case "FoodMinusOther"
                fp_in_vmp = "D:\Synology\CulhamLab\Projects\CurrentProjects\CC_fMRI_FoodImages\ACT\BV-Files\Food_minus_other_Localizer.vmp";
                map_index = 1;
                vmp_threshold = 3;
                vmp_threshold_suffix = "(not-FDR)";
            case "FoodObjAnimalMinusScambled"
                fp_in_vmp = "D:\Synology\CulhamLab\Projects\CurrentProjects\CC_fMRI_FoodImages\ACT\BV-Files\FoodObjAnimal_minus_Scambled_Localizer.vmp";
                map_index = 1;
                vmp_threshold = 3.8680;
                vmp_threshold_suffix = "(FDR)";
            otherwise
                error
        end

        fn_out = vmp + "_" + voi + sprintf("_t%g%s", vmp_threshold, vmp_threshold_suffix);
        fp_out_csv = fol_out + fn_out + ".csv";
        fp_out_voi = fol_out + fn_out + sprintf("_PercentVoxelsAboveThreshold%g", min_pct_voxels) + ".voi";

        VMP_VOI_SUMMARY(    fp_in_vmp.char, ...
                            map_index, ...
                            vmp_threshold, ...
                            fp_in_voi.char, ...
                            fp_out_csv.char, ...
                            min_pct_voxels, ...
                            fp_out_voi.char ...
                            );
        
    end
end