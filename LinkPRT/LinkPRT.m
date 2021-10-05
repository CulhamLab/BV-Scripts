%Uses NeuroElf to set PRT links in VTC files
%Requires the "sub-##_ses-##_task-TASKNAME_run-##" notation in VTC filenames
%Sets prt link to "sub-##_ses-##_task-TASKNAME_run-##.prt" (make changes on line 29)
function LinkPRT

%% parameters
root = 'D:\Culham Lab\CB_ActiveLearn\MAIN\BIDS';
vtc_search = '*.vtc';

%% check param
if root(end) ~= filesep
    root(end+1) = filesep;
end

%% find files
list = dir(fullfile(root, '**', vtc_search));
number_files = length(list);

%% process files
for fid = 1:number_files
    fprintf('Processing %d of %d:\n\tFolder:\t%s\n\tFile:\t%s\n', fid, number_files, list(fid).folder, list(fid).name);
    
    %parse sub 
    info = regexp(list(fid).name,'(?<sub>sub-\d\d)_(?<ses>ses-\d\d)_(?<task>task-\w*)_(?<run>run-\d\d)','names');
    fprintf('\tsub:\t%s\n\tses:\t%s\n\ttask:\t%s\n\trun:\t%s\n', info.sub, info.ses, info.task, info.run);
    
    %generate PRT name
    prt = sprintf('%s_%s_%s_%s.prt', info.sub, info.ses, info.task, info.run);
    fprintf('\tPRT:\t%s\n', prt);
    
    %load vtc
    filepath = [list(fid).folder filesep list(fid).name];
    vtc = xff(filepath);
    
    %display prior
    fprintf('\tPrior:\t%s\n', vtc.NameOfLinkedPRT);
    
    %is prt already linked?
    if strcmp(vtc.NameOfLinkedPRT, prt)
        fprintf('\tAlready linked. Skipping!\n');
    else
        fprintf('\tAdding link and saving...\n');
        vtc.NameOfLinkedPRT = prt;
        vtc.Save;
    end
    
    %cleanup
    vtc.ClearObject;
end

disp Done.
