%Step 1a: Calculate betas from BV files (VTCs and SDMs)

function BOTH_step1_PREPARE1_calculateBetas

%where is data and output folder
[p] = ALL_STEP0_PARAMETERS;
outfol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '1-2. Betas' filesep];
if ~exist(outfol,'dir')
    mkdir(outfol)
end

fprintf('If you see the warning "Matrix is singular to working precision", then there is a problem in the BV files (most likely sdm).\n')

[filelist] = create_filelist(p);
%[~,~,filelist] = xlsread(p.FILELIST_FILENAME);

%for each subject, find all runs and calc betas
fig = figure('Position', get(0,'ScreenSize'));
for par = 1:p.NUMBER_OF_PARTICIPANTS
    for run = 1:p.NUMBER_OF_RUNS
        fprintf('\nCalculating betas for PAR %d/%d RUN %d/%d\n',par,p.NUMBER_OF_PARTICIPANTS,run,p.NUMBER_OF_RUNS)
        
        ind = cellfun(@(x,y) isnumeric(x) && isnumeric(y) && (x==par) && (y==run), filelist(:,1), filelist(:,2));
        fp_vtc = filelist{ind,3};
        fp_sdm = filelist{ind,4};
        fp_out = sprintf('%s%s_%s', outfol, p.FILELIST_PAR_ID{par}, p.FILELIST_RUN_ID{run});
        
        fprintf('VTC: %s\nSDM: %s\nOut: %s\n', fp_vtc, fp_sdm, fp_out);
        
        createBetasFromBV(fp_sdm, fp_vtc, fp_out, true, fig); %subfunction below

%         %find vtc
%         listVTC = dir(sprintf('%sSUB%02d_RUN%02d*.vtc',p.FILEPATH_TO_VTC_AND_SDM,sub,run));
%         
%         %find sdm
%         listSDM = dir(sprintf('%sSUB%02d_RUN%02d*.sdm',p.FILEPATH_TO_VTC_AND_SDM,sub,run));
%         
%         if length(listVTC) ~= 1 | length(listSDM) ~= 1
%             warning(sprintf('Wrong number vtc/sdm files for SUB%02d_RUN%02d.\n',sub,run))
%         else
%             vtcPath = [p.FILEPATH_TO_VTC_AND_SDM listVTC.name];
%             sdmPath = [p.FILEPATH_TO_VTC_AND_SDM listSDM.name];
%             createBetasFromBV(sdmPath,vtcPath,sprintf('%sSUB%02d_RUN%02d',outfol,sub,run)); %subfunction below
%         end
    end
end
fprintf('\n\nBeta calculations complete.\n')
close(fig);
end


% Below is a beta calc from VTC+SDM script that I created for Sara
% It produced 1mm^3 voxel betas, but removes subsample redundancy (i.e.,
% only a single 1mm^3 voxel from each 3mm^3 is used to calc betas) 

% Pictures are outputted from a mini (10x10x10) beta calc for manual
% checking of alignment between 1mm and 3mm spaces


