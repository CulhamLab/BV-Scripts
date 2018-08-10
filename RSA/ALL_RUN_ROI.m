function run_searchlight

%% param
SCRIPTS_TO_IGNORE = {'ALL_STEP0_PARAMETERS.m'};

%% create list of scripts
scripts = cell(0);

%BOTH
list = dir('BOTH_*.m');
for i = 1:length(list)
    name = list(i).name;
    if ~any(cellfun(@(x) strcmp(x,name),SCRIPTS_TO_IGNORE))
        scripts{end+1} = name;
    end
end

%ROI
list = dir('ROI_*.m');
for i = 1:length(list)
    name = list(i).name;
    if ~any(cellfun(@(x) strcmp(x,name),SCRIPTS_TO_IGNORE))
        scripts{end+1} = name;
    end
end

%% ask which to start with
for i = 1:length(scripts)
    fprintf('[%d] %s\n',i,scripts{i})
end
str = input('Which step to start at (or exit):','s');
if strcmp(lower(str),'exit'), return, end
num = str2num(str);
if length(num)~=1
    error('Unknown step. Please enter a single number only.')
end
if num>length(scripts) | num<1
    error('Number invalid.')
end

disp('Running...')
for i = num:length(scripts)
    fprintf('[%d] %s\n',i,scripts{i})
end
disp('If an error is encountered, further scripts will not be run')

for i = num:length(scripts)
    fprintf('[%d] %s\n',i,scripts{i})
    eval(scripts{i}(1:end-2))
end

