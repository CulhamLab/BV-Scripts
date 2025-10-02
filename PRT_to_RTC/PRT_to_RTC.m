% PRT_to_RTC
%
% Combines events in PRT(s) into a boxcar and writes as RTC
%
% Inputs:
%   search_term             search term for finding PRTs, can include folder path (e.g., "C:\Data\*.prt")
%   conditions_to_combine   names of events to combine
%   number_volumes          number of volumes
%   suffix                  suffix to append to RTC file
%   TR                      TR in seconds
%
function PRT_to_RTC(args)

arguments
    args.search_term (1,1) string = "*.prt"
    args.conditions_to_combine (1,:) string
    args.number_volumes (1,1) double
    args.suffix (1,1) string = "_boxcar"
    args.TR (1,1) double = 1
end


%% find PRT
list = dir(args.search_term);
list_count = length(list);
if ~list_count
    error("No files found for search term: %s", args.search_term)
end


%% process
for fid = 1:list_count
    filepath = [list(fid).folder filesep list(fid).name];
    fprintf("Processing %d of %d: %s\n", fid, list_count, filepath);

    % load
    prt = xff(filepath);

    % find condition indices to combine
    conds = arrayfun(@(c) find(strcmp(prt.ConditionNames, c)), args.conditions_to_combine);

    % initialize
    rtc = zeros(args.number_volumes, 1);

    % add conditions
    for c = conds
        % get
        onoff = prt.Cond(c).OnOffsets;
        
        % convert to volumes?
        if strcmp(prt.ResolutionOfTime, "msec")
            onoff = (onoff / (1000 * args.TR)) + [1 0];
        end

        % add
        for evt = 1:size(onoff,1)
            rtc(onoff(evt,1):onoff(evt,2)) = 1;
        end
    end
    if length(rtc) ~= args.number_volumes
        error("Number of volumes was set incorrectly")
    end
    
    % filename
    [~,name,~] = fileparts(list(fid).name);
    filepath = [list(fid).folder filesep name args.suffix.char '.rtc'];

    % write file
    file = fopen(filepath, "w");
    fprintf(file, "FileVersion:     2\n");
    fprintf(file, "Type:            CorrelationReference\n");
    fprintf(file, "NrOfRTCs:        1\n");
    fprintf(file, "NrOfDataPoints:  %d\n", args.number_volumes);
    fprintf(file, "\n");
    fprintf(file, """CorrelationReference""");
    for i = 1:args.number_volumes
        fprintf(file, "\n%0.6f", rtc(i));
    end

    % cleanup
    fclose(file);
    prt.ClearObject;

end


%% Done
disp Done!