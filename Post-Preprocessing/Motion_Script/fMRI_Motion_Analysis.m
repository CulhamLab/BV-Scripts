%fMRI_Motion_Analysis(uniqueSearchString)
%
%PURPOSE:
%This script searching for SDMs in the folder "Input(sdm)", order files
%alphanumerically, asks which file (run) is the alignment run, and reads in
%relevant data from the SDMs. This data is used to calculate various motion
%parameters which are output in figures and text as well was saved to mat
%data files.
%
%REQUIRES:
%a) NeuroElf toolBox (see http://neuroelf.net/)
%
%Inputs:
%a) a unqiue string to search for which identifies the participant/session (e.g., SUB02 or AZ21)
%b) SDM files for each run
%
function fMRI_Motion_Analysis(uniqueSearchString)
% clear all, close all
% nargin = 1;
% uniqueSearchString = 'SUB01';

%% require input
if nargin<1 | ~ischar(uniqueSearchString)
    error([mfilename '(uniqueSearchString)'])
end

%% create folders (if not present)
%create input folder if it doesn't exist  to clarify where inputs should go
inFolName = 'Input(sdm)';
if ~exist('Input(sdm)','dir')
    mkdir(inFolName)
end

%create output folder
outmatFolName = 'Output(mat)';
if ~exist('Output(mat)','dir')
    mkdir(outmatFolName)
end

%create output folder
outfigFolName = 'Output(png)';
if ~exist('Output(png)','dir')
    mkdir(outfigFolName)
end

%% find desired sdms
%list sdm
list = dir([pwd filesep inFolName filesep '*.sdm']);

%check filename of each, remove those that do not contain uniqueSearchString
for i = length(list):-1:1
    if ~length(strfind(list(i).name,uniqueSearchString))
        list(i) = [];
    end
end
numSDM = length(list);

%are there are least 1 runs?
if numSDM<1
    error(sprintf('Did not find any SDMs for the search string "%s".',uniqueSearchString))
end

%% confirm that selection/order is okay and ask which run is the ALIGNMENT run

%confirm order/selecting
while 1
    %display runs
    fprintf('\nFound the following SDMs for the search string "%s"...\n',uniqueSearchString)
    for i = 1:numSDM
        fprintf('RUN%02d: %s\n',i,list(i).name)
    end
    
    %ask if the order is correct?
    try
        strIN = lower(input('Is the selection and order of these SDM files correct? (y/n): ','s'));
    catch
        strIN = '';
    end
    if strcmp(strIN,'y') | strcmp(strIN,'yes')
        break;
    elseif strcmp(strIN,'n') | strcmp(strIN,'no')
        errstr = sprintf('SMD files must be placed directly in the folder "%s". These files must NOT be within subfolders. Files which contain the input "uniqueSearchString" are selected. Files are ordered alphanumerically.',inFolName);
        error(errstr)
    else
       warning('Incorrect reponse format.')
    end
end

%select alignment run
while 1
    msgStr = sprintf('\nThe alignment run is the closest run following the anatomical scan.\nWhich run is the alignment run? (1-%d): ',numSDM);
    try
    	intIN = input(msgStr);
    catch
        intIN = [];
    end
    
    if ~isnumeric(intIN) | length(intIN)~=1
        warning('Incorrect reponse format.')
    elseif intIN>numSDM
        warning('Input value exceed the number of SDMs found.')
    else
        alignRunNum = intIN;
        fprintf('Alignment run selected: RUN%02d (%s)\n',alignRunNum,list(alignRunNum).name)
        break
    end
end

%% read in all SDMs
%initialize cell arrays
runData.x = {};
runData.y = {};
runData.z = {};
runData.rx = {};
runData.ry = {};
runData.rz = {};

%read in data to fill cell arrays
fprintf('\nReading in data from all SDMs...\n');
for i = 1:numSDM
    try
        %load sdm
        sdm = xff([pwd filesep inFolName filesep list(i).name]);

        %fill cell arrays
        for ii = 1:length(sdm.PredictorNames)
            switch sdm.PredictorNames{ii}
                case 'Translation BV-X [mm]'
                    runData.x{i} = sdm.SDMMatrix(:,ii);
                case 'Translation BV-Y [mm]'
                    runData.y{i} = sdm.SDMMatrix(:,ii);
                case 'Translation BV-Z [mm]'
                    runData.z{i} = sdm.SDMMatrix(:,ii);
                case 'Rotation BV-X [deg]'
                    runData.rx{i} = sdm.SDMMatrix(:,ii);
                case 'Rotation BV-Y [deg]'
                    runData.ry{i} = sdm.SDMMatrix(:,ii);
                case 'Rotation BV-Z [deg]'
                    runData.rz{i} = sdm.SDMMatrix(:,ii);
            end
        end
        
        %success!
        fprintf('Read run %d/%d.\n',i,numSDM)
        
    catch err
        errstr = sprintf('An error occured during the reading of RUN%02d (%s): %s',i,list(i).name,err.message);
        error(errstr)
    end
end

%% process
%init new struct
sessionData.x = [];
sessionData.y = [];
sessionData.z = [];
sessionData.rx = [];
sessionData.ry = [];
sessionData.rz = [];
sessionData.diffPosition = [];
sessionData.diffPositionAbs = [];
sessionData.diffRotation = [];

%concat all runs
for run = 1:numSDM
    %note which volume is the first of this run
    firstVol(run) = length(sessionData.x)+1;
    
    %concat
    sessionData.x = [sessionData.x; runData.x{run}];
    sessionData.y = [sessionData.y; runData.y{run}];
    sessionData.z = [sessionData.z; runData.z{run}];
    sessionData.rx = [sessionData.rx; runData.rx{run}];
    sessionData.ry = [sessionData.ry; runData.ry{run}];
    sessionData.rz = [sessionData.rz; runData.rz{run}];
end

%calculate XYZ distance from initial (0,0,0)
numVol = length(sessionData.x);
for vol = 1:numVol
    sessionData.diffPosition(vol,1) = pdist([0 0 0; sessionData.x(vol) sessionData.y(vol) sessionData.z(vol)],'euclidean'); %not absolute
    sessionData.diffPositionAbs(vol,1) = abs(sessionData.diffPosition(vol)); %absolute
    sessionData.diffRotation(vol,1) = sum(abs([sessionData.rx(vol) sessionData.ry(vol) sessionData.rz(vol)])); %always absolute
end


