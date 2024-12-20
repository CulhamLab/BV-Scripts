%Uses NeuroElf to set PRT links in VTC files
%Sets prt link to "sub-##_ses-##_task-TASKNAME_run-##.prt"
%   -uses sub/ses/task/run if available, if none are available then it will
%    default to the name of the VTC
%   -can be changed on line 40
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
    [~,fn,~] = fileparts(list(fid).name);
    parts = strsplit(fn, '_');
    info = struct;
    for part = parts
        if contains(part, '-')
            split = strsplit(part{1},'-');
            name = split{1};
            value = split{2};
            if contains(name, {'sub' 'ses' 'task' 'run'})
                fprintf('\t%s:\t%s\n', name, value);
                info = setfield(info, name, value);
            end
        end
    end
    
    %generate PRT name
    prt = '';
    for f = {'sub' 'ses' 'task' 'run'}
        f=f{1};
        if isfield(info, f)
            prt = [prt sprintf('%s-%s_', f, getfield(info, f))];
        end
    end
    if ~isempty(prt)
        prt(end:end+3) = '.prt';
    else
        %default name
        [~,fn,~] = fileparts(list(fid).name);
        prt = [fn '.prt'];
    end
    fprintf('\tPRT:\t%s\n', prt);
    
    %load vtc
    filepath = [list(fid).folder filesep list(fid).name];
    vtc = xff(filepath);
    
    %display prior
    if iscell(vtc.NameOfLinkedPRT)
        if isempty(vtc.NameOfLinkedPRT)
            prior_name = '';
        else
            prior_name = vtc.NameOfLinkedPRT{1};
        end
    else
        prior_name = vtc.NameOfLinkedPRT;
    end
    if isempty(prior_name)
        prior_name = 'NONE';
    elseif ~ischar(prior_name)
        prior_name = 'UNKNOWN';
    end
    fprintf('\tPrior:\t%s\n', prior_name);
    
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
