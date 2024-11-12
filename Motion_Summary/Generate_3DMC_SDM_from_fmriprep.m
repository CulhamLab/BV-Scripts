% Generate_3DMC_SDM_from_fmriprep(folder_fmriprep_project, folder_output)
%
% Generates _3DMC.sdm from fmriprep's _desc-confounds_timeseries.tsv
% Copies only translation xyz and rotation xyz
%
% For use with MotionSummary and MotionPlots
%
% Requires NeuroElf (see readme in top level folder)
%
function Generate_3DMC_SDM_from_fmriprep(folder_fmriprep_project, folder_output)

arguments
    folder_fmriprep_project (1,1) string {mustBeFolder}
    folder_output (1,1) string
end

%% Make output folder
if ~folder_output.endsWith(filesep)
    folder_output = folder_output + filesep;
end
if ~exist(folder_output, "dir")
    mkdir(folder_output)
end

%% Locate fmriprep tsv files
list = dir(fullfile(folder_fmriprep_project, '**', '*_desc-confounds_timeseries.tsv'));
number_files = length(list);
fprintf("Found %d fmriprep tsv files...\n", number_files);

%% Initialize SDM (requires NeuroElf)
sdm = xff('sdm');
sdm.PredictorNames = {  'Translation BV-X [mm]'
                        'Translation BV-Y [mm]'
                        'Translation BV-Z [mm]'
                        'Rotation BV-X [deg]'
                        'Rotation BV-Y [deg]'
                        'Rotation BV-Z [deg]'}';
sdm.PredictorColors = [   255    50    50;
                            50   255    50;
                            50    50   255;
                           255   255     0;
                           255     0   255;
                             0   255   255];
sdm.IncludesConstant = 0;
sdm.FirstConfoundPredictor = 1;

%% Process Each Files
for fid = 1:number_files
    fprintf("Processing tsv %d of %d: %s\n", fid, number_files, list(fid).name);
    
    % load tsv
    fprintf("\tLoading tsv...\n");
    tbl = readtable([list(fid).folder filesep list(fid).name], FileType="text", VariableNamingRule="preserve");
    
    % populate
    fprintf("\tPopulating sdm...\n");
    sdm.SDMMatrix = [];
    sdm.SDMMatrix(:,1) = tbl.trans_x;
    sdm.SDMMatrix(:,2) = tbl.trans_y;
    sdm.SDMMatrix(:,3) = tbl.trans_z;
    sdm.SDMMatrix(:,4) = tbl.rot_x;
    sdm.SDMMatrix(:,5) = tbl.rot_y;
    sdm.SDMMatrix(:,6) = tbl.rot_z;

    % save
    [~,name,~] = fileparts(list(fid).name);
    filename = [name '_3DMC.sdm'];
    fprintf("\tSaving: %s\n", filename);
    sdm.SaveAs([folder_output.char filename]); %only supports char array
end

%% Done
disp Done!
