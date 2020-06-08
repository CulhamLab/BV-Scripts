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
    
    %Select first valid filepath, ensure that the correct file separators are
	%used (/ or \), and ensure that filepaths end in a file separator
    p_fields = fields(p);
    p_fields_filepath = p_fields(contains(p_fields,'FILEPATH_'));
	for field_name = p_fields_filepath'
        field_name = field_name{1};
        temp = getfield(p, field_name);
        if ~iscell(temp)
            temp = {temp};
        end
		foundPath = false;
		for i = 1:length(temp)
			filepath = temp{i};
			filepath(filepath=='\' | filepath=='/') = filesep;
			if filepath(end)~=filesep
				filepath = [filepath filesep];
			end
			if exist(filepath,'dir')
				foundPath = true;
				break
			end
		end
		if ~foundPath
			error(sprintf('No valid path was found in %s.\n',field_name))
        else
            p = setfield(p, field_name, filepath);
		end
	end

	%Create subfolders if they do not yet exist
    p_fields_subfolder = p_fields(contains(p_fields,'SUBFOLDER_'));
	for field_name = p_fields_subfolder'
        field_name = field_name{1};
        fullpath = [p.FILEPATH_TO_SAVE_LOCATION getfield(p, field_name)];
        if ~exist(fullpath, 'dir')
            mkdir(fullpath);
        end
	end
    
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
    filepath_fields = all_fields( contains(all_fields, 'FILEPATH_') | strcmp(all_fields, 'MSK_FILE') );
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
    
    %add version timestamp
    %1. April 24, 2020
    %   -new odd/even split method (mandatory)
    %   -track runtime info in data files
	%2. May 12, 2020
	%	-add support for participant-specific models
	%	-move last bits of prep from param file to this script
    %   -searchlight slow RSM method now only used when needed
    %   -support relative paths for MSK_FILE
    %   -VMR file can now be used to mask searchlight VMPs (uses intensity>10)
    %   -searchlight VMPs now contain voxel counts for BV's Bonferroni (adjusted by mask)
    %3. May 19, 2020
    %   -added model comparison t-maps to searchlight (see new parameter SEARCHLIGHT_MODEL_COMPARISON_TTEST in example)
	%4. June 8, 2020
	%	-fix crashes: step1, ROI step6+7 when missing data and all splits, 
	%	-diag and similar models are now automatically exlcuded from nonsplit MDS
	%	-step1 now supports runs with empty predictors
	%	-prep for DO_ALL_SPLITS_VOI will now occur even if VOI_USE_SPLIT is not currently true
	%	-ROI step9 now creates both split and nonsplit
	%	-ROI step10 generic noise ceiling is now corrected for the new split method (i.e., don't use whole matrix)
	%	-ROI step6 no longer preloads all subject data, which could run out of memory in large datasets
    p.RUNTIME.VERSION = 4;
    p.RUNTIME.RUN = datetime('now');
    
	%copy for nonsplit model, clear lower half plus diag (keep upper)
	[row,col] = ind2sub([p.NUMBER_OF_CONDITIONS p.NUMBER_OF_CONDITIONS],1:(p.NUMBER_OF_CONDITIONS^2));
	indClear = find(col <= row);
	for i = 1:length(p.MODELS.matrices)
		for j = 1:size(p.MODELS.matrices{i}, 3)
			mat = p.MODELS.matrices{i}(:,:,j);
			mat(indClear) = nan;
			p.MODELS.matricesNonsplit{i}(:,:,j) = mat;
		end
	end
	
    %remove split model lower half (keep upper + diag)
    [row,col] = ind2sub([p.NUMBER_OF_CONDITIONS p.NUMBER_OF_CONDITIONS],1:(p.NUMBER_OF_CONDITIONS^2));
    indClear = find(col < row);
	for i = 1:length(p.MODELS.matrices)
		for j = 1:size(p.MODELS.matrices{i}, 3)
			mat = p.MODELS.matrices{i}(:,:,j);
			mat(indClear) = nan;
			p.MODELS.matrices{i}(:,:,j) = mat;
		end
	end
	
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
    
    if ~any(strcmp(fs, 'DO_ALL_SPLITS_VOI'))
        warning('Parameter file does not contain the new field "p.DO_ALL_SPLITS_VOI". This field will be defaulted to false.')
        p.DO_ALL_SPLITS_VOI = false;
    end
    
    if ~isempty(p.CUSTOM_VOI_SUMMARY_FIGURES) 
        for c = 1:length(p.CUSTOM_VOI_SUMMARY_FIGURES)
            if ~isfield(p.CUSTOM_VOI_SUMMARY_FIGURES(c), 'NORMALIZE_TO_NOISE_CEILING_LOWER_BOUND') || isempty(p.CUSTOM_VOI_SUMMARY_FIGURES(c).NORMALIZE_TO_NOISE_CEILING_LOWER_BOUND)
                warning('Parameter file does not contain the new field "p.CUSTOM_VOI_SUMMARY_FIGURES(%d).NORMALIZE_TO_NOISE_CEILING_LOWER_BOUND". This field will be defaulted to false.', c)
                p.CUSTOM_VOI_SUMMARY_FIGURES(c).NORMALIZE_TO_NOISE_CEILING_LOWER_BOUND = false;
            end
        end
    end
    
    if ~any(strcmp(fs, 'SEARCHLIGHT_MODEL_COMPARISON_TTEST'))
        warning('Parameter file does not contain the new field "p.SEARCHLIGHT_MODEL_COMPARISON_TTEST". This field will be defaulted to empty [].')
        p.SEARCHLIGHT_MODEL_COMPARISON_TTEST = [];
    else
        %check SEARCHLIGHT_MODEL_COMPARISON_TTEST
        if any(any(cellfun(@(x) ~any(strcmp(p.MODELS.names,x)), p.SEARCHLIGHT_MODEL_COMPARISON_TTEST)))
            error('Parameter SEARCHLIGHT_MODEL_COMPARISON_TTEST contains one or more unknown model name')
        end
    end
    
catch err
	cd(return_path);
	rethrow(err);
end
cd(return_path);