% Parameters:
%    bvbetafile - a string naming a BV file that contains information about condition betas
%    varargin - whatever other parameters are needed to specify the conditions, runs, etc. 
%                    needed to extract the betas for Condition c for Run r for Subject s and put it into 3D space
% Returns:
%    A - a 3D matlab matrix in some sort of 3D space
%        other return values may also be useful, such as some sort of code identifying the 3D space used
%        (e.g., MNI space, Talairach space, ACPC space, etc.
function [betas,vox,vtcRes,offsetXYZ] = createBetasFromBV(sdmFilepath,vtcFilepath,outputFilepath,doSave,fig)
if ~exist('doSave','var')
	doSave = true;
end
if exist('fig','var') & ishandle(fig)
	clf(fig)
	close_fig = false;
else
	fig = figure('Position', get(0,'ScreenSize'));
	close_fig = true;
end

% %% Step 0: Example Input
% vtcFilepath = 'SUB16_12_GraspTaxonomy_SCCAI2_3DMCS_LTR_THP3c_ACPC_box.vtc';
% sdmFilepath = 'SUB16_12_GraspTaxonomy_SCCAI2_3DMCS_LTR_THP3c_ACPC_72Cond_volumes.sdm';
% outputFilepath = [pwd '\Output\SUB16_12_WholeBrain_Betas'];

%% requires neuroelf tools
ne = neuroelf;

%% Step 1: Load files
%Load Time Course
vtc = xff(vtcFilepath);

%Load Design Matrix
sdm = xff(sdmFilepath);

%% Step 2: Create voi with 1mm^3 res covering a small chunk of brain to determine how the functional voxels fit over the 1mm^3 space
%For some reason, BV makes it hard to be 100% sure where the functional
%voxels fall without running a little check. There doesn't seem to be any
%fully consistent pattern.

%There is a simpler alternetive which skips this step, but it requires that
%each boundry be moved in by 2mm, which isn't ideal

%create blank voi struct (using this for a test voi plus a wholebrain voi)
voiWholeBrain = xff('voi');

%fill in voi paramets with some defaults
voiWholeBrain.NrOfVOIs = 1;
voiWholeBrain.VOI(1).Name = 'Whole-Brain';
voiWholeBrain.VOI(1).Color = [255 255 255];
voiWholeBrain.OriginalVMRResolutionX = 1;
voiWholeBrain.OriginalVMRResolutionY = 1;
voiWholeBrain.OriginalVMRResolutionZ = 1;
voiWholeBrain.OriginalVMRFramingCubeDim = 256;
voiWholeBrain.ReferenceSpace = 'ACPC'; %doesn't matter
voiWholeBrain.FileVersion = 4;
voiWholeBrain.OriginalVMROffsetX = 0;
voiWholeBrain.OriginalVMROffsetY = 0;
voiWholeBrain.OriginalVMROffsetZ = 0;
voiWholeBrain.Convention = 1;

%create a little voi in 1mm^3 space
%Note: cannot include voxels that there is no time course data for - these
%can exist on the edges of the recorded brain space (this is a big part of
%why this step is required)
voiCubeWidth = 10; %in mm
vox = nan(voiCubeWidth^3,3);
xs = round(mean([vtc.XEnd vtc.XStart]));
ys = round(mean([vtc.YEnd vtc.YStart]));
zs = round(mean([vtc.ZEnd vtc.ZStart]));
counter = 0;
Xs = xs-(1+voiCubeWidth):xs-2;
Ys = ys-(1+voiCubeWidth):ys-2;
Zs = zs-(1+voiCubeWidth):zs-2;
for x = Xs
    for y = Ys
        for z = Zs
            counter = counter + 1;
            vox(counter,:) = [x y z];
        end
    end
end

%check that there are no nan left at the bottom
if size(vox,1) > counter
    %should only be at end...
    vox(counter+1:end,:) = []; %remove extra rows
end
if sum(isnan(vox(:))) %double check, nans would crash later processes
    error('Should not heve had any NANs left.')
end

%place this voi into the voi struct
voiWholeBrain.VOI(1).Voxels = vox;
voiWholeBrain.VOI(1).NrOfVoxels = size(vox,1);

%extract time course for the mini voi
%voitc has the time course, voiuvec is a vector of indexes points to the
%corners of each unqiue rectagle of values (is the corner w/ max XYZ)
[voitc, voiuvec] = vtc.VOITimeCourse(voiWholeBrain, Inf); %extract time course
voitc = voitc{1}(1,:); %just use first volume

if sum(sum(voitc(~isnan(voitc)))) == 0
    save
    error('Bounding box is really, really off!')
end

%find a cube of unique values that is fully intact (not cut off at edges)
sizeOfFullCube = vtc.Resolution^3;
bad = 1;
originCoords = nan;
for u = unique(voitc)
    f = find(voitc == u);
    if length(f) == sizeOfFullCube %has right # of values
        %is a cube...
        bad = 0;
        originCoords = [];
        for coord = 1:3
            if range(vox(f,coord)) ~= vtc.Resolution-1
                bad = 1;
            else
                originCoords(coord) = max(vox(f,coord));
            end
        end
        if ~bad %is cube of same value of right size
            break
        end
    end
end
if bad %didn't find one
    error('Functional voxel locations on 1mm^3 map could not be determined')
end
cornerCoordInd = sub2ind([voiCubeWidth voiCubeWidth voiCubeWidth],originCoords(1)-Xs(1)+1,originCoords(2)-Ys(1)+1,originCoords(3)-Zs(1)+1);

%visualize to check that origin is good
timecourse3D = nan(voiCubeWidth,voiCubeWidth,voiCubeWidth);
for v = 1:counter
    voxInd = sub2ind([voiCubeWidth voiCubeWidth voiCubeWidth],vox(v,1)-Xs(1)+1,vox(v,2)-Ys(1)+1,vox(v,3)-Zs(1)+1);
    timecourse3D(voxInd) = voitc(v);
end

%close all
%fig = figure('Position', get(0,'ScreenSize'));

XwithCorner = originCoords(1) - Xs(1) + 1;
YwithCorner = originCoords(2) - Ys(1) + 1;
ZwithCorner = originCoords(3) - Zs(1) + 1;
for z = 1:voiCubeWidth
    subplot(3,4,z)
    hold on
    imagesc(timecourse3D(:,:,z))
    if ~mod(ZwithCorner - z,vtc.Resolution)
        for x = 1:voiCubeWidth
            for y = 1:voiCubeWidth
                if ~mod(XwithCorner-x,vtc.Resolution) & ~mod(YwithCorner-y,vtc.Resolution)
                    plot(x,y,'*m','MarkerSize',12)
                end
            end
        end
    end
    if z == ZwithCorner
        plot(YwithCorner,XwithCorner,'*w','MarkerSize',12)
    end
    hold off
    axis([0.5 voiCubeWidth+0.5 0.5 voiCubeWidth+0.5])
    axis square
    set(gca,'YDir','reverse','Xtick',1:voiCubeWidth,'YTick',1:voiCubeWidth);
    ylabel('X Coord (1)')
    xlabel('Y Coord (2)')
    title(['Z Coord (3) = ' num2str(z)])
    colorbar
end
suptitle('White * marks the cube corner found | Purple * marks corners based on this origin')
drawnow
saveas(fig,outputFilepath,'jpg')
if close_fig
	close(fig)
end

%only need a few things kept
clearvars -except vtcFilepath sdmFilepath outputFilepath vtc sdm voiWholeBrain originCoords ne

%% Step 3:Create Whole-Brain voi (reuse old voi struct)
%Only uses one 1mm^3 voxel for each functional voxel, uses step 2 (above)
%to avoid calling dataless voxels from around the edge of the recorded
%region

%which coords to use (based on origin determined in step 2)
Xs = unique([originCoords(1):-1*vtc.Resolution:vtc.XStart originCoords(1):vtc.Resolution:vtc.XEnd]);
Ys = unique([originCoords(2):-1*vtc.Resolution:vtc.YStart originCoords(2):vtc.Resolution:vtc.YEnd]);
Zs = unique([originCoords(3):-1*vtc.Resolution:vtc.ZStart originCoords(3):vtc.Resolution:vtc.ZEnd]);

%create list of voxel coords
% % % counter = 0;
% % % for x = Xs
% % %     for y = Ys
% % %         for z = Zs
% % %             counter = counter + 1;
% % %             vox(counter,:) = [x y z];
% % %         end
% % %     end
% % % end

% %check that there are no nan left at the bottom
% if size(vox,1) > counter
%     %should only be at end...
%     vox(counter+1:end,:) = []; %remove extra rows
% end

%much faster method
[x,y,z] = meshgrid(Xs,Ys,Zs);
vox = [x(:) y(:) z(:)];

if sum(isnan(vox(:))) %double check, nans would crash later processes
    error('Should not heve had any NANs left.')
end

%place this voi into the voi struct
voiWholeBrain.VOI(1).Voxels = vox;
voiWholeBrain.VOI(1).NrOfVoxels = size(vox,1);

% % %output for checking
% % voiWholeBrain

%% Step 4: Calculate Betas (voi could be whole-brain)
%get vtc data
[voitc, voiuvec] = vtc.VOITimeCourse(voiWholeBrain, Inf); 

%z-transformation of time course data
[ztc, zf, zsh] = ne.ztrans(voitc{1});

%pre-allocate
betas = nan(voiWholeBrain.VOI(1).NrOfVoxels,sdm.FirstConfoundPredictor-1);

%compute beta maps
[betas, irtc, ptc, se] = ne.calcbetas(sdm.RTCMatrix, ztc);

%% Step 5: Save (for now)

%position info
box.XStart = vtc.XStart;
box.XEnd = vtc.XEnd;
box.YStart = vtc.YStart;
box.YEnd = vtc.YEnd;
box.ZStart = vtc.ZStart;
box.ZEnd = vtc.ZEnd;

%include the vtc res (e.g., 3mm^3 functional voxels)
vtcRes = vtc.Resolution;

%condition names
conditionNames = sdm.PredictorNames;

%VariableHelp/Legend
VariableHelp.betas = 'rows: voxels, columns: conditions';
VariableHelp.vox = 'row: voxels, columns = XYZ';
VariableHelp.vtcRes = 'resolution of functional space';
VariableHelp.vtcFilepath = 'path to time course used';
VariableHelp.sdmFilepath = 'path to design matrix used';
VariableHelp.voiWholeBrain = 'BVQX voi struct for the whole-brain.';

%save everything we may need (voiWholeBrain may be overkill but it's small)
save(outputFilepath,'betas','vox','vtcRes','vtcFilepath','sdmFilepath','voiWholeBrain','VariableHelp','box','conditionNames');

vtc.ClearObject;
sdm.ClearObject;
end

function [xls] = create_filelist(p)

%% checks
if length(p.FILELIST_PAR_ID) ~= p.NUMBER_OF_PARTICIPANTS
    error('Invalid number of participants ids.');
end

%% run
%delete prior filelist if any
if exist(p.FILELIST_FILENAME,'file')
    delete(p.FILELIST_FILENAME);
end

%run
xls = {'Participant' 'Run' 'VTC' 'SDM'};
for par = 1:p.NUMBER_OF_PARTICIPANTS
    if p.FILELIST_SUBFOLDERS
        dir = [p.FILEPATH_TO_VTC_AND_SDM p.FILELIST_PAR_ID{par} filesep];
    else
        dir = p.FILEPATH_TO_VTC_AND_SDM;
    end
    
    for run = 1:p.NUMBER_OF_RUNS
        fn_vtc = strrep(strrep(p.FILELIST_FORMAT_VTC,'[PAR]',p.FILELIST_PAR_ID{par}),'[RUN]',p.FILELIST_RUN_ID{run});
        fn_sdm = strrep(strrep(p.FILELIST_FORMAT_SDM,'[PAR]',p.FILELIST_PAR_ID{par}),'[RUN]',p.FILELIST_RUN_ID{run});
        
        fp_vtc = [dir fn_vtc];
        fp_sdm = [dir fn_sdm];
        
        %check if files exist
        if ~exist(fp_vtc,'file')
            warning(sprintf('Cannot Find VTC: %s\n',fp_vtc));
        end
        if ~exist(fp_sdm,'file')
            warning(sprintf('Cannot Find SDM: %s\n',fp_sdm));
        end
        
        xls(end+1,:) = {par run fp_vtc fp_sdm};
    end
end

xlswrite(p.FILELIST_FILENAME,xls);

end