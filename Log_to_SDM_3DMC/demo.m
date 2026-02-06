%% Choose optional arguments
%   filepath_sdm                        filepath of the sdm file to write (default: filepath_log + ".sdm")
%   overwrite                           whether or not to overwrite existing sdm files (default: false)
%   framewise_displacement_radius_mm    constant used in the framewise displacement calculation, Rainer uses 50 (default: 50)

% we will leave the deafult path and FD constant, but turn overwrite on as an example
arg_overwrite = true;

%% Call on a specific file

fprintf("\n# Example 1: specific log file\n");

% set path to log file (can be relative or absolute)
filepath_log = ".\Demo_Files\example1.log";

% call function
Log_to_SDM_3DMC(filepath_log, overwrite=arg_overwrite)


%% Call on all log files in a folder

fprintf("\n# Example 2: all log files in a folder\n");

% folder to search
folder = ".\Demo_Files\";

% find all *.log files in the folder
list = dir(folder + "*.log");

% run on each file
arrayfun(@(file) Log_to_SDM_3DMC([file.folder filesep file.name], overwrite=arg_overwrite), list);


%% Call on all log files in a folder including subfolders

fprintf("\n# Example 3: all log files in a folder including subfolders\n");

% folder to search
folder = ".\Demo_Files\";

% find all *.log files in the folder and subfolders
list = dir(fullfile(folder, '**', '*.log'));

% run on each file
arrayfun(@(file) Log_to_SDM_3DMC([file.folder filesep file.name], overwrite=arg_overwrite), list);