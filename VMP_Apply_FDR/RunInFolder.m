%% Settings

%folder to run
fol = pwd;

%FDR q
q = 0.05;

%FDR formula
%0: c(V)=1
%1: c(V)=ln(V)+E
formula = 0;

%% Run...

%ensure folder ends with file separator
if fol(end) ~= filesep
    fol(end+1) = filesep;
end

%find all VMP in this folder and subfolders
list = dir(fullfile(fol, '**', '*.vmp'));

%remove *_FDR.vmp from selection
list = list(cellfun(@(x) ~contains(x, '_FDR.vmp'), {list.name}));

%run each
number_files = length(list);
for fid = 1:number_files
    fprintf('Processing file %d of %d: %s\n', fid, number_files, list(fid).name);
    
    %load
    fp_in = [list(fid).folder filesep list(fid).name];
    vmp = xff(fp_in);
    
    %select all maps
    map_ind_to_do = 1:vmp.NrOfMaps;
    
    %apply FDR thresholding
    VMP_Apply_FDR(vmp, q, map_ind_to_do, formula);
    
    %save
    fp_out = [fp_in(1:end-4) '_FDR.vmp'];
    vmp.SaveAs(fp_out);
    
    %clear
    vmp.ClearObject;
    clear vmp
    
end

disp Done.
