% Reads 3DMC metrics from csv, calculates framewise displacement, and saves a new csv with FD added
%
% Works with output from SDM_to_CSV

%% Parameterse
fol_in = ".\In\";
fol_out = ".\Out\";

radius_mm = 50;

%% Prep
if ~exist(fol_out, "dir")
    mkdir(fol_out);
end

%% Find
list = dir(fol_in + "*.csv");
number_files = length(list);

%% Process
for fid = 1:number_files
    fprintf("Processing %d of %d: %s\n", fid, number_files, list(fid).name);

    % read table
    tbl = readtable([list(fid).folder filesep list(fid).name], VariableNamingRule="preserve");

    % 1st deriv of each translation (mm) and rotation (deg)
    d_tx = [0; diff(tbl.("Translation BV-X [mm]"))];
    d_ty = [0; diff(tbl.("Translation BV-Y [mm]"))];
    d_tz = [0; diff(tbl.("Translation BV-Z [mm]"))];
    d_rx = [0; diff(tbl.("Rotation BV-X [deg]"))];
    d_ry = [0; diff(tbl.("Rotation BV-Y [deg]"))];
    d_rz = [0; diff(tbl.("Rotation BV-Z [deg]"))];

    % convert rotation angles (deg) to displacement (mm)
    d_rx = d_rx * (pi/180) * radius_mm;
    d_ry = d_ry * (pi/180) * radius_mm;
    d_rz = d_rz * (pi/180) * radius_mm;

    % calculate FD as sum of absolutes
    tbl.FramewiseDisplacement = abs(d_tx) + ...
                                abs(d_ty) + ...
                                abs(d_tz) + ...
                                abs(d_rx) + ...
                                abs(d_ry) + ...
                                abs(d_rz);
    % save
    fp = fol_out + list(fid).name;
    if exist(fp, "file")
        delete(fp)
    end
    writetable(tbl, fp)
end

%% Done
disp Done!


