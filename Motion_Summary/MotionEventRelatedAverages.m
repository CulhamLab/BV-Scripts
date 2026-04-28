% MotionEventRelatedAverages(search_folder, args)
%
% Assumed naming convention:
%   SDM: sub-##_ses-##_task-*_run-##_*3DMC.sdm
%   PRT: sub-##_ses-##_task-*_run-##.prt
%
function MotionEventRelatedAverages(search_folder, args)

arguments
    search_folder (1,1) string {mustBeFolder}
    args.name_translation_x (1,1) string {mustBeNonzeroLengthText} = "Translation BV-X [mm]"
    args.name_translation_y (1,1) string {mustBeNonzeroLengthText} = "Translation BV-Y [mm]"
    args.name_translation_z (1,1) string {mustBeNonzeroLengthText} = "Translation BV-Z [mm]"
    args.name_rotation_x (1,1) string {mustBeNonzeroLengthText} = "Rotation BV-X [deg]"
    args.name_rotation_y (1,1) string {mustBeNonzeroLengthText} = "Rotation BV-Y [deg]"
    args.name_rotation_z (1,1) string {mustBeNonzeroLengthText} = "Rotation BV-Z [deg]"
    args.output_folder (1,1) string {mustBeNonzeroLengthText} = [pwd filesep mfilename filesep]
    args.framewise_displacement_radius_mm (1,1) double {mustBePositive} = 50
    args.TR_msec (1,1) double {mustBePositive} = 1000 % used if PRT is in msec
    args.volumes_before_onset (1,1) double {mustBePositive} = 2
    args.volume_after_onset (1,1) double {mustBePositive} = 20
    args.figure_size_position (1,4) double = get(0,"ScreenSize") %defaults to full screen, can instead do [xStart yStart width height]
    args.ylimits (1,2) double = [nan nan] %leave as nans to fit the data, else [min max]
end

%% Volumes selected

volumes_selected = -args.volumes_before_onset : args.volume_after_onset;
volumes_selected_count = length(volumes_selected);


%% Output Folder

if ~args.output_folder.endsWith(filesep)
    args.output_folder = args.output_folder + filesep;
end
if ~exist(args.output_folder, "dir")
    mkdir(args.output_folder)
end


%% Find SDM Files

list = dir(fullfile(search_folder, "**", "*_run-*_*3DMC.sdm"));
number_files = length(list);

if ~number_files
    error("No SDM files were located!")
end


%% Parse Filenames

tbl = struct2table(arrayfun(@(x) regexp(x.name, "(?<ID>.+)_run-(?<run>\d+)_.*3DMC.sdm", "names"), list));
tbl.ID = string(tbl.ID);
tbl.run = string(tbl.run);
tbl.filepath_sdm = arrayfun(@(x) string([x.folder filesep x.name]), list);

unique_IDs = unique(tbl.ID);
unique_IDs_count = length(unique_IDs);
fprintf("Found %d unique IDs:\n\t%s\n", unique_IDs_count, strjoin(unique_IDs, '\n\t'));


%% Find PRTs

% create PRT table
list = dir(fullfile(search_folder, "**", "*_run-*.prt"));
tbl_prt = struct2table(arrayfun(@(x) regexp(x.name, "(?<ID>.+)_run-(?<run>\d+).prt", "names"), list));
tbl_prt.ID = string(tbl_prt.ID);
tbl_prt.run = string(tbl_prt.run);
tbl_prt.filepath_prt = arrayfun(@(x) string([x.folder filesep x.name]), list);

% match rows and copy PRT filepaths over
tbl.filepath_prt(:) = "";
for row = 1:height(tbl)
    ind = find((tbl.ID(row) == tbl_prt.ID) & (tbl.run(row) == tbl_prt.run));
    if length(ind) ~= 1
        error("Did not find exactly one PRT match for %s run %s", tbl.ID(row), tbl.run(row))
    end

    tbl.filepath_prt(row) = tbl_prt.filepath_prt(ind);
end


%% Open Figure

fig = figure(Position=args.figure_size_position);
if isprop(fig, "Theme")
    fig.Theme = "Light";
end


%% Process by ID

