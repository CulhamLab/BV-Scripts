function run_all_cluster_estimates

% select and read an excel file
[FileName,PathName,FilterIndex] = uigetfile('*.xls*');
if ~FilterIndex
    error('Must select an excel file.')
end
xlsFilepath = [PathName FileName];
[~,~,xls] = xlsread(xlsFilepath);

%prep
numTests = size(xls,1)-3;

% %constants/params
% tails = '2of2';
% numIterations = 1000;
% FWHM = 1; %1 is BV default
% useDataDist = false; %false is BV constant

%folder path
folpath = xls{2,1};
if folpath(end)~=filesep
    folpath = [folpath filesep];
end

%loop through each row in xls
for test = 1:numTests
    %read
    row = test+3;
    vmpFilename = xls{row,1};
    mapNum = xls{row,2};
    critT = xls{row,3};
    vmpFilepath = [folpath vmpFilename];
    tails = xls{row,6};
    numIterations = xls{row,7};
    FWHM = xls{row,8};
    useDataDist = xls{row,9};
    
    %continue if there is no vmpFilename
    if ~length(vmpFilename)
        continue
    end
    
    %check FWHM
    if ischar(FWHM)
        switch lower(FWHM)
            case 'nan'
                FWHM = NaN;
            otherwise
                error('FWHM invalid!')
        end
    end
    
    %check useDataDist (if it's string, set it correctly)
    if ischar(useDataDist)
        switch lower(useDataDist)
            case 'true'
                useDataDist = true;
            case 'false'
                useDataDist = false;
            otherwise
                error('useDataDist must be true or false!')
        end
    end
    
    %estimate cluster threshold
    [k] = calc_cluster_thresh(vmpFilepath,mapNum,critT,tails,numIterations,FWHM,useDataDist);
    
    %add k to excel
    xls{row,4} = k;
    
% %     %set cluster thresh in vmp
% %     clear vmp
% %     vmp = xff(vmpFilepath);
% %     vmp.Map(mapNum).ClusterSize = k;
% %     vmp.Map(mapNum).EnableClusterCheck = 1;
% %     vmp.SaveAs(vmpFilepath);
% %     clear vmp
% %     close all
    
end

%write updated excel
xlswrite(xlsFilepath,xls);