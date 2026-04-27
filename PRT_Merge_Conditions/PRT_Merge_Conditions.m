% PRT_Merge_Conditions(args)
%
% Combines and/or reorders and/or recolours the conditions in a PRT and
% saves the modified copy.
%
% Inputs:
%   filepath_input      filepath to read PRT (1x1 string)
%   filepath_output     filepath to write to (1x1 string)
%   merge_info          table outlining new conditions (see below) (Nx3 table)
%
% merge_info Columns:
%   NewName             Name of new condition (1x1 string)
%   NewColour           Colour of new condition (1x3 double, 0-255)
%   OldNames            Names of conditions to merge (cell containing 1xN strings)
%
function PRT_Merge_Conditions(args)

arguments
    args.filepath_input     (1,1) string {mustBeNonzeroLengthText}
    args.filepath_output    (1,1) string {mustBeNonzeroLengthText}
    args.merge_info         (:,:) table  {mustBeNonempty}
end

% All inputs are required
sd = setdiff(["filepath_input" "filepath_output" "merge_info"], fields(args));
if ~isempty(sd)
    error("Missing argument(s): %s", strjoin(sd, ", "))
end

% Check merge_info fields
sd = setdiff(["NewName" "NewColour" "OldNames"], args.merge_info.Properties.VariableNames);
if ~isempty(sd)
    error("Missing field(s) in merge_info: %s", strjoin(sd, ", "))
end

% Check that all new conditions are unique
if length(args.merge_info.NewName) ~= length(unique(args.merge_info.NewName))
    error("New condition names contains one or more duplicate")
end

% Load PRT
fprintf("\tReading: %s\n", args.filepath_input);
prt = xff(args.filepath_input.char);

% Copy prior conditions, then clean clear conditions
prior_cond = prt.Cond;
prior_cond_names = arrayfun(@(x) string(x.ConditionName), prior_cond');
prt.Cond = prt.Cond([]);

% Add new conditions
fprintf("\tMerging conditions...\n");
for c = 1:height(args.merge_info)
    % get merge info
    new_name = args.merge_info.NewName(c);
    new_colour = args.merge_info.NewColour(c,:);
    old_names = args.merge_info.OldNames{c};

    % check for duplicates
    if length(old_names) ~= length(unique(old_names))
        error("%s contains duplicate prior conditions", new_name)
    end

    % find prior conditions
    try
        ind_old = arrayfun(@(x) find(prior_cond_names == x), old_names);
    catch
        error("Did not find exactly one match for each prior condition of %s", new_name)
    end

    for i = 1:length(old_names)
        if i==1
            % copy first condition
            cond = prior_cond( ind_old(i) );

            % overwrite name and colour
            cond.ConditionName = {new_name.char};
            cond.Color = new_colour;
        else
            % append subsequent conditions
            cond.OnOffsets = [cond.OnOffsets; prior_cond( ind_old(i) ).OnOffsets];
            cond.Weights = [cond.Weights; prior_cond( ind_old(i) ).Weights];
        end
    end

    % sort events by onset
    [~, order] = sort(cond.OnOffsets(:,1), "ascend");
    cond.OnOffsets = cond.OnOffsets(order, :);
    cond.Weights = cond.Weights(order, :);

    % merge events if needed
    %TODO

    % store
    prt.Cond(c) = cond;
end

% Count
prt.NrOfConditions = length(prt.Cond);

% Output folder?
folder = fileparts(args.filepath_output);
if ~exist(folder, "dir")
    mkdir(folder);
end

% Save
fprintf("\tWriting: %s\n", args.filepath_output);
prt.SaveAs(args.filepath_output.char);
prt.ClearObject;
