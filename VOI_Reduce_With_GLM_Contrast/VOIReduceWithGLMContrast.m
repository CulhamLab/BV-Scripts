% VOIReduceWithGLMContrast(filepath_voi, filepath_glm, max_voxels, min_t_abs, contrast, filepath_save, overwrite, require_max_voxels, allow_unbalanced)
%
% Reduce each VOI to the most significant voxels in a contrast. Selects up
% to "max_voxels" voxels (can be inf for no limit) with absolute t-values
% of at least "min_t_abs" (can be 0 for no threshold).
% 
% Operates at the resolution of the VOI. For example, if the VOI is defined
% at 1mm but you want to select voxels at the functional resolution (>1mm),
% then you would need to downsample the VOI prior to using this function.
%
% filepath_voi          char        required        Filepath to read VOI
%
% filepath_glm          char        required        Filepath to read GLM
%
% max_voxels            numeric     default=inf     Maximum number of voxels to select
%
% min_t_abs             numeric     default=0       Minimum absolute t-value to select
%
% contrast              [numeric]   default=[]      Contrast vector. Defaults to all predictors of interest > baseline.
%
% filepath_save         char        default=[]      Filepath to write masked VOI. If empty, defaults to auto-generated.
%
% overwrite             logical     default=false   Allow overwriting if output file already exists
%
% require_max_voxels   	logical     default=false   If true, an error is thrown when there are not at least max_voxels selected
%
% allow_unbalanced      logical     default=false   If true, an error is thrown when an unbalanced contrast is given
%
function VOIReduceWithGLMContrast(filepath_voi, filepath_glm, max_voxels, min_t_abs, contrast, filepath_save, overwrite, require_max_voxels, allow_unbalanced)

%% Inputs

if ~exist('filepath_voi', 'var') || isempty(filepath_voi)
    error('Missing input: filepath_voi');
elseif ~exist(filepath_voi, 'file')
    error('VOI does not exist: %s', filepath_voi);
end

if ~exist('filepath_glm', 'var') || isempty(filepath_glm)
    error('Missing input: filepath_voi');
elseif ~exist(filepath_glm, 'file')
    error('GLM does not exist: %s', filepath_glm);
end

if ~exist('max_voxels', 'var') || isempty(max_voxels)
    max_voxels = inf;
end

if ~exist('min_t_abs', 'var') || isempty(min_t_abs)
    min_t_abs = 0;
end

if ~exist('contrast', 'var') || isempty(contrast)
    auto_contrast = true;
else
    auto_contrast = false;
end

if ~exist('filepath_save', 'var') || isempty(filepath_save)
    [voi_fol,voi_name] = fileparts(filepath_voi);
    [~,glm_name] = fileparts(filepath_glm);
    filepath_save = sprintf('%s%s%s_ReduceWithGLMContrast-%s-%dvox-t>%g.voi', voi_fol, filesep, voi_name, glm_name, max_voxels, min_t_abs);
end

if ~exist('overwrite', 'var') || isempty(overwrite)
    overwrite = false;
end

if ~exist('require_max_voxels', 'var') || isempty(require_max_voxels)
    require_max_voxels = false;
end

if ~exist('allow_unbalanced', 'var') || isempty(allow_unbalanced)
    allow_unbalanced = false;
end

%% Check Overwrite

if exist(filepath_save, 'file') && ~overwrite
    error('Output file already exists and overwrite is false')
end

%% Make Output Folder

fol = fileparts(filepath_save);
if ~isempty(fol) && ~exist(fol, 'dir')
    mkdir(fol);
end

%% GLM

%load
glm = xff(filepath_glm);

%make auto-contrast
if auto_contrast
    number_poi = glm.NrOfPredictors - glm.NrOfConfounds;
    contrast = ones(1, number_poi);
end

%check contrast balance
if length(unique(contrast(contrast~=0))) > 1
    if abs(sum(contrast)) > 0.01
        if allow_unbalanced
            warning('Contrast is unbalanced but allow_unbalancedis true')
        else
            error('Contrast is unbalanced')
        end
    end
end

%% Contrast

%calculate contrast t-map
opt = struct('interp',false);
if glm.ProjectTypeRFX
    ctr =  glm.RFX_tMap(contrast, opt);
else
    ctr =  glm.FFX_tMap(contrast, opt);
end

%check for exactly one t-map
if ctr.NrOfMaps ~= 1
    error('Contrast calculation did not produce exactly one t-map.')
end

%bounding box
bb = ctr.BoundingBox;

%% VOI

%load
voi = xff(filepath_voi);

%must be MNI space
if ~strcmp(voi.ReferenceSpace, 'MNI')
    error('VOI ReferenceSpace (%s) must be MNI. VOI_BV2MNI may help resolve this.', voi.ReferenceSpace)
end

%process each voi
for v = 1:voi.NrOfVOIs
    %get values
    tvalues = ctr.VoxelStats(1, voi.BVCoords(v, bb) + 1);
    
    %will use absolute
    tvalues_abs = abs(tvalues);
    
    %sort values
    [tvalues_abs_sort, indicies] = sort(tvalues_abs, 'descend');
    
    %apply threshold
    last = find(tvalues_abs_sort >= min_t_abs, 1, 'last');
    tvalues_abs_sort = tvalues_abs_sort(1:last);
    indicies = indicies(1:last);
    
    %apply max number of voxels
    nvox = length(tvalues_abs_sort);
    if nvox < max_voxels
        if require_max_voxels
            error('%s did not contain at least %d voxels above %g (contained %d)', voi.VOI(v).Name, max_voxels, min_t_abs, nvox);
        else
            %use fewer voxels
        end
    else
        tvalues_abs_sort = tvalues_abs_sort(1:max_voxels);
        indicies = indicies(1:max_voxels);
    end
    
    %set voxels
    voi.VOI(v).Voxels = voi.VOI(v).Voxels(indicies,:);
    voi.VOI(v).NrOfVoxels = size(voi.VOI(v).Voxels, 1);
    
    %warn if no voxels
    if ~voi.VOI(v).NrOfVoxels
        warning('%s did not contain any voxels above %g', voi.VOI(v).Name, min_t_abs);
    end
end

%% Save

fprintf('Writing: %s\n', filepath_save);
voi.SaveAs(filepath_save);

%% Cleanup

glm.ClearObject;
ctr.ClearObject;
voi.ClearObject;
