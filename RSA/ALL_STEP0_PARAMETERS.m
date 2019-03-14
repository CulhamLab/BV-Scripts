function [p] = ALL_STEP0_PARAMETERS

%Path to parameter file
%
%set the path to your parameter script (use ALL_STEP0_PARAMETERS_EXAMPLE.m as a template)
% FULL_PATH_TO_PARAMETER_SCRIPT = 'ALL_STEP0_PARAMETERS_EXAMPLE.m';
%
%if the script is in another directory (e.g., synced in a Dropbox folder or another repo),
%then you must include the directory path
%Example:
%FULL_PATH_TO_PARAMETER_SCRIPT = 'C:\Users\kstubbs4\Documents\GitHub\CC_fMRI_FoodImages\RSA\ALL_STEP0_PARAMETERS_ACT61.m';
FULL_PATH_TO_PARAMETER_SCRIPT = 'ALL_STEP0_PARAMETERS_EXAMPLE.m';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% THERE IS NO NEED TO EDIT BELOW %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%store current path for return
return_path = pwd;

%split filename and directory
last_filesep = find(FULL_PATH_TO_PARAMETER_SCRIPT==filesep,1,'last');
file_is_local = isempty(last_filesep);
if file_is_local
	filename = FULL_PATH_TO_PARAMETER_SCRIPT;
	directory = return_path;
else
	filename = FULL_PATH_TO_PARAMETER_SCRIPT(last_filesep+1:end);
	directory = FULL_PATH_TO_PARAMETER_SCRIPT(1:last_filesep);
end

%remove .m from script name if it was included
if strcmp(filename(end-1:end), '.m')
	filename = filename(1:end-2);
end

%move to script directory if not local
if ~file_is_local
	cd(directory)
end

%get parameters from script and return to original directory
try
	p = eval('%s', filename);
	p.FULL_PATH_TO_PARAMETER_SCRIPT = FULL_PATH_TO_PARAMETER_SCRIPT;
    
    %add directory to each voi path (unless already is path)
    for v = 1:length(p.VOI_FILE)
        voi_file = p.VOI_FILE{v};
        if ~any(voi_file == filesep)
            p.VOI_FILE{v} = [directory p.VOI_FILE{v}];
        end
    end
catch err
	cd(return_path);
	rethrow(err);
end
cd(return_path);