% RTC_Convolve
%
% Convolves boxcar RTC(s) with HRF
%
% Inputs:
%   search_term     search term for finding RTC(s), can include folder path (e.g., "C:\Data\*.rtc")
%   suffix          suffix to append to new RTC file
%   hrf             (optional) HRF function to use instead of default (must start at time=1, not time=0)
%
function RTC_Convolve(args)

arguments
    args.search_term (1,1) string = "*_boxcar.rtc"
    args.suffix (1,1) string = "_convolved"
    args.hrf (:,1) double
end


%% find RTC(s)
list = dir(args.search_term);
list_count = length(list);
if ~list_count
    error("No files found for search term: %s", args.search_term)
end


%% HRF
if ~isfield("hrf", args)
    % Using BV defaults:
    %   two gamma
    %   onset = 0
    %   undershoot ratio = 6
    %   time to peak = 6
    %   time to undershoot peak = 16
    %   response dispersion = 1
    %   undershoot dispersion = 1

    % NeuroElf function inputs:
    %
    %       shape       HRF general shape {'twogamma' [, 'boynton']}
    %       sf          HRF sample frequency (default: 1s/16, OK: [1e-3 .. 5])
    %       pttp        time to positive (response) peak (default: 5 secs)
    %       nttp        time to negative (undershoot) peak (default: 15 secs)
    %       pnr         pos-to-neg ratio (default: 6, OK: [1 .. Inf])
    %       ons         onset of the HRF (default: 0 secs, OK: [-5 .. 5])
    %       pdsp        dispersion of positive gamma PDF (default: 1)
    %       ndsp        dispersion of negative gamma PDF (default: 1)

    shape = 'twogamma';
    sf = 1;
    pttp = 6;
    nttp = 16;
    pnr = 6;
    ons = -1; % the filter method used needs the hrf to start at time=1 (defaults to include time=0)
    pdsp = 1;
    ndsp = 1;
    
    ne = neuroelf;
    [args.hrf, hrf_time] = ne.hrf(shape, sf, pttp, nttp, pnr, ons, pdsp, ndsp);

    % plot for verification
    % % plot(hrf_time, args.hrf)
    % % title("HRF Used")
    % % xlabel("Seconds")
end


%% process
for fid = 1:list_count
    filepath = [list(fid).folder filesep list(fid).name];
    fprintf("Processing %d of %d: %s\n", fid, list_count, filepath);

    % load
    rtc = xff(filepath);

    % convolve
    boxcar = rtc.SDMMatrix;
    convolved = filter(args.hrf, 1, boxcar);

    % filename
    [~,name,~] = fileparts(list(fid).name);
    filepath = [list(fid).folder filesep name args.suffix.char '.rtc'];

    % write file
    file = fopen(filepath, "w");
    fprintf(file, "FileVersion:     2\n");
    fprintf(file, "Type:            CorrelationReference\n");
    fprintf(file, "NrOfRTCs:        1\n");
    fprintf(file, "NrOfDataPoints:  %d\n", length(convolved));
    fprintf(file, "\n");
    fprintf(file, """CorrelationReference""");
    for i = 1:length(convolved)
        fprintf(file, "\n%0.6f", convolved(i));
    end

    % cleanup
    fclose(file);
    rtc.ClearObject;
end


%% Done
disp Done!


