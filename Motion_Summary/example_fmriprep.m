%% Generate 3DMC SDMs from fMRIprep outputs
folder_fmriprep_project = "S:\Transfer\example_fmriprep_for_kevin\example_fmriprep_for_kevin\project_root";
folder_generated_sdm = ".\Generate_MotionSDM_from_fmriprep\";
Generate_3DMC_SDM_from_fmriprep(folder_fmriprep_project, folder_generated_sdm)

%% Run MotionSummary
filepath_summary = "example_fmriprep_MotionSummary.csv";
MotionSummary(folder_generated_sdm, output_filepath=filepath_summary);

%% Run MotionPlots
folder_plots = ".\example_fmriprep_MotionSummary";
MotionPlots(folder_generated_sdm, output_folder=folder_plots);
