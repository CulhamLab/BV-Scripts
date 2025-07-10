%% Parameters

directory_search = "D:\Sofia\RSA\RSA_Inputs\Run_Files\";    % also searches subfolders
vtc_search_term = "*_bold_SCCTBL_3DMCTS_MNI_THPGLMF3c.vtc"; % allows wildcards (*)
volume = 1;                                                 % VTC volume to convert to VMR (usually 1 = first volume)


%% Prep

% handle / and \
directory_search = directory_search.replace("/",filesep).replace("\",filesep);

% directory must end with file separator
if ~directory_search.endsWith(filesep)
    directory_search = directory_search + filesep;
end

% find VTCs
list = dir(fullfile(directory_search, "**", vtc_search_term));

% count VTCs
number_files = length(list);

% stop if no VTCs
if ~number_files
    error("No VTCs were found in...\n  Directory:\t%s\n  Search Term:\t%s\n", directory_search, vtc_search_term)
end


%% Run

for fid = 1:number_files
    fn_vmr = [list(fid).name '.vmr'];
    fprintf("Processing VTC %d of %d...\n  Directory:\t%s\n  VTC:\t\t%s\n  VMR:\t\t%s\n", fid, number_files, list(fid).folder, list(fid).name, fn_vmr);
    vtc_to_vmr([list(fid).folder filesep list(fid).name], [list(fid).folder filesep fn_vmr], volume);
end


%% Done
disp Done!