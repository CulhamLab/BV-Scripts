function MotionSummary(search_folder, args)

arguments
    search_folder (1,1) string {mustBeFolder}
    args.search_sdm_term (1,1) string {mustBeNonzeroLengthText} = "*_3DMC.sdm"
    args.threshold_mean_3D_mm_per_volume (1,1) {isnumeric} = 0.5;
    args.threshold_total_range_3D_mm (1,1) {isnumeric} = 3;
    args.name_translation_x (1,1) string {mustBeNonzeroLengthText} = "Translation BV-X [mm]"
    args.name_translation_y (1,1) string {mustBeNonzeroLengthText} = "Translation BV-Y [mm]"
    args.name_translation_z (1,1) string {mustBeNonzeroLengthText} = "Translation BV-Z [mm]"
    args.output_filepath (1,1) string {mustBeNonzeroLengthText} = [pwd filesep mfilename '.xlsx'];
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

name_thresh_mtn_per_vol = sprintf("Motion exceeds %g/vol", args.threshold_mean_3D_mm_per_volume);
name_thresh_mtn_range = sprintf("Range exceeds %g", args.threshold_total_range_3D_mm);
variables = [   "Folder"                    "string"
                "SDM Filename"              "string"
                "sub"                       "string"
                "ses"                       "string"
                "task"                      "string"
                "run"                       "string"
                "Mean 3D motion per volume" "double"
                "Total range of 3D motion"  "double"
                name_thresh_mtn_per_vol     "logical"
                name_thresh_mtn_range       "logical"
                "Should Exclude"            "logical"
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
        if length(ind) == 1
            tbl.(v)(fid) = parts{ind};
        end
    end

    %read
    fp = [list(fid).folder filesep list(fid).name];
    fprintf('\tReading: %s\n', fp);
    sdm = xff(fp);

    %find motion parameters
    for v = 'xyz'
        %name to look for
        name = eval(['args.name_translation_' v]);

        %find
        ind = find(strcmp(sdm.PredictorNames, name));

        %handle issues
        if length(ind) > 1
            error('Found multiple matches for: %s', name)
        elseif isempty(ind)
            error('Found no matches for: %s', name)
        end
        
        %get values
        eval([v ' = sdm.SDMMatrix(:,ind);'])
    end

    %cleanup SDM object
    sdm.ClearObject;

    %combine
    xyz = [x y z];

    %3D motion/volume
    xyz_delta = [0 0 0; diff(xyz)];
    xyz_euc = sqrt(sum(xyz_delta .^ 2, 2));
    tbl.("Mean 3D motion per volume")(fid) = mean(xyz_euc);
    tbl.(name_thresh_mtn_per_vol)(fid) = tbl.("Mean 3D motion per volume")(fid) > args.threshold_mean_3D_mm_per_volume;

    %3D range of motion
    tbl.("Total range of 3D motion")(fid) = max(pdist(xyz));
    tbl.(name_thresh_mtn_range)(fid) = tbl.("Total range of 3D motion")(fid) > args.threshold_total_range_3D_mm;

    %should exclude?
    tbl.("Should Exclude")(fid) = tbl.(name_thresh_mtn_per_vol)(fid) || tbl.(name_thresh_mtn_range)(fid);
end

%% Display
disp(tbl)

%% Write
disp(sprintf('Writing %s\n', args.output_filepath))
writetable(tbl, args.output_filepath);

%% Done
disp Done!
