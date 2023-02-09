function VMP_FindHotspot(filepath)

if exist('filepath','var')
    if iscell(filepath)
        filepaths = filepath;
    else
        filepaths = {filepath};
    end
else
    list = dir('*.vmp');
    filepaths = arrayfun(@(x) [x.folder filesep x.name], list, 'UniformOutput', false);
end

if isempty(filepaths)
    error('No files detected')
end

%%
nfilepaths = length(filepaths);
for f = 1:nfilepaths
    fprintf('Processing VMP %d of %d: %s\n', f, nfilepaths, filepaths{f});

    vmp = xff(filepaths{f});

    for m = 1:vmp.NrOfMaps
        fprintf('\tChecking map %d of %d: %s\n', m, vmp.NrOfMaps, vmp.Map(m).Name);
        
        for type = 1:2
            if type == 1
                func = @max;
            else
                func = @min;
            end

            [value,ind] = func(vmp.Map(m).VMPData(:));
            [x,y,z] = ind2sub(size(vmp.Map(m).VMPData), ind);
    
            %add XYZStarts (these are in save coord, not system coord)
            x = (x * vmp.Resolution) + vmp.XStart - 1;
            y = (y * vmp.Resolution) + vmp.YStart - 1;
            z = (z * vmp.Resolution) + vmp.ZStart - 1;
    
            %reorder
            xSyst = z;
            ySyst = x;
            zSyst = y;
    
            %MNI
            xMNI = 128 - xSyst;
            yMNI = 128 - ySyst;
            zMNI = 128 - zSyst;
    
            fprintf('\t\t%g @ (%d,%d,%d)\n', value, xMNI, yMNI, zMNI);
        end
    end

    vmp.ClearObject;
end

disp Done.