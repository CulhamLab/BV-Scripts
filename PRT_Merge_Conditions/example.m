% Example for fMRI_bp_graziano-game_2025
function example

% Folders
folder_input = "C:\Users\kmstu\Documents\GitHub\fMRI_bp_graziano-game_2025\Make_PRT\PRTs\";
folder_output = "C:\Users\kmstu\Documents\GitHub\fMRI_bp_graziano-game_2025\Make_PRT\PRTs_MergedPositions\";

% Folders must end in a filesep
if ~folder_input.endsWith(filesep)
    folder_input = folder_input + filesep;
end
if ~folder_output.endsWith(filesep)
    folder_output = folder_output + filesep;
end

% Find PRTs
prts = dir(folder_input + "*.prt");
prts_count = length(prts);
fprintf("Found %d PRTs in %s\n", prts_count, folder_input);

% Load first PRT to get the colours
fprintf("Loading first PRT to get colours...\n")
prt = xff([prts(1).folder filesep prts(1).name]);
cond_names = arrayfun(@(x) string(x.ConditionName), prt.Cond');
cond_colours = cell2mat(arrayfun(@(x) x.Color, prt.Cond', UniformOutput=false));
prt.ClearObject;

% Populate info table
% Columns:
%   NewName     Name of new condition (1x1 string)
%   NewColour   Colour of new condition (1x3 double, 0-255)
%   OldNames    Names of conditions to merge (cell containing 1xN strings)
merge_info = table;
fprintf("Creating merge info table...\n")
for task = ["Play" "React" "Watch"]
    for action = ["Defend" "Eat" "Pick" "Climb"]
        % Name of new condition
        new_name = task + "_" + action;

        % Name(s) of old condition(s)
        old_names = [(task + "_High_" + action) , (task + "_Low_" + action)];

        % Use the colour from the first old condition
        ind = find(cond_names == old_names(1));
        if length(ind) ~= 1
            error("Failed to find exactly one match for %s", old_names(1))
        end
        new_colour = cond_colours(ind, :);

        % Add to table
        merge_info(end+1, ["NewName" "NewColour" "OldNames"]) = { new_name , new_colour , {old_names} };
    end
end
disp(merge_info)

% Run merge on each PRT
for i = 1:prts_count
    filepath_input = [prts(i).folder filesep prts(i).name];
    filepath_output = [folder_output.char prts(i).name];

    fprintf("Merging %d of %d\n", i, prts_count);
    PRT_Merge_Conditions(filepath_input=filepath_input, filepath_output=filepath_output, merge_info=merge_info)
end
