% PRT search term, can include folder path
search_term = "C:\Data\*.prt";

% which event types to combine into the boxcar
conditions_to_combine = ["Body"    "Face"    "Hand"    "Scrambled"];

% number of volumes
number_volumes = 340;

% TR
TR = 1;

% suffix for the new file(s)
suffix = "_vis-baseline_4corr_boxcar";

% run
PRT_to_RTC(search_term=search_term, ...
           conditions_to_combine=conditions_to_combine, ...
           number_volumes=number_volumes, ...
           TR=TR, ...
           suffix=suffix)