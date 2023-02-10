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

fprintf('Loading VMP: %s\n', filepath);
vmp = xff(filepath);

fprintf('Searching within %gmm of (%d,%d,%d)...\n', radius, x, y, z);
target = 128 - [y z x];
[ys,xs,zs] = meshgrid(1:256,1:256,1:256);
ds = sqrt((xs-target(1)).^2 + (ys-target(2)).^2 + (zs-target(3)).^2);
select = ds <= radius;

for m = 1:vmp.NrOfMaps
    fprintf('Checking map %d of %d: %s\n', m, vmp.NrOfMaps, vmp.Map(m).Name);

    map = nan(256,256,256,'double');
    map(vmp.XStart:vmp.XEnd-1, vmp.YStart:vmp.YEnd-1, vmp.ZStart:vmp.ZEnd-1) = imresize3(vmp.Map(m).VMPData, vmp.Resolution, 'method', 'nearest');
    map(~select) = nan;

    for type = 1:2
        if type == 1
                func = @nanmax;
                name = 'Max';
            else
                func = @nanmin;
                name = 'Min';
        end

        [value,ind] = func(map(:));
        [y,x,z] = ind2sub(size(map), ind);

        %reorder
        xSyst = z;
        ySyst = y;
        zSyst = x;

        %MNI
        xMNI = 128 - xSyst;
        yMNI = 128 - ySyst;
        zMNI = 128 - zSyst;

        fprintf('\t\t%s: %g @ (%d,%d,%d)\n', name, value, xMNI, yMNI, zMNI);
    end
    
end

vmp.ClearObject;
disp Done!