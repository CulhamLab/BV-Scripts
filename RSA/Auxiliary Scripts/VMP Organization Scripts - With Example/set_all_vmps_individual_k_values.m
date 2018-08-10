%sets both the lower t threshold as well as the k threshold

function set_all_vmps_individual_k_values

%% select and read an excel file
[FileName,PathName,FilterIndex] = uigetfile('*.xls*');
if ~FilterIndex
    error('Must select an excel file.')
end
[~,~,xls] = xlsread([PathName FileName]);

%% extra info from excel
vmpPath = xls{2,1};
if vmpPath(end) ~= filesep
    vmpPath = [vmpPath filesep];
end
%remove extra rows
for row = size(xls,1):-1:4
    if ~length(xls{row,1}) | ~ischar(xls{row,1})
        xls(row,:) = [];
    end
end
%keep only useful info
xls = xls(4:end,1:4);
numMaps = size(xls,1);
if ~numMaps
    error('Excel must have at least 1 map to change.')
end

%% make changes
for mid = 1:numMaps
    filename = xls{mid,1};
    filepath = [vmpPath filename];
    mapNum = xls{mid,2};
    lowTThresh = xls{mid,3};
    newClusterVal = xls{mid,4};
    
    fprintf('Setting map %d in "%s": t=%d, k=%d\n',mapNum,filename,lowTThresh,newClusterVal)
    
    %open
    clear vmp
    vmp = xff(filepath);
    
    %set
    vmp.Map(mapNum).LowerThreshold = lowTThresh;
    vmp.Map(mapNum).ClusterSize = newClusterVal;
    vmp.Map(mapNum).EnableClusterCheck = 1;
    
    %save
    vmp.SaveAs(filepath);
    clear vmp
    
    %pause 2 seconds prevent read/write issues
    pause(2);
end

disp('Done.')