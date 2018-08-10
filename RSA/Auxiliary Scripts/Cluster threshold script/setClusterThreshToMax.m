function setClusterThreshToMax

%% select vmp
[FileName,PathName,FilterIndex] = uigetfile('*.vmp');
if ~FilterIndex
    error('Must select a VMP.')
end
vmpPath = [PathName FileName];

%load vmp
vmp = xff(vmpPath);

%find max k value
kMax = 0;
for m = 1:vmp.NrOfMaps
    k = vmp.Map(m).ClusterSize;
    if k > kMax
        kMax = k;
    end
end

%tell us what the max k was
fprintf('Setting all k values to %g...\n',kMax);

%set k values
for m = 1:vmp.NrOfMaps
    vmp.Map(m).ClusterSize = kMax;
end

%save
newPath = [vmpPath(1:(find(vmpPath=='.',1,'last')-1)) '_MaxThresh.vmp'];
vmp.SaveAs(newPath);
disp('done.')