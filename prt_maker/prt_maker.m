close all;clear all
clc

%Version 1.1 - added extra colours

% ATTENTION: files needed for this program:
% 
% Setup_prt.m (this one)
% color_select.m
% brains.m
% color_swatch_new.jpg

% define all variables that will be used outside of this m-file.  There are
% also prt_fname## files being declared below as global.

global data
global cond_name
global expt_name
global txt
global counter
global colortypes
global data_type



% Ask user for name of experiment to be stored in PRT.
expt_name = input('Input name of experiment? = ','s');
disp(sprintf('\n'));
disp('***********************************************');
disp('***     Before you start make sure your     ***');
disp('***        EXCEL file is saved as an        ***');
disp('***         EXCEL 5.0 WORKSHEET !!!         ***');                  
disp('***                                         ***');
disp('*** Select your file from the dialogue box  ***');
disp('***********************************************');
disp(sprintf('\n'))

% Prompt user for EXCEL file to load.
[fname,pname] = uigetfile('*.xls','Choose an EXCEL worksheet file');        %uigetfile will open dialogue box entitled 'Choose and EXCEL 5.0 Worksheet file and displays only XLS files
xl_fname = [pname,fname];                                                   % concatinates filename and path into xl_fname.

% Read in EXCEL file.
% Parse read data into numerical entries (data) and strings (conditions) 
[data,txt] = xlsread(xl_fname);
data = data(:,1:3);
titles=txt(1,:);
titles(1:4)=[];                     % eliminates the first 4 entries (Condition, state, BV start volume, BV stop volume) leaving the names of the different runs
txt(1,:)=[];

cond_name=txt(:,1);


% Determine is data is presented in terms of volumes or time

data_type=input('Is your data presented in Volumes (v) or Interval times (t), (v/t)   ','s');

if (strcmp(data_type,'v')== 1) || (strcmp(data_type,'V')== 1) || (strcmp(data_type,'v ')== 1) || (strcmp(data_type,'V ')== 1)
    data_type='Volumes';
elseif (strcmp(data_type,'t')== 1) || (strcmp(data_type,'t ')== 1) || (strcmp(data_type,'T ')== 1) || (strcmp(data_type,'T')== 1)
    data_type='msec';
else
    % this restarts the program
    prt_maker
end

%compare number of runs in excel sheet and if its not the same tell them to
%check excel sheet
[xdim,ydim]=size(txt);
check=input(['There are ',int2str(ydim-4),' order(s) in your Protocol, is this correct????  (y/n)   '],'s');



if (strcmp(check,'y')== 1) || (strcmp(check,'yes')== 1) || (strcmp(check,'y ')== 1) ||(strcmp(check,'yes ')== 1) || (strcmp(check,'YES')==1) || (strcmp(check,'Yes')==1) ||(strcmp(check,'Y')==1)
    no_runs=(ydim-4);
else
    disp('You need to re-check your excel file before continuing.')
    % this restarts the program
    prt_maker
end

% Prompt user for PRT file to save.

[fname,pname] = uiputfile('*.prt','Choose a name for PRT file');      % combines filename with path name into one string
prt_fname = [pname,fname];


for i=1:no_runs
    eval(sprintf('global prt_fname_%d;',i));
    if ~strcmp(prt_fname(1,end-3:end),'.prt')           %checks to see if the .prt extension has been added to the string but looking at the last 3 chars, if not, adds it in.
       prt_fname = [prt_fname, '.prt'];
    end
    a=[prt_fname(1,1:end-4),'_',char(titles(i)),prt_fname(1,end-3:end)];
    eval(sprintf('prt_fname_%d=a;',i));
 
end

counter=1;
for i=1:no_runs
   brains
   counter=counter+1;
end

disp(['You can now find your ', int2str(no_runs), ' PRT files in ',pname]);
disp(sprintf('\n'));
disp('Thank you, come again.');






