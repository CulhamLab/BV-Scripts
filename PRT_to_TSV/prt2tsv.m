% prt2tsv(prt_filepath, tsv_filepath, TR_sec)
% 
% Reads a PRT, converts the contents to TSV format, and writes the result to a new TSV file.
%
% INPUTS:
%   prt_filepath    char        required        Filepath to the PRT to use
%
%   tsv_filepath    char/[]     default=[]      Filepath to the TSV to write. Defaults to
%                                               the same location and naming as PRT.
%
%   TR_sec          numeric     conditional*    If the PRT is in volumes, then the volume
%                                               duration (TR) must be specified in seconds.
%
function prt2tsv(prt_filepath, tsv_filepath, TR_sec)

%% Check Inputs
if ~exist('prt_filepath', 'var') || isempty(prt_filepath) || ~ischar(prt_filepath)
    error('Missing input: prt_filepath')
end

if ~exist('tsv_filepath', 'var') || isempty(tsv_filepath) || ~ischar(tsv_filepath)
    tsv_filepath = [prt_filepath(1:end-3) 'tsv'];
end

%% Check Files/Paths
if ~exist(prt_filepath, 'file')
    error('PRT does not exist: %s', prt_filepath);
end

if exist(tsv_filepath, 'file')
    error('TSV already exists: %s', tsv_filepath);
end

%% Load PRT

prt = xff(prt_filepath);

%% Convert To Seconds

%create conversion function
switch lower(prt.ResolutionOfTime)
    case 'volumes'
        %has TR_sec?
        if ~exist('TR_sec', 'var') || isempty(TR_sec) || ~isnumeric(TR_sec)
            error('PRT is in volumes but TR_sec was not provided')
        end
        
        %convert function
        convert = @(x) (x-[1 0])*TR_sec;
        
    case 'msec'
        %convert function
        convert = @(x) x/1000;
        
    otherwise
        error('Unsupported ResolutionOfTime: %s', prt.ResolutionOfTime);
end

%apply conversion function
for c = 1:prt.NrOfConditions
    prt.Cond(c).OnOffsets_Sec = convert(prt.Cond(c).OnOffsets);
end

%% Create TSV Table

%initialize table
tbl = table('Size',[0, 3],'VariableTypes',{'double' 'double' 'string'},'VariableNames',{'onset' 'duration' 'trial_type'});

%add events
for c = 1:prt.NrOfConditions
    name = strrep(prt.Cond(c).ConditionName{1}, ' ', '_');
    
    for e = 1:prt.Cond(c).NrOfOnOffsets
        onset = prt.Cond(c).OnOffsets_Sec(e,1);
        dur = range(prt.Cond(c).OnOffsets_Sec(e,1:2));
        tbl(end+1,:) = {onset dur name};
    end
end

%sort events by onset
[~,order] = sort(tbl.onset, 'ascend');
tbl = tbl(order,:);

%% Write TSV

fprintf('Writing: %s\n', tsv_filepath);
writetable(tbl, tsv_filepath, 'FileType', 'text' ,'Delimiter', '\t');

%% Done
disp Done.

