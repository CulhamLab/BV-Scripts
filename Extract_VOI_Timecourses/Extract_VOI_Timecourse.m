function Extract_VOI_Timecourse

%% Parameters

%input files
FILEPATHS_VOI = {
                'D:\The University of Western Ontario\Cassandra Bacher - Masters_Thesis_Study_Data\BIDS\derivatives\VOIs\FFA.voi'
                'D:\The University of Western Ontario\Cassandra Bacher - Masters_Thesis_Study_Data\BIDS\derivatives\VOIs\neurosynth_radius_7mm.voi'
            };
FILEPATHS_VTC = {
                'D:\The University of Western Ontario\Cassandra Bacher - Masters_Thesis_Study_Data\BIDS\derivatives\sub-03\ses-01\func\VTCs THP+SS\sub-03_ses-01_task-MAIN_run-01_bold_SCCTBL_3DMCTS_MNI_THPGLMF3c_SD3DVSS5.00mm.vtc'
                'D:\The University of Western Ontario\Cassandra Bacher - Masters_Thesis_Study_Data\BIDS\derivatives\sub-03\ses-01\func\VTCs THP+SS\sub-03_ses-01_task-MAIN_run-02_bold_SCCTBL_3DMCTS_MNI_THPGLMF3c_SD3DVSS5.00mm.vtc'
            };

%max number of volumes to expect in any VTC
MAX_VOLUMES = 500;

%throw an error if any VOI are not of the expected resolution, set nan to
%disable this check
EXPECTED_VOI_RESOLUTION = 1;
        
%output filepaths
FILEPATH_SAVE_MAT = 'Extract_VOI_Timecourse.mat';
FILEPATH_SAVE_EXCEL = 'Extract_VOI_Timecourse.xlsx';

%options for aft_VOITimeCourse
opts = struct('bvcomp',true,'weight',2);

%% Check Inputs

%adjust file separators for OS
FILEPATHS_VOI = cellfun(@(x) strrep(strrep(x,'/',filesep),'\',filesep), FILEPATHS_VOI, 'UniformOutput',false);
FILEPATHS_VTC = cellfun(@(x) strrep(strrep(x,'/',filesep),'\',filesep), FILEPATHS_VTC, 'UniformOutput',false);

%check that all input files exist
filepaths_all = [FILEPATHS_VOI; FILEPATHS_VTC];
files_exist = cellfun(@(x) exist(x,'file'), filepaths_all);
if any(~files_exist(:))
    ind = ~files_exist(:);
    error('The following files were not found:\n%s', sprintf('%s\n', filepaths_all{ind}))
end

%store filepaths used
data.voi_filepaths = FILEPATHS_VOI;
data.vtc_filepaths = FILEPATHS_VTC;

%filenames
data.voi_filenames = cellfun(@(x) x(max([1 find(x==filesep,1,'last')+1]):end), data.voi_filepaths, 'UniformOutput', false);
data.vtc_filenames = cellfun(@(x) x(max([1 find(x==filesep,1,'last')+1]):end), data.vtc_filepaths, 'UniformOutput', false);

%counts
data.voi_count = length(data.voi_filepaths);
data.vtc_count = length(data.vtc_filepaths);

%% Preload VOIs and Count Maps

%load
vois = xff(data.voi_filepaths);

%count
data.voi_map_counts = cellfun(@(x) x.NrOfVOIs, vois);
data.all_map_count = sum(cellfun(@(x) x.NrOfVOIs, vois));

%names
data.voi_map_names = cellfun(@(voi) arrayfun(@(x) x.Name, voi.VOI, 'UniformOutput', false), vois, 'UniformOutput', false);
data.all_map_names = [data.voi_map_names{:}];

%% Check VOI Resolution

if ~isnan(EXPECTED_VOI_RESOLUTION)
    vois_invalid_res = cell(0);
    for v = 1:data.voi_count
        if any([vois{v}.OriginalVMRResolutionX vois{v}.OriginalVMRResolutionY vois{v}.OriginalVMRResolutionZ] ~= EXPECTED_VOI_RESOLUTION)
            vois_invalid_res{end+1} = data.voi_filepaths{v};
        end
    end
    if ~isempty(vois_invalid_res)
        error('The following VOIs have unexpected resolution:\n%s', sprintf('%s\n', vois_invalid_res{:}))
    end
end

%% Initialize

xls_headers_row = 4;
xls_headers_col = 1;
xls = cell(xls_headers_row + MAX_VOLUMES , xls_headers_col + (data.vtc_count * data.all_map_count));
xls(1:5,1) = {'VTC' 'VOI' 'MapNum' 'MapName' 'Timecourse'};

%% Process

xls_col = xls_headers_col;
for ind_vtc = 1:data.vtc_count
    %load vtc
    vtc = xff(data.vtc_filepaths{ind_vtc});
    
    %init
    data.vtc(ind_vtc).name = data.vtc_filenames{ind_vtc};
    data.vtc(ind_vtc).timecourses = nan(vtc.NrOfVolumes, data.all_map_count);
    
    %process each voi
    map_counter = 0;
    for ind_voi = 1:data.voi_count
        for ind_map = 1:vois{ind_voi}.NrOfVOIs
            map_counter = map_counter + 1;
            
            %extract each voxel timecourse
            voxel_timecourses = vtc.VOITimeCourse(vois{ind_voi}.BVCoords(ind_map,vtc.BoundingBox),opts);
            voxel_timecourses = voxel_timecourses{1};
            
            %set 0 to nan
            voxel_timecourses(voxel_timecourses==0) = nan;
            
            %average across voxels
            timecourse = nanmean(voxel_timecourses,2);
            
            %store
            data.vtc(ind_vtc).timecourses(:,map_counter) = timecourse;
            
            %write to excel matrix
            xls_col = xls_col + 1;
            xls{1,xls_col} = data.vtc(ind_vtc).name;
            xls{2,xls_col} = data.voi_filenames{ind_voi};
            xls{3,xls_col} = ind_map;
            xls{4,xls_col} = vois{ind_voi}.VOI(ind_map).Name;
            xls((1:length(timecourse)) + xls_headers_row,xls_col) = num2cell(timecourse);
        end
    end
    
    %clear vtc
    vtc.ClearObject;
end


%% Clear VOIs
cellfun(@(x) x.ClearObject, vois);

%% Trim Excel
is_empty = cellfun(@isempty, xls);
last_col = find(any(~is_empty,1), 1, 'last');
last_row = find(any(~is_empty,2), 1, 'last');
xls = xls(1:last_row,1:last_col);

%% Save

%mat
data.xls = xls;
save(FILEPATH_SAVE_MAT, '-struct', 'data');

%excel
if exist(FILEPATH_SAVE_EXCEL, 'file')
    delete(FILEPATH_SAVE_EXCEL);
end
xlswrite(FILEPATH_SAVE_EXCEL,xls);

