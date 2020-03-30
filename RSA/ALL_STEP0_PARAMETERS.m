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
    p.FULL_PATH_TO_PARAMETER_SCRIPT_DIR = directory;
    
    %make sure p.VOI_FILE is cell
    if ~iscell(p.VOI_FILE)
        p.VOI_FILE = {p.VOI_FILE};
    end
    
    %add directory to each voi path (unless already is path)
    if length(p.VOI_FILE)>1 | ~isnan(p.VOI_FILE{1})
        for v = 1:length(p.VOI_FILE)
            voi_file = p.VOI_FILE{v};
            if ~any(voi_file == filesep)
                p.VOI_FILE{v} = [directory p.VOI_FILE{v}];
            end
        end
    end
    
    %add directory to any filepath starting with .
    all_fields = fields(p);
    filepath_fields = all_fields(cellfun(@(x) any(strfind(x,'FILEPATH_')),all_fields));
    for field = filepath_fields'
        field = field{1};
        value = getfield(p, field);
        if value(1) == '.'
            value = [directory value];
            p = setfield(p, field, value);
        end
    end
    
    %add directory to filelist
    p.FILELIST_FILENAME = [directory p.FILELIST_FILENAME];
    
    %check new fields
    fs = fields(p);
    if ~any(strcmp(fs, 'RENUMBER_RUNS'))
        warning('Parameter file does not contain the new field "p.RENUMBER_RUNS". This field will be defaulted to false.')
        p.RENUMBER_RUNS = false;
    end
    
    if ~any(strcmp(fs, 'INDIVIDUAL_MODEL_NOISE_CEILING'))
        warning('Parameter file does not contain the new field "p.INDIVIDUAL_MODEL_NOISE_CEILING". This field will be defaulted to true.')
        p.INDIVIDUAL_MODEL_NOISE_CEILING = true;
    end
    
    if ~any(strcmp(fs, 'RSM_PREDICTOR_ORDER'))
        warning('Parameter file does not contain the new field "p.RSM_PREDICTOR_ORDER". This field will be defaulted to [1:p.NUMBER_OF_CONDITIONS]')
        p.RSM_PREDICTOR_ORDER = 1:p.NUMBER_OF_CONDITIONS;
    elseif length(p.RSM_PREDICTOR_ORDER)==1
        %left as nan (or an invalid array of 1), defaults to 1:p.NUMBER_OF_CONDITIONS
        p.RSM_PREDICTOR_ORDER = 1:p.NUMBER_OF_CONDITIONS;
    end
    
    if ~any(strcmp(fs, 'VOI_USE_SPLIT'))
        warning('Parameter file does not contain the new field "p.VOI_USE_SPLIT". This field will be defaulted to true.')
        p.VOI_USE_SPLIT = true;
    end
    
    if ~any(strcmp(fs, 'CUSTOM_VOI_SUMMARY_FIGURES'))
        warning('Parameter file does not contain the new field "p.CUSTOM_VOI_SUMMARY_FIGURES". This field will be defaulted to empty.')
        p.CUSTOM_VOI_SUMMARY_FIGURES = [];
    end
    
    if ~any(strcmp(fs, 'CREATE_FIGURE_NOISE_CEILING'))
        warning('Parameter file does not contain the new field "p.CREATE_FIGURE_NOISE_CEILING". This field will be defaulted to true.')
        p.CREATE_FIGURE_NOISE_CEILING = true;
    end
    
    if ~any(strcmp(fs, 'CREATE_FIGURE_SUMMARY'))
        warning('Parameter file does not contain the new field "p.CREATE_FIGURE_SUMMARY". This field will be defaulted to true.')
        p.CREATE_FIGURE_SUMMARY = true;
    end
    
    if ~any(strcmp(fs, 'ALLOW_MISSING_CONDITIONS_IN_VOI_ANALYSIS'))
        warning('Parameter file does not contain the new field "p.ALLOW_MISSING_CONDITIONS_IN_VOI_ANALYSIS". This field will be defaulted to false.')
        p.ALLOW_MISSING_CONDITIONS_IN_VOI_ANALYSIS = false;
    end
    
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES) 
        for c = 1:length(p.CUSTOM_VOI_SUMMARY_FIGURES)
            if ~isfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c), 'NORMALIZE_TO_NOISE_CEILING_LOWER_BOUND') || isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).NORMALIZE_TO_NOISE_CEILING_LOWER_BOUND)
                warning('Parameter file does not contain the new field "p.CUSTOM_VOI_SUMMARY_FIGURES(%d).NORMALIZE_TO_NOISE_CEILING_LOWER_BOUND". This field will be defaulted to false.', c)
                p.CUSTOM_VOI_SUMMARY_FIGURES(c).NORMALIZE_TO_NOISE_CEILING_LOWER_BOUND = false;
            end
        end
    end
    
catch err
	cd(return_path);
	rethrow(err);
end
cd(return_path);