for ID_ind = 1:unique_IDs_count
    fprintf("Processing ID %d of %d: %s\n", ID_ind, unique_IDs_count, unique_IDs(ID_ind));

    % select files
    file_info = tbl(tbl.ID==unique_IDs(ID_ind),:);
    file_info_count = height(file_info);
    fprintf("\tProcessing %d run files...\n", file_info_count);
    disp(file_info)

    % initialize
    ERA_cond_name = string([]);
    ERA_cond_trials = cell(0);
    
    % process each file
    for i = 1:file_info_count
        %% Calculate FD from SDM

        % load sdm
        sdm = xff(file_info.filepath_sdm(i).char);

        % volume count
        volumes_count = sdm.NrOfDataPoints;

        % translation
        ind = arrayfun(@(x) find(strcmpi(sdm.PredictorNames, x)), [args.name_translation_x args.name_translation_y args.name_translation_z]);
        trans_xyz = sdm.SDMMatrix(:, ind);

        % rotation
        ind = arrayfun(@(x) find(strcmpi(sdm.PredictorNames, x)), [args.name_rotation_x args.name_rotation_y args.name_rotation_z]);
        rot_xyz = sdm.SDMMatrix(:, ind);

        % calcualte 1st deriv
        d_trans_xyz = [0 0 0 ; diff(trans_xyz)];
        d_rot_xyz =   [0 0 0 ; diff(rot_xyz)];
    
        % convert rotation angles (deg) to displacement (mm)
        d_rot_xyz = d_rot_xyz * (pi/180) * args.framewise_displacement_radius_mm;
    
        % sum of absolutes
        FD = sum(abs([d_trans_xyz d_rot_xyz]), 2);

        % cleanup
        sdm.ClearObject;


        %% Extra Event FD

        % load prt
        prt = xff(file_info.filepath_prt(i).char);
        
        % each condition...
        for c = 1:prt.NrOfConditions
            % get condition
            name = string(prt.Cond(c).ConditionName);
            onsets = prt.Cond(c).OnOffsets(:,1);

            % convert onsets from msec to vol?
            if strcmp(lower(prt.ResolutionOfTime), 'msec')
                onsets = (onsets / args.TR_msec) + 1;
            end

            % find index to store
            ind_store_cond = find(ERA_cond_name == name);
            if isempty(ind_store_cond)
                ind_store_cond = length(ERA_cond_name) + 1;
                ERA_cond_name(ind_store_cond) = name;
                ERA_cond_trials{ind_store_cond} = [];
            end

            % each trial...
            for t = 1:length(onsets)
                % initialize trial FD as NaN
                values = nan(1, volumes_selected_count);

                % volumes
                inds = 1:volumes_selected_count;
                vols = onsets(t) + volumes_selected;

                % remove volumes before 1st vol and after last vol
                to_remove = (vols < 1) | (vols > volumes_count);
                inds(to_remove) = [];
                vols(to_remove) = [];

                % get values
                values(inds) = FD(vols);

                % store trial values
                ind_store_trial = size(ERA_cond_trials{ind_store_cond}, 1) + 1;
                ERA_cond_trials{ind_store_cond}(ind_store_trial,:) = values;
            end
        end
        
        % cleanup
        prt.ClearObject;
    end

    % average across trials
    ERA_cond_means = cell2mat(cellfun(@(x) nanmean(x, 1), ERA_cond_trials, UniformOutput=false)');

    % figure
    clf
    plot(volumes_selected, ERA_cond_means, LineWidth=3)
    xlim(volumes_selected([1 end]))
    yl = ylim;
    for i = 1:2
        if ~isnan(args.ylimits(i))
            yl(i) = args.ylimits(i);
        end
    end
    hold on
        plot([0 0], yl, ":k", LineWidth=3)
    hold off
    ylim(yl)
    xlabel("Volume Relative to Onset", FontWeight="bold")
    ylabel("Framewise Displacement", FontWeight="bold")
    title(strrep(unique_IDs(ID_ind), "_", "\_"))
    legend(strrep(ERA_cond_name, "_", "\_"), Location="eastoutside")
    
    % save figure
    saveas(fig, args.output_folder + mfilename + "_" + unique_IDs(ID_ind) + ".png")
end


%% Close Figure
close(fig)


%% Done
disp Done!