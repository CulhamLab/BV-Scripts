%this is just a copy of createSphereOrCubeVOIs_nov13

function script1_createVOI

%% Construct voi struct (error if neuroelf is not installed)
try
    voi = xff('voi');
catch 
    error('NeuroElf toolbox must be installed.')
end

%% Load input
[fn_in,fp_in] = uigetfile('*.xls*','INPUT EXCEL','INPUT','MultiSelect','off');
[~,~,xlsin] = xlsread([fp_in fn_in]);

%% Pre output fp
guessOutputName = fn_in(1:find(fn_in=='.',1,'last')-1);
[fn_out,fp_out] = uiputfile('*.voi','OUTPUT VOI',guessOutputName);

%% Check that input is good
if size(xlsin,1)<12 | size(xlsin,2)<5
    error('At least one VOI is required.')
end
rowParamNeeded = [1:8 10]; %don't need 9
if sum(cellfun(@(x) sum(isnan(x)),xlsin(rowParamNeeded,2)))
    error('All parameters except VTC filepath are required.')
end

%% Place params in struct
voi.ReferenceSpace = xlsin{1,2};
voi.OriginalVMRResolutionX = xlsin{2,2};
voi.OriginalVMRResolutionY = xlsin{3,2};
voi.OriginalVMRResolutionZ = xlsin{4,2};
voi.OriginalVMROffsetX = xlsin{5,2};
voi.OriginalVMROffsetY = xlsin{6,2};
voi.OriginalVMROffsetZ = xlsin{7,2};
voi.OriginalVMRFramingCubeDim = xlsin{8,2};
voi.FileVersion = xlsin{10,2};
voi.Convention = 1;
if ~isnan(xlsin{9,2})
    voi.NrOfVTCs = 1;
    voi.VTCList = xlsin{9,2};
else
    voi.NrOfVTCs = 0;
    voi.VTCList = cell(0,1);
end

%% Process each VOI
lastGoodRow = find(~cellfun(@(x) sum(isnan(x)),xlsin(:,1)),1,'last');

numVoiLikely = lastGoodRow-12+1;
voicolours = jet(numVoiLikely);
voicolours = round(voicolours * 255);

numVOI = 0;
for row = 12:lastGoodRow
    fprintf('\nProcessing row %g...\n',row)
    
    numVOI = numVOI+1;
    voi.NrOfVOIs = numVOI;
    fprintf('-ROI Num: %g\n',numVOI)
    
    radius = xlsin{row,5};
    if ~isnumeric(radius) | length(radius)~=1
        error('Radius format invalid.')
    end
    fprintf('-Radius(voxels): %g\n',radius)
    
    shape = lower(xlsin{row,6});
    if ~strcmp(shape,'sphere') & ~strcmp(shape,'cube')
        error('Shape is not defined (sphere or cube).')
    end
    fprintf('-Shape: %s\n',shape)
    
    name = xlsin{row,1};
%     name = sprintf('%s - radius%d - %s',name,radius,shape);
    voi.VOI(numVOI).Name = name;
    fprintf('-ROI Name: %s\n',name)
    
    centerXYZ = [xlsin{row,2:4}];
    if ~isnumeric(centerXYZ) | length(centerXYZ)~=3
        error('Coordinate format invalid.')
    end
    fprintf('-Centered at: (%g,%g,%g)\n',centerXYZ)
    
    % create shape
    dim = repmat((radius*2) + 1,[1 3]);
    COORDS = zeros(dim);
    [x,y,z] = ind2sub(dim,1:numel(COORDS));
    coords = [x' y' z'];
    if strcmp(shape,'sphere')
        coordDistXYZ = coords - repmat(radius+1,[size(coords,1),3]);
        coordDistEuclidean = sqrt(sum(coordDistXYZ.^2,2));
        COORDS(:) = coordDistEuclidean;
        COORDS(COORDS>radius) = inf;
        COORDS(~isinf(COORDS)) = 1;
        COORDS(isinf(COORDS)) = 0;
    elseif strcmp(shape,'cube')
        COORDS = ones(dim);
    else
        error('Shape unknown.')
    end
    
    % sphere in brain
    coord_inshape = coords(find(COORDS(:)),:);
    coord_inshape_0origin = coord_inshape - repmat(radius+1,[size(coord_inshape,1) 3]);
    coord_inshape_inbrain = coord_inshape_0origin + repmat(centerXYZ,[size(coord_inshape,1) 1]);
    
    %% remove outside brain if applicable
    %badInd = find(sum(coord_insphere_inbrain<0 | coord_insphere_inbrain>voi.OriginalVMRFramingCubeDim,2));
    %coord_insphere_inbrain(badInd,:) = [];
    
    numVox = size(coord_inshape_inbrain,1);
    voi.VOI(numVOI).NrOfVoxels = numVox;
    voi.VOI(numVOI).Voxels = coord_inshape_inbrain;
    voi.VOI(numVOI).Color = voicolours(numVOI,:);
    fprintf('-Num voxels in brain: %g\n',numVox)
end

%% Save voi
voi.SaveAs([fp_out fn_out])
fprintf('\nVOI saved to: %s\n',[fp_out fn_out])

end