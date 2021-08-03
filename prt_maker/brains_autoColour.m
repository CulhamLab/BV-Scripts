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
colours=[255 255 255;225 225 225;155 155 155;120 120 120;80 80 80;255 220 220;255 155 155;255 100 100;255 0 0;200 0 0;255 193 230;255 129 231;255 35 213;208 0 168;146 0 118;240 215 255;221 165 255;199 109 255;177 51 255;121 0 196;196 193 255;162 157 255;116 109 255;42 31 255;9 0 188;193 239 255;141 225 255;91 212 255;0 187 254;0 136 184;193 255 239;141 255 225;71 255 207;0 216 159;0 150 111;194 254 197;151 253 156;90 252 98;4 208 14;3 135 9;254 254 194;252 252 104;236 231 5;200 195 4;139 136 3;254 222 190;253 192 131;252 165 78;244 124 4;193 98 3];
colours=colours(end:-1:1,:);
numColour = size(colours,1);
if counter < 2
    for jj=1:cond_no
        disp(sprintf('\n'))
        disp(['Pick a colour for condition ' char(cond_name(jj))])
        %colour_pick=color_select;
        colourInd = mod(jj-1,numColour)+1;
        colortypes(jj,:)=colours(colourInd,:);%colour_pick;
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

