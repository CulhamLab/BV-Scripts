function BOTH_STEP1_getBetas

%% Get Parameters
[p] = ALL_STEP0_PARAMETERS;

%% Prepare Output Directory
outfol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '1-2. Betas' filesep];
if ~exist(outfol,'dir')
    mkdir(outfol)
end

%% Find Files
for par = 1:p.NUMBER_OF_PARTICIPANTS
    if p.FILELIST_SUBFOLDERS
        directory = [p.FILEPATH_TO_VTC_AND_SDM p.FILELIST_PAR_ID{par} filesep];
    else
        directory = p.FILEPATH_TO_VTC_AND_SDM;
    end
    
    for run = 1:p.NUMBER_OF_RUNS
        %find output file
        d(run,par).out.filepath = sprintf('%s%s_%s.mat', outfol, p.FILELIST_PAR_ID{par}, p.FILELIST_RUN_ID{run});
        d(run,par).need_betas = ~exist(d(run,par).out.filepath, 'file');
        if ~d(run,par).need_betas
            continue
        end
        
        %find input files
        for type_id = 1:3
            switch type_id
                case 1
                    search_string = strrep(strrep(p.FILELIST_FORMAT_VTC,'[PAR]',p.FILELIST_PAR_ID{par}),'[RUN]',p.FILELIST_RUN_ID{run});
                    type = 'vtc';
                case 2
                    search_string = strrep(strrep(p.FILELIST_FORMAT_SDM,'[PAR]',p.FILELIST_PAR_ID{par}),'[RUN]',p.FILELIST_RUN_ID{run});
                    type = 'sdm';
                case 3
                    search_string = strrep(strrep(strrep(p.FILELIST_FORMAT_SDM,'.sdm','_ForRSA.glm'),'[PAR]',p.FILELIST_PAR_ID{par}),'[RUN]',p.FILELIST_RUN_ID{run});
                    type = 'glm';
            end
            
            list = dir(fullfile(directory, '**', search_string));
            if length(list)>1
                error('Multiple results for search string: [%s] in [%s]', search_string, directory);
            end
            
            found = ~isempty(list);
            eval(sprintf('d(run,par).%s.found = found;', type));
            if found
                eval(sprintf('d(run,par).%s.filepath = [list.folder filesep list.name];', type));
            end
        end
        
        %need to run glm?
        d(run,par).run_glm = ~d(run,par).glm.found;
        
        %has file to run glm?
        if d(run,par).run_glm
            if ~d(run,par).vtc.found || ~d(run,par).sdm.found
                d(run,par).run_glm = false;
                warning('GLM and VTC+SDM could not be found for %s_%s. Assumed to be missing.', p.FILELIST_PAR_ID{par}, p.FILELIST_RUN_ID{run});
            end
        end
    end
end

%% Run GLMs
ind_run = find([d.run_glm]);
num_glms = length(ind_run);
if num_glms
    fprintf('Running %d GLMs...\n', num_glms);
    
    %open BV
    try
        bv = actxserver('BrainVoyager.BrainVoyagerScriptAccess.1');
    catch
        error('Could not connect to BV. Check MATLAB COM access.')
    end
    
    %open MNI template
    doc = bv.OpenDocument([pwd filesep 'ICBM452-IN-MNI152-SPACE_BRAIN.vmr']);
    
    %run each
    for i = 1:num_glms
        %filepaths
        ind = ind_run(i);
        fp_mdm = strrep(d(ind).sdm.filepath, '.sdm', '_ForRSA.mdm');
        d(ind).glm.filepath = strrep(fp_mdm, '.mdm', '.glm');
        [~,fn,~] = fileparts(d(ind).glm.filepath);
        fprintf('\tRunning %d of %d: %s\n', i, num_glms, fn);
        
        %create mdm
        mdm = xff('mdm');
        mdm.RFX_GLM = 0;
        mdm.PSCTransformation = 1;
        mdm.zTransformation = 0;
        mdm.SeparatePredictors = 0;
        mdm.NrOfStudies = 1;
        mdm.XTC_RTC = {d(ind).vtc.filepath , d(ind).sdm.filepath};
        mdm.SaveAs(fp_mdm);
        mdm.ClearObject;
        clear mdm;
        
        %run glm
        doc.ClearMultiStudyGLMDefinition;
        doc.LoadMultiStudyGLMDefinitionFile(fp_mdm);
        doc.ComputeMultiStudyGLM;
        doc.SaveGLM(d(ind).glm.filepath);
        d(ind).glm.found = true;
        
        %delete mdm
        doc.ClearMultiStudyGLMDefinition;
        delete(fp_mdm);
    end
    
    %close BV
    bv.Exit;
