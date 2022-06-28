%PlotMotionBIDS(folder_BIDS)
% Creates summary figures of motion for each subject/task/session.
% You must have performed motion correction in BV to use this tool because it reads the *_3DMC.sdm files.
% The only parameter to pass is the path to the BIDS folder.
% The figures are written to "...\derivatives\figures\PlotMotionBIDS"
% You can change the line colours and toggle dark mode on/off at the top of the script.
% Requires NeuroElf
function PlotMotionBIDS(folder_BIDS)

%% Requires NeuroElf

if ~exist('xff')
    error('Requires NeuroElf Toolbox')
end

%% Param

line_colours = [0.8 0.2 0.2; 0.2 0.2 0.8; 0.8 0.8 0.2];
dark_mode = false;

if dark_mode
    colour_bgd = 'k';
    colour_fgd = 'w';
else
    colour_bgd = 'w';
    colour_fgd = 'k';
end


%% Prep

%folder exists
if ~exist('folder_BIDS', 'var')
    error('Missing input. Must pass the BIDS folder.')
end

%folder ends with filesep
if folder_BIDS(end) ~= filesep
    folder_BIDS(end+1) = filesep;
end

%folder with derivatives
folder_deriv = [folder_BIDS 'derivatives' filesep];

%derivatives exists?
if ~exist(folder_deriv, 'dir')
    error('derivatives folder does not exist: %s', folder_deriv)
end

%folder for figures
fol_fig = [folder_deriv 'figures' filesep 'PlotMotionBIDS' filesep];
if ~exist(fol_fig, 'dir')
    mkdir(fol_fig);
end

%% Find Files

%find motion SDMs
search_term = 'sub-*_ses-*_task-*_run-*_3DMC.sdm';
files = dir(fullfile(folder_BIDS, '**', search_term));

%no files
if isempty(files)
    error('No files found for search "%s" in "%s"', search_term, folder_BIDS);
end

%parse info
file_info = cell2mat(regexp({files.name}, '(?<par>sub-[a-zA-Z0-9]+)_(?<ses>ses-\d+)_(?<task>task-[a-zA-Z0-9]+)_(?<run>run-\d+)_*', 'names'));

%organize info
par_IDs = unique({file_info.par});
task_IDs = unique({file_info.task});
for fid = 1:length(files)
    file_info(fid).par_num = find(strcmp(par_IDs, file_info(fid).par));
    file_info(fid).ses_num = str2num(file_info(fid).ses(5:end));
    file_info(fid).run_num = str2num(file_info(fid).run(5:end));
    file_info(fid).task_num = find(strcmp(task_IDs, file_info(fid).task));
    
    file_info(fid).folder = [files(fid).folder filesep];
    file_info(fid).filename = files(fid).name;
    file_info(fid).filepath = [file_info(fid).folder file_info(fid).filename];
end

%max number of sessions
max_ses = max([file_info.ses_num]);


%% Process

fig = figure('Position', get(0,'ScreenSize'));

