%Combine 
function aux_VOI_combineLeftRight

try
    return_path = pwd;
    cd ..
    p = ALL_STEP0_PARAMETERS;
    
    %filepaths
    fp = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep 'VOI_RSMs.mat'];
    fp_backup = strrep(fp, '.mat', '_BeforeCombineLeftRight.mat');
    
    %backup
    if exist(fp_backup, 'file')
        error('BeforeCombineLeftRight file already exists: %s', fp_backup);
    else
        copyfile(fp, fp_backup);
    end
    
    %load
    file = load(fp);
    
    %parse names
    names = file.data.VOINames;
    is_left = contains(names, 'Left');
    is_right = contains(names, 'Right');
    names_base = strrep(strrep(names, 'Left', ''), 'Right', '');
    names_base = strrep(names_base, ' ', '');
    for i = 1:length(names_base)
        if names_base{i}(1) == '_'
            names_base{i}(1) = [];
        end
    end
    bases = unique(names_base);
    
    %stop if any aren't left/right
    if any(~is_left & ~is_right)
        error('One or more VOIs cannot be identified as "Left" or "Right"')
    elseif any(is_left & is_right)
        error('One or more VOIs contains both "Left" and "Right"')
    end
    
    %init
    rsm_size = size(file.data.RSM_split);
    num_bases = length(bases);
    VOINames = cell(1, num_bases);
    VOINames_short = cell(1, num_bases);
    VOInumVox = nan(1, num_bases);
    RSM_split = nan([rsm_size(1:3) num_bases]);
    RSM_nonsplit = nan([rsm_size(1:3) num_bases]);
    
    %combine
    used = false(1, length(names));
    for i = 1:num_bases
        base = bases{i};
        
        %find left
        ind_left = find(contains(names_base, base) & is_left & ~used);
        if length(ind_left) ~= 1
            error('Failed to find a single unused voi for Left %s', base); 
        end
        used(ind_left) = true;
        
        %find right
        ind_right = find(contains(names_base, base) & is_right & ~used);
        if length(ind_right) ~= 1
            error('Failed to find a single unused voi for Right %s', base); 
        end
        used(ind_right) = true;
        
        %indices
        inds = [ind_left ind_right];
        
        %names
        VOINames{i} = base;
        VOINames_short{i} = base;
        
        %#vox (use sum)
        VOInumVox(i) = sum(file.data.VOInumVox(inds));
        
        %RSM split
        RSM_split(:,:,:,i) = CombineRSM(file.data.RSM_split(:,:,:,inds));
        
        %RSM nonsplit
        RSM_nonsplit(:,:,:,i) = CombineRSM(file.data.RSM_nonsplit(:,:,:,inds));
    end
    
    %all were used?
    if any(~used)
        error('One or more VOIs was not selected (shouldn''t be possible)')
    end
    
    %overwrite in struct
    file.data.VOINames = VOINames;
    file.data.VOINames_short = VOINames_short;
    file.data.VOInumVox = VOInumVox;
    file.data.RSM_split = RSM_split;
    file.data.RSM_nonsplit = RSM_nonsplit;
    
    %save
    fprintf('Overwriting with combined VOIs: %s\n', fp)
    save(fp, '-struct', 'file')
    
    %done
    disp Done.
    
    cd(return_path);
catch err
    cd(return_path);
    warning('Could not load VOI RSMs. Has VOI step6 been run or has data moved?')
    rethrow(err);
end


function [rsms] = CombineRSM(rsms)
%no support for missing values
if any(isnan(rsms(:)))
    error('RSM contains NaNs')
end

%average across 4th dim (Left/Right VOI)
rsms = nanmean(rsms, 4);

