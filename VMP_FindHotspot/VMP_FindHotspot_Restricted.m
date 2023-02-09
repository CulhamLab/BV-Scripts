% VMP_FindHotspot_Restricted(filepath,x,y,z,radius)
%
% Displays the location and value of the hotspots (min and max) in each map
% of each VMP. Search is restricted to specified radius around specified
% location.
%
% filepath - path to VMP
% x/y/z - MNI coordinates
% radius - in mm
%
function VMP_FindHotspot_Restricted(filepath,x,y,z,radius)

filepath = 'all_ttest.vmp';
x = -58;
y = -10;
z = -21;
radius = 10;

target = 128 - [y z x]

vmp = xff(filepath);

for m = vmp.NrOfMaps
    fprintf('Checking map %d of %d: %s\n', m, vmp.NrOfMaps, vmp.Map(m).Name);

    map = nan(256,256,256,'single');
    map(vmp.XStart:vmp.XEnd-1, vmp.YStart:vmp.YEnd-1, vmp.ZStart:vmp.ZEnd-1) = imresize3(vmp.Map(m).VMPData, vmp.Resolution);
    
    
end

vmp.ClearObject;
disp Done!