% function Log_to_SDM_3DMC(filepath, overwrite)
%
% Reads a .log file created by BrainVoyager during motion correction and
% creates an equivalent .sdm containing the 6 motion metrics plus framewise
% displacement as a 7th metric.
%
% Requires NeuroElf.
%
% Note: ReleaseIniFile warnings are not a problem and can be ignored.
%
% Inputs:
%   filepath_log    filepath to the log file to read
%
% Optional Arguments:
%   filepath_sdm                        filepath of the sdm file to write (default: filepath_log + ".sdm")
%   overwrite                           whether or not to overwrite existing sdm files (default: false)
%   framewise_displacement_radius_mm    constant used in the framewise displacement calculation, Rainer uses 50 (default: 50)
%

function Log_to_SDM_3DMC(filepath_log, args)
arguments
    filepath_log (1,1) string {mustBeFile}
    args.filepath_sdm (1,1) string = (filepath_log+ ".sdm")
    args.overwrite (1,1) logical = false
    args.framewise_displacement_radius_mm (1,1) {isnumeric} = 50
end

% requires NeuroElf
if isempty(which("xff"))
    error("This function requires NeuroElf")
end

% handle incorrect filesep
filepath_log = filepath_log.replace("/",filesep).replace("\",filesep);
args.filepath_sdm = args.filepath_sdm.replace("/",filesep).replace("\",filesep);

% overwrite?
if exist(args.filepath_sdm, "file") && ~args.overwrite
    warning("The output file already exists and overwrite is set to false!\nAttempted to overwrite: %s", args.filepath_sdm)
    return
end

% read log
fprintf("Parsing: %s\n", filepath_log);
text = readlines(filepath_log);

% select rows of interest (between first two empty rows)
ind_empty = find(text == "");
text = text(ind_empty(1)+1 : ind_empty(2)-1);

% parse into [volume x 6]
number_volumes = 1 + length(text);
motion = zeros(number_volumes, 6); % Initialize matrix to store motion metrics
for i = 1:(number_volumes-1)
    line = text(i);
    values = sscanf(line, '-> volume: %d n_its: %d dx: %f mm dy: %f mm dz: %f mm rx: %f degs ry: %f degs rz: %f degs');
    motion(i+1, :) = values(end-5:end)'; % Store metrics in the matrix
end

% calculate framewise displacement...
% Method from Rainer (he uses a framewise_displacement_radius_mm of 50)
    
    % 1st deriv
    d_tx = [0; diff(motion(:,1))];
    d_ty = [0; diff(motion(:,2))];
    d_tz = [0; diff(motion(:,3))];
    d_rx = [0; diff(motion(:,4))];
    d_ry = [0; diff(motion(:,5))];
    d_rz = [0; diff(motion(:,6))];

    % convert rotation angles (deg) to displacement (mm)
    d_rx = d_rx * (pi/180) * args.framewise_displacement_radius_mm;
    d_ry = d_ry * (pi/180) * args.framewise_displacement_radius_mm;
    d_rz = d_rz * (pi/180) * args.framewise_displacement_radius_mm;

    % calculate framewise displacement as sum of absolutes
    FD =    abs(d_tx) + ...
            abs(d_ty) + ...
            abs(d_tz) + ...
            abs(d_rx) + ...
            abs(d_ry) + ...
            abs(d_rz);

% store FD
motion(:,7) = FD;

% create SDM
sdm = xff('sdm');
sdm.PredictorNames = {  'Translation BV-X [mm]'
                        'Translation BV-Y [mm]'
                        'Translation BV-Z [mm]'
                        'Rotation BV-X [deg]'
                        'Rotation BV-Y [deg]'
                        'Rotation BV-Z [deg]'
                        'Framewise Displacement'}';
sdm.PredictorColors = [   255    50    50;
                            50   255    50;
                            50    50   255;
                           255   255     0;
                           255     0   255;
                             0   255   255;
                           100   100   100];
sdm.IncludesConstant = 0;
sdm.FirstConfoundPredictor = 1;
sdm.SDMMatrix = motion;

% save sdm
fprintf("Writing: %s\n", args.filepath_sdm);
sdm.SaveAs(args.filepath_sdm.char);