% Reads xyz translation and rotation from 3DMC.sdm files created during
% motion correction. Plots summary figures across runs.
%
% Assumes that SDMs are named [ID]_run-[#]_*3DMC.sdm
%   e.g., "sub-01_ses-01_task-Pacman_run-01_bold_SCCTBL_3DMC.sdm"
%           Grouped by ID: "sub-01_ses-01_task-Pacman"
%           Ordered as 1st run (leftmost)
function MotionPlots(search_folder, args)

arguments
    search_folder (1,1) string {mustBeFolder}
    args.name_translation_x (1,1) string {mustBeNonzeroLengthText} = "Translation BV-X [mm]"
    args.name_translation_y (1,1) string {mustBeNonzeroLengthText} = "Translation BV-Y [mm]"
    args.name_translation_z (1,1) string {mustBeNonzeroLengthText} = "Translation BV-Z [mm]"
    args.name_rotation_x (1,1) string {mustBeNonzeroLengthText} = "Rotation BV-X [deg]"
    args.name_rotation_y (1,1) string {mustBeNonzeroLengthText} = "Rotation BV-Y [deg]"
    args.name_rotation_z (1,1) string {mustBeNonzeroLengthText} = "Rotation BV-Z [deg]"
    args.output_folder (1,1) string {mustBeNonzeroLengthText} = [pwd filesep] + "MotionPlots" + filesep
    args.figure_size_position (1,4) double = get(0,"ScreenSize") %defaults to full screen, can instead do [xStart yStart width height]
    args.line_colour (4,4) double = [1 0 0 0.8; 0 1 0 0.8; 0 0 1 0.8; 1 0 0 0.8] %[red green blue opacity] for x, y, z, FD
    args.ylimits_position (1,2) double = [nan nan] %leave as nans to fit the data, else [min max]
    args.ylimits_rotation (1,2) double = [nan nan] %leave as nans to fit the data, else [min max]
    args.ylimits_pervol (1,2) double = [nan nan] %leave as nans to fit the data, else [min max]
    args.framewise_displacement_radius_mm (1,1) {isnumeric} = 50
    args.close_figure (1,1) logical = true
    args.resume_from_prior_runs_endpoint (1,1) logical = false %if true, then the starting point of each run will be adjusted to match the endpoint of the prior run
end

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
tbl.filepath = arrayfun(@(x) string([x.folder filesep x.name]), list);

unique_IDs = unique(tbl.ID);
unique_IDs_count = length(unique_IDs);
fprintf("Found %d unique IDs:\n\t%s\n", unique_IDs_count, strjoin(unique_IDs, '\n\t'));

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
    fprintf("\tFound %d run files...\n", file_info_count);
    disp(file_info)
    
    % gather data
    trans_xyz = cell(1,file_info_count);
    rot_xyz = cell(1,file_info_count);
    for i = 1:file_info_count
        % load sdm
        sdm = xff(file_info.filepath(i).char);

        % translation
        ind = arrayfun(@(x) find(strcmpi(sdm.PredictorNames, x)), [args.name_translation_x args.name_translation_y args.name_translation_z]);
        trans_xyz{i} = sdm.SDMMatrix(:, ind);

        % rotation
        ind = arrayfun(@(x) find(strcmpi(sdm.PredictorNames, x)), [args.name_rotation_x args.name_rotation_y args.name_rotation_z]);
        rot_xyz{i} = sdm.SDMMatrix(:, ind);
        
        % cleanup sdm (otherwise can accumulate in memory)
        sdm.ClearObject;
    end

    % apply resume_from_prior_runs_endpoint
    if args.resume_from_prior_runs_endpoint
        for i = 2:file_info_count
            % translation
            trans_xyz{i} = trans_xyz{i} + (trans_xyz{i-1}(end,:) - trans_xyz{i}(1,:));

            % rotation
            rot_xyz{i} = rot_xyz{i} + (rot_xyz{i-1}(end,:) - rot_xyz{i}(1,:));
        end
    end

    % Figure prep
    if ~ishandle(fig)
        fig = figure(Position=args.figure_size_position); %reopen if closed
    else
        fig.Position = args.figure_size_position; %restore position if moved
    end
    clf(fig) %clear

    %% Figure 1 - Translation XYZ
    subplot(3,1,1);
    hold on
    v=0;
    if any(isnan(args.ylimits_position))
        yl = [nanmin(cellfun(@(x) nanmin(x(:)), trans_xyz)) nanmax(cellfun(@(x) nanmax(x(:)), trans_xyz))];
    else
        yl = args.ylimits_position;
    end
    for i = 1:file_info_count
        xs = v + (1:size(trans_xyz{i},1));

        plot([v v], yl, "-k")
        text(v, yl(2), file_info.run(i))

        p = plot(xs, trans_xyz{i});
        arrayfun(@(j) set(p(j),Color=args.line_colour(j,:)), 1:3)

        v = xs(end);
    end
    hold off
    xlim([1 v])
    ylim(yl)
    legend(p, ["Translation X" "Translation Y" "Translation Z"], Location="eastoutside")
    ylabel("mm")
    xlabel("Volumes")
    title("Raw Position")

    %% Figure 2: Rotation
    subplot(3,1,2);
    hold on
    v=0;
    if any(isnan(args.ylimits_rotation))
        yl = [nanmin(cellfun(@(x) nanmin(x(:)), rot_xyz)) nanmax(cellfun(@(x) nanmax(x(:)), rot_xyz))];
    else
        yl = args.ylimits_rotation;
    end
    for i = 1:file_info_count
        xs = v + (1:size(rot_xyz{i},1));

        plot([v v], yl, "-k")
        text(v, yl(2), file_info.run(i))

        p = plot(xs, rot_xyz{i});
        arrayfun(@(j) set(p(j),Color=args.line_colour(j,:)), 1:3)

        v = xs(end);
    end
    hold off
    xlim([1 v])
    ylim(yl)
    legend(p, ["   Rotation X" "   Rotation Y" "   Rotation Z"], Location="eastoutside")
    ylabel("deg")
    xlabel("Volumes")
    title("Raw Rotation")

    %% Figure 3: Framewise displacement
    subplot(3,1,3)

    % calcualte 1st deriv
    d_trans_xyz = cellfun(@(x) [0 0 0 ; diff(x)], trans_xyz, UniformOutput=false);
    d_rot_xyz =   cellfun(@(x) [0 0 0 ; diff(x)], rot_xyz,   UniformOutput=false);

    % convert rotation angles (deg) to displacement (mm)
    d_rot_xyz = cellfun(@(x) x * (pi/180) * args.framewise_displacement_radius_mm, d_rot_xyz, UniformOutput=false);

    % sum of absolutes
    FD = cellfun(@(a,b) sum(abs([a b]), 2), d_trans_xyz, d_rot_xyz, UniformOutput=false);

    hold on
    v=0;

    if any(isnan(args.ylimits_pervol))
        yl = [0 nanmax(cellfun(@(x) nanmax(x(:)), FD))];
    else
        yl = args.ylimits_pervol;
    end

    for i = 1:file_info_count
        xs = v + (1:size(FD{i},1));

        plot([v v], yl, "-k")
        text(v, yl(2), file_info.run(i))

        p = plot(xs, FD{i}, Color=args.line_colour(4,:));

        v = xs(end);
    end
    hold off
    xlim([1 v])
    ylim(yl)
    legend(p, "mm/vol", Location="eastoutside")
    ylabel("mm")
    xlabel("Volumes")
    title("Framewise Displacement")

    %% Title and Save
    sgtitle(strrep(unique_IDs(ID_ind),"_","\_"))
    fp = args.output_folder + unique_IDs(ID_ind) + ".png";
    fprintf("\tWriting: %s\n", fp);
    saveas(fig, fp)

end

%% Close figure?
if args.close_figure
    close(fig)
end

%% Done
disp Done!
