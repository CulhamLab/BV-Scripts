function MotionSummary(search_folder, args)

arguments
    search_folder (1,1) string {mustBeFolder}
    args.search_sdm_term (1,1) string {mustBeNonzeroLengthText} = "*_3DMC.sdm"
    args.threshold_mean_FD_per_volume (1,1) {isnumeric} = 0.5;
    args.threshold_total_range_3D_translation (1,1) {isnumeric} = 3
    args.name_translation_x (1,1) string {mustBeNonzeroLengthText} = "Translation BV-X [mm]"
    args.name_translation_y (1,1) string {mustBeNonzeroLengthText} = "Translation BV-Y [mm]"
    args.name_translation_z (1,1) string {mustBeNonzeroLengthText} = "Translation BV-Z [mm]"
    args.name_rotation_x (1,1) string {mustBeNonzeroLengthText} = "Rotation BV-X [deg]"
    args.name_rotation_y (1,1) string {mustBeNonzeroLengthText} = "Rotation BV-Y [deg]"
    args.name_rotation_z (1,1) string {mustBeNonzeroLengthText} = "Rotation BV-Z [deg]"
    args.output_filepath (1,1) string {mustBeNonzeroLengthText} = [pwd filesep mfilename '.csv']
    args.framewise_displacement_radius_mm (1,1) {isnumeric} = 50
end

%% Argument Checks

if ~args.search_sdm_term.lower.endsWith('.sdm')
    error('search_sdm_term must end with ".sdm"')
end

if ~args.output_filepath.lower.endsWith([".csv" ".xlsx" ".xls"])
    error('output_filepath must be csv, xls, or xlsx')
end

if exist(args.output_filepath, 'file')
    error('Output file already exists: %s', args.output_filepath)
end

%% Find SDM Files

list = dir(fullfile(search_folder, '**', args.search_sdm_term));
number_files = length(list);

if ~number_files
    error('No SDM files were located!')
end

%% Initialize Table

name_thresh_FD_per_vol = sprintf("FD exceeds %g mm/vol", args.threshold_mean_FD_per_volume);
name_thresh_translation_range = sprintf("Translation range exceeds %gmm", args.threshold_total_range_3D_translation);
variables = [   "Folder"                        "string"
                "SDM Filename"                  "string"
                "sub"                           "string"
                "ses"                           "string"
                "task"                          "string"
                "run"                           "string"
                "Mean FD per volume"            "double"
                "Total range of 3D translation" "double"
                name_thresh_FD_per_vol          "logical"
                name_thresh_translation_range   "logical"
                "Consider Excluding"                "logical"
                ];
tbl = table('Size',[number_files size(variables,1)], 'VariableNames', variables(:,1), 'VariableTypes', variables(:,2));

%% Process Files

for fid = 1:number_files
    fprintf('Processing file %d of %d: %s\n', fid, number_files, list(fid).name);
    tbl.("SDM Filename")(fid) = list(fid).name;
    tbl.("Folder")(fid) = list(fid).folder;

    %info from filename
    [~,name,~] = fileparts(list(fid).name);
    parts = strsplit(name,'_');
    for v = ["sub" "ses" "task" "run"]
        ind = find(cellfun(@(x) startsWith(x, v.append('-')), parts));
        if isscalar(ind)
            tbl.(v)(fid) = parts{ind};
        end
    end

    %read
    fp = [list(fid).folder filesep list(fid).name];
    fprintf('\tReading: %s\n', fp);
    sdm = xff(fp);

    %find motion parameters
    for v = ["x" "y" "z"]
        for type = ["translation" "rotation"]
            %name to look for
            name = args.("name_" + type + "_" + v);
    
            %find
            ind = find(strcmp(sdm.PredictorNames, name));
    
            %handle issues
            if length(ind) > 1
                error('Found multiple matches for: %s', name)
            elseif isempty(ind)
                error('Found no matches for: %s', name)
            end
            
            %get values
            eval(type.extract(1) + v + " = sdm.SDMMatrix(:,ind);")
        end
    end

    %cleanup SDM object
    sdm.ClearObject;

    %calculate framewise displacement...

        % 1st deriv
        d_tx = [0; diff(tx)];
        d_ty = [0; diff(ty)];
        d_tz = [0; diff(tz)];
        d_rx = [0; diff(rx)];
        d_ry = [0; diff(ry)];
        d_rz = [0; diff(rz)];
    
        % convert rotation angles (deg) to displacement (mm)
        d_rx = d_rx * (pi/180) * args.framewise_displacement_radius_mm;
        d_ry = d_ry * (pi/180) * args.framewise_displacement_radius_mm;
        d_rz = d_rz * (pi/180) * args.framewise_displacement_radius_mm;
    
        % calculate FD as sum of absolutes
        FD =    abs(d_tx) + ...
                abs(d_ty) + ...
                abs(d_tz) + ...
                abs(d_rx) + ...
                abs(d_ry) + ...
                abs(d_rz);

    %store FD framewise displacement summary
    tbl.("Mean FD per volume")(fid) = mean(FD);
    tbl.(name_thresh_FD_per_vol)(fid) = tbl.("Mean FD per volume")(fid) > args.threshold_mean_FD_per_volume;
    
    %range of translational motion
    range_translation = max(pdist([tx ty tz]));
    tbl.("Total range of 3D translation")(fid) = range_translation;
    tbl.(name_thresh_translation_range)(fid) = tbl.("Total range of 3D translation")(fid) > args.threshold_total_range_3D_translation;

    %should exclude?
    tbl.("Consider Excluding")(fid) = tbl.(name_thresh_FD_per_vol)(fid) || tbl.(name_thresh_translation_range)(fid);
end

%% Display
disp(tbl)

%% Write
fprintf('Writing %s\n', args.output_filepath);
writetable(tbl, args.output_filepath);

%% Done
disp Done!