end

%% Extract Betas

%Legend (saved in each beta file)
VariableHelp.betas = 'rows: voxels, columns: conditions';
VariableHelp.vox = 'row: voxels, columns = XYZ';
VariableHelp.vtcRes = 'resolution of functional space';
VariableHelp.vtcFilepath = 'path to time course used';
VariableHelp.sdmFilepath = 'path to design matrix used';
VariableHelp.voiWholeBrain = 'BVQX voi struct for the whole-brain.';

%expected data matrix size
expected_data_size = ceil([range([p.BBOX.XStart p.BBOX.XEnd]) range([p.BBOX.YStart p.BBOX.YEnd]) range([p.BBOX.ZStart p.BBOX.ZEnd])] / p.FUNCTIONAL_RESOLUTION);
number_voxels = prod(expected_data_size);

%voxel coords
[xs,ys,zs] = ind2sub(expected_data_size, 1:number_voxels);
vox = (([xs' ys' zs'] - 1) * p.FUNCTIONAL_RESOLUTION) + [p.BBOX.XStart p.BBOX.YStart p.BBOX.ZStart] + 1;

%run each
ind_extract = find(arrayfun(@(i) i.need_betas && i.glm.found, d));
num_extract = length(ind_extract);
fprintf('Extracting betas from %d GLMs...\n', num_extract);
for i = 1:num_extract
    ind = ind_extract(i);
    [~,fn,~] = fileparts(d(ind).out.filepath);
    fprintf('\tRunning %d of %d: %s\n', i, num_extract, fn);
    
    %init struct of data to save
    tosave = struct;
    
    %load glm
    glm = xff(d(ind).glm.filepath);
    
    %check bounding box
    if (p.BBOX.XStart ~= glm.XStart) || (p.BBOX.XEnd ~= glm.XEnd) || ...
            (p.BBOX.YStart ~= glm.YStart) || (p.BBOX.YEnd ~= glm.YEnd) || ...
            (p.BBOX.ZStart ~= glm.ZStart) || (p.BBOX.ZEnd ~= glm.ZEnd)
        p.BBOX
        glm
        error('Invalid BBOX')
    end
    
    %check res
    if glm.Resolution ~= p.FUNCTIONAL_RESOLUTION
        error('Invalid VTC resolution')
    end
    
    %check data size
    data_size = size(glm.GLMData.BetaMaps);
    data_size = data_size(1:3);
    if any(data_size ~= expected_data_size)
        error('Invalid data matrix size')
    end
    
    %get pred names
    glm_cond_names = arrayfun(@(x) x.Name2, glm.Predictor, 'UniformOutput', false);
    
    %select pred (exclude PONI)
    ind_cond_use = find(cellfun(@isempty, regexp(glm_cond_names,'Study \d+: \d*')));
    num_cond = length(ind_cond_use);
    cond_names_use = glm_cond_names(ind_cond_use);
    
    %init beta
    tosave.betas = nan( number_voxels , num_cond );
    
    %copy betas
    for c = 1:num_cond
        values = glm.GLMData.BetaMaps(:,:,:,ind_cond_use(c));
        values(values==0) = nan;
        tosave.betas(:,c) = values(:);
    end
    
    %clear
    glm.ClearObject;
    
    %ensure no 0s in betas
    tosave.betas(tosave.betas == 0) = nan;
    
    %store vox
    tosave.vox = vox;

    %misc
    tosave.sdmFilepath = [];
    tosave.vtcFilepath = [];
    tosave.voiWholeBrain = [];
    tosave.conditionNames = cond_names_use;
    tosave.VariableHelp = VariableHelp;
    tosave.vtcRes = p.FUNCTIONAL_RESOLUTION;
    tosave.box = p.BBOX;

    %save
    save(d(ind).out.filepath, '-struct', 'tosave');
end

%% Complete
fprintf('\n\nBeta extraction complete.\n')

