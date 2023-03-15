first_confound = 8;

allow_variable_PONI = true;

new_order = { 'VL_CR_Play'
'VR_CR_Play'
'VL_CR_React'
'VR_CR_React'
'VL_CR_Replay'
'VR_CR_Replay'
'JoystickXYMvtHRF'
'trans_x_THPGLMF3c_ZSCORE'
'trans_y_THPGLMF3c_ZSCORE'
'trans_z_THPGLMF3c_ZSCORE'
'rot_x_THPGLMF3c_ZSCORE'
'rot_y_THPGLMF3c_ZSCORE'
'rot_z_THPGLMF3c_ZSCORE'
'trans_x_derivative1'
'trans_y_derivative1'
'trans_z_derivative1'
'rot_x_derivative1'
'rot_y_derivative1'
'rot_z_derivative1'
'a_comp_cor_00'
'a_comp_cor_01'
'a_comp_cor_02'
'a_comp_cor_03'
'a_comp_cor_04'
'a_comp_cor_05'
't_comp_cor_00'
't_comp_cor_01'
't_comp_cor_02'
't_comp_cor_03'
't_comp_cor_04'
't_comp_cor_05'
'VL_CR_Play_derivative1'
'VR_CR_Play_derivative1'
'VL_CR_React_derivative1'
'VR_CR_React_derivative1'
'Constant'
};

%%

folder = 'D:\The University of Western Ontario\Culham Lab General Email - Projects\CurrentProjects\Leppala_AvatarActions_JL_2020\New_PRT_SDM\Output3+ControllerPONI+OnlyCR+HRF\';

list = dir([folder '*_NoPONI_AvgDur_AddTSVPONI_AddPOIDeriv1_AddJoyPONI_OnlyCR_OnlyJoyHRF.sdm'])';

%exclude replay
list = list( arrayfun(@(f) ~contains(f.name,'task-Replay'), list) );

for file = list
    fp_in = [file.folder filesep file.name];
    fp_out = strrep(fp_in, '.sdm', '_Reorder.sdm');
    SDM_Reorder(fp_in, fp_out, new_order, first_confound, allow_variable_PONI);
end

disp Done!

