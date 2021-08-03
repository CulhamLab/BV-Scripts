%Version 1.1

global data
global cond_name
global expt_name
global txt
global counter
global colortypes
global data_type

% gets a list of all the condition names for a the current run (determined
% by the value of the counter)

conditions=txt(:,4+counter);

% truncates empty cells at the end of cond_name
jj=0;
while jj==0
    xx=size(cond_name,1);
    a=strcmp(cond_name(xx),'');
    if a==1 
        cond_name(xx)=[] ;
    else
        jj=1;
    end
end

% Determine number of trial types and number of conditions.

cond_no=size(cond_name,1);

% Give user some feedback.
disp(sprintf('\n'))
if counter < 2
    eval(sprintf('disp(''There are %d different conditions'');',cond_no));
end


% Determine the number of occurance per conditions.  Conditions are
% numbered according to the order presented in the Excel file.

ctt=zeros(cond_no,2);
for tt=1:cond_no
    for i=1:size(conditions,1)
       ctt(tt,1)=tt;
       ctt(tt,2)=ctt(tt,2)+strcmp(cond_name(tt),conditions(i));
    end
end



% Loop to prompt user for name and colour of each condition.  Also, selects that 
% colour from matrix of colour indices.
%colortypes=zeros(length(cond_name),3);
if counter < 2
    for jj=1:cond_no
        disp(sprintf('\n'))
        disp(['Pick a colour for condition ' char(cond_name(jj))])
        colour_pick=color_select;
        colortypes(jj,:)=colour_pick;
        close
    end
end

% Open PRT for writing.
eval(sprintf('b=prt_fname_%d;',counter));

fid = fopen(b,'w');
fprintf(fid,'\n');
fprintf(fid,'FileVersion:        2\n');
fprintf(fid,'\n');
fprintf(fid,'ResolutionOfTime:   %s\n',data_type);
fprintf(fid,'\n');
fprintf(fid,'Experiment:         %s\n',expt_name);
fprintf(fid,'\n');
fprintf(fid,'BackgroundColor:    0 0 0\n');
fprintf(fid,'TextColor:          255 255 255\n');
fprintf(fid,'TimeCourseColor:    255 255 255\n');
fprintf(fid,'TimeCourseThick:    3\n');
fprintf(fid,'ReferenceFuncColor: 0 0 80\n');
fprintf(fid,'ReferenceFuncThick: 3\n');
fprintf(fid,'\n');
fprintf(fid,'NrOfConditions:  %s\n',num2str(cond_no));
fprintf(fid,'\n');

for jj=1:cond_no
    fprintf(fid,'%s\n',char(cond_name(jj)));
    fprintf(fid,'%d\n',ctt(jj,2));
    for kk=1:(length(conditions))
        ch=strcmp(cond_name(jj),conditions(kk));
        if ch==1 
            fprintf(fid,'%d %d\n',data(kk,2),data(kk,3));
        end
    end
    fprintf(fid,'Color:  %d %d %d\n',colortypes(jj,1),colortypes(jj,2),colortypes(jj,3));
    fprintf(fid,'\n');
end

fclose all;

