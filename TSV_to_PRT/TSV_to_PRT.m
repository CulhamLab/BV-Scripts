function TSV_to_PRT(folder, conds, experiment_name)

%% Check Inputs
if ~exist('folder', 'var') || isempty(folder) || ~ischar(folder)
    folder = [pwd filesep];
elseif ~exist(folder, 'dir')
    error('Folder does not exist: %s', folder);
elseif folder(end) ~= filesep
    folder(end+1) = filesep;
end

if ~exist('conds', 'var') || isempty(conds)
    auto_cond = true;
else
    auto_cond = false;
    number_cond = size(conds,1);
end

if ~exist('experiment_name', 'var') || isempty(experiment_name) || ~ischar(experiment_name)
    experiment_name = 'Unspecified';
end
    

%%
list = dir([folder '*.tsv']);
number_files = length(list);

for fid = 1:number_files
    fp = [list(fid).folder filesep list(fid).name];
    fprintf('Processing %d of %d: %s\n', fid, number_files, fp);
    
    tbl = readtable(fp, 'FileType', 'text');
    
    if auto_cond
        conds = unique(tbl.trial_type);
        number_cond = size(conds,1);
        colours = round(jet(number_cond) * 255);
        conds(:,2) = arrayfun(@(x) colours(x,:), 1:number_cond, 'UniformOutput', false);
    end
    
    prt = xff('prt');
    prt.ResolutionOfTime = 'msec';
    prt.Experiment = experiment_name;
    
    for c = 1:number_cond
        ind = find(strcmp(tbl.trial_type, conds{c,1}));
        number_events = length(ind);
        
        on = tbl.onset(ind);
        dur = tbl.duration(ind);
        
        onoff = [on on] + [zeros(number_events,1) dur];
        onoff = onoff * 1000; %sec to msec
        
        prt.Cond(c).ConditionName = conds(c,1);
        prt.Cond(c).NrOfOnOffsets = number_events;
        prt.Cond(c).OnOffsets = onoff;
        prt.Cond(c).Color = conds{c,2};
    end
    
    fp_out = [fp(1:end-3) 'prt'];
    prt.SaveAs(fp_out);
    prt.ClearObject;
    
end

disp Done!