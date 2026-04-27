%% Specify data location
folder_BIDS_deriv = ".\Psych9223_BIDS_MotionFilesOnly\derivatives\sourcedata_bv\";

%% Run MotionSummary
filepath_summary = "example_MotionSummary.csv";
MotionSummary(folder_BIDS_deriv, output_filepath=filepath_summary);

%% Run MotionPlots
folder_plots = ".\example_MotionSummary";
MotionPlots(folder_BIDS_deriv, output_folder=folder_plots);