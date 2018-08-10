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
    p.VOI_FILE = fn_in;
else
    disp('Loading MSK...');
    msk = xff(p.MSK_FILE);
end

%list vmp
list = dir([vmpFol '*.vmp']);

num_vmp = length(list);
for f = 1:num_vmp
    name = list(f).name;
    vmp = xff([vmpFol name]);
    
    num_map = vmp.NrOfMaps;
    for m = 1:num_map
        vmp.Map(m).VMPData( ~msk.Mask ) = nan;
    end
    
    name_new = strrep(name,'.vmp',sprintf('_MSK-%s.vmp',strrep(p.VOI_FILE,'.msk','')));
    vmp.SaveAs([vmpFol_out name_new]);
    
    vmp.ClearObject;
end

msk.ClearObject;

disp Done.