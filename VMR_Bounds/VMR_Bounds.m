%Calculates and displays the XYZ bounds of all VMR in the target folder

%% Settings

%folder to run
fol = pwd;

%VMR intensity threshold
vmr_thresh = 10;

%% Run

%ensure folder ends with file separator
if fol(end) ~= filesep
    fol(end+1) = filesep;
end

%find all VMP in this folder and subfolders
list = dir(fullfile(fol, '**', '*.vmr'));


if isempty(list)
    warning('No VMR files found in this folder')
    return
else
    number_files = length(list);
    
    fprintf('VMR intensity threshold is set to >=%g\n', vmr_thresh);
    
    for fid = 1:number_files
        fprintf('Processing %d of %d: %s\n', fid, number_files, list(fid).name);
        
        vmr = xff([list(fid).folder filesep list(fid).name]);
        
        for dim = 1:3
            d = [1:dim-1 dim+1:3];
            val = any(any(vmr.VMRData >= vmr_thresh,d(1)),d(2));
            bbox(dim,1) = find(val,1,'first');
            bbox(dim,2) = find(val,1,'last');
        end
        
        %clear vmr
        vmr.ClearObject;
        
        %set to BV order
        bbox = bbox([3 1 2],:);
        
        %display
        fprintf('\tBounding box in BV coordinates:\n');
        fprintf('\t\tX: % 3d to % 3d\n', bbox(1,:));
        fprintf('\t\tY: % 3d to % 3d\n', bbox(2,:));
        fprintf('\t\tZ: % 3d to % 3d\n', bbox(3,:));
        
    end
end

disp Done.