%for each particiapnt...
for p = 1:length(par_IDs)
    %for each task...
    for t = 1:length(task_IDs)
        %for each ses...
        for s = 1:max_ses
            %select files
            select = ([file_info.par_num] == p) & ([file_info.task_num] == t) & ([file_info.ses_num] == s);
            files = file_info(select);
            number_files = length(files);
            
            %sort runs
            [~,order] = sort([files.run_num]);
            files = files(order);
            
            %load and parse SDMs
            for f = 1:number_files
                %read
                sdm = xff(files(f).filepath);
                
                %number of volumes
                files(f).volumes = sdm.NrOfDataPoints;
                
                %get measures
                ind = find(strcmp(sdm.PredictorNames, 'Translation BV-X [mm]'));
                files(f).trans_x_mm = sdm.SDMMatrix(:,ind);
                ind = find(strcmp(sdm.PredictorNames, 'Translation BV-Y [mm]'));
                files(f).trans_y_mm = sdm.SDMMatrix(:,ind);
                ind = find(strcmp(sdm.PredictorNames, 'Translation BV-Z [mm]'));
                files(f).trans_z_mm = sdm.SDMMatrix(:,ind);
                ind = find(strcmp(sdm.PredictorNames, 'Rotation BV-X [deg]'));
                files(f).rot_x_deg = sdm.SDMMatrix(:,ind);
                ind = find(strcmp(sdm.PredictorNames, 'Rotation BV-Y [deg]'));
                files(f).rot_y_deg = sdm.SDMMatrix(:,ind);
                ind = find(strcmp(sdm.PredictorNames, 'Rotation BV-Z [deg]'));
                files(f).rot_z_deg = sdm.SDMMatrix(:,ind);
                
                %close
                sdm.Clear;
                
                %calcualte translation distance from origin
                files(f).distance_mm = sqrt(files(f).trans_x_mm.^2 + files(f).trans_y_mm.^2 + files(f).trans_z_mm.^2);
                files(f).distance_mm_delta = [0; diff(files(f).distance_mm)];
                
                %calculate rotation distance from origin
                files(f).angle_deg = sqrt(files(f).rot_x_deg.^2 + files(f).rot_y_deg.^2 + files(f).rot_z_deg.^2);
                files(f).angle_deg_delta = [0; diff(files(f).angle_deg)];
                
            end
            
            %figure
            clf
            for mode = 1:4
                switch mode
                    case 1
                        lbl_title = 'Raw Translation';
                        lbl_y = 'mm';
                        fields = {'trans_x_mm' 'trans_y_mm' 'trans_z_mm'};
                        lbl_lines = {'X' 'Y' 'Z'};
                    case 2
                        lbl_title = 'Raw Rotation';
                        lbl_y = 'deg';
                        fields = {'rot_x_deg' 'rot_y_deg' 'rot_z_deg'};
                        lbl_lines = {'X' 'Y' 'Z'};
                    case 3
                        lbl_title = 'Location Relative to Origin';
                        lbl_y = 'mm|deg';
                        fields = {'distance_mm' 'angle_deg'};
                        lbl_lines = {'Position' 'Angle'};
                    case 4
                        lbl_title = 'Movement Per Volume';
                        lbl_y = 'mm|deg';
                        fields = {'distance_mm_delta' 'angle_deg_delta'};
                        lbl_lines = {'Position' 'Angle'};
                    otherwise
                        error
                end
                
                
                subplot(4,1,mode)
                leg = [];
                hold on
                for f = 1:number_files
                    vol_prior = sum([files(1:(f-1)).volumes]);

                    xs = vol_prior + (1:files(f).volumes);
                    
                    values = cell2mat(cellfun(@(x) getfield(files(f), x), fields, 'UniformOutput', false));

                    for i = 1:size(values,2)
                        leg(i) = plot(xs, values(:,i), 'color', line_colours(i,:));
                    end
                end
                yl = ylim;
                yl_new = yl + [0 range(yl)*0.1];
                for f = 1:number_files
                    vol = sum([files(1:(f-1)).volumes]);
                    plot([vol vol], yl_new, 'Color', colour_fgd)
                    text(vol+3, yl_new(2) - range(yl_new)*0.05,files(f).run, 'Color', colour_fgd)
                end
                ylim(yl_new)
                hold off
                xlim([1 sum([files.volumes])])
                title(lbl_title,'Color',colour_fgd)
                ylabel(lbl_y,'Color',colour_fgd)
                set(gca,'xtick',[],'Color',colour_bgd,'XColor',colour_fgd,'YColor',colour_fgd)
                legend(leg,lbl_lines,'Location','SouthOutside','TextColor',colour_fgd)
            
            end
            
            set(gcf,'Color',colour_bgd,'InvertHardcopy',false)
            lbl = sprintf('%s_%s_%s', files(1).par, files(1).task, files(1).ses);
            sgtitle(strrep(lbl,'_',', '),'Color',colour_fgd)
            saveas(fig, [fol_fig lbl '.png'])
            
        end
    end
end

%% Done
close(fig)
fprintf('Done. Figures created in: %s\n', fol_fig);