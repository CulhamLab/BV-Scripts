function SEARCHLIGHT_STEP5_ttest

%params
[p] = ALL_STEP0_PARAMETERS;

%paths
vmpFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '8-9. VMPs' filesep];
vmpFol_out = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '10. Masked VMPs' filesep];

%maks fol
if ~exist(vmpFol_out,'dir'), mkdir(vmpFol_out);, end

%load msk file
if isnan(p.MSK_FILE)
    disp('Select a MSK file to use.')
    [fn_in,fp_in] = uigetfile('*.msk','Mask','INPUT','MultiSelect','off');
    if isnumeric(fn_in)
        warning('No file selected. Stopping.')
        return
    end
    disp('Loading MSK...');
    msk = xff([fp_in fn_in]);
    mask_filename = fn_in;
else
    disp('Loading MSK...');
    msk = xff(p.MSK_FILE);
    mask_filename = p.MSK_FILE;
end

%mask_filename
if any(mask_filename == filesep)
    mask_filename = mask_filename(find(mask_filename==filesep,1,'last')+1:end);
end
% % if any(mask_filename == '.')
% %     mask_filename = mask_filename(1:find(mask_filename=='.',1,'last')-1);
% % end

%list vmp
list = dir([vmpFol '*.vmp']);

num_vmp = length(list);
for f = 1:num_vmp
    name = list(f).name;
    vmp = xff([vmpFol name]);
    
    num_map = vmp.NrOfMaps;
    
    if isfield(msk, 'Mask')
        %msk type file
        for m = 1:num_map
            vmp.Map(m).VMPData( ~msk.Mask ) = nan;
        end
    elseif isfield(msk, 'VMRData')
        vmp.MaskWithVMR(msk, 10);
    else
        error('Unsupported mask file type (supports msk and vmr)')
    end
    
    %new voxel counts for bonf
    for m = 1:num_map
        vmp.Map(m).BonferroniValue = sum(vmp.Map(m).VMPData(:) ~= 0);
    end
    
    name_new = strrep(name,'.vmp',sprintf('_MSK-%s.vmp',mask_filename));
    vmp.SaveAs([vmpFol_out name_new]);
    
    vmp.ClearObject;
end

msk.ClearObject;

disp Done.