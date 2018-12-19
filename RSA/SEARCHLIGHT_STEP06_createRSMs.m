%uses 3D beta maps from step3 to calculate a 12x12 (odd condition by even condition) RSM for each functional voxel
%
%this is the actual searchlight step
%
%uses radius 2 voxels (diameter is 5 voxels = 15mm), 33 voxels per sphere (i.e., "corners" not included)
%
%now takes only a few minutes per subject (down from 60-120 minutes)

function SEARCHLIGHT_step2_createRSMs

%params
[p] = ALL_STEP0_PARAMETERS;

%paths
inputFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '5. 3D Matrices of Betas' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '6. 3D Matrices of RSMs' filesep];
if ~exist(saveFol,'dir')
    mkdir(saveFol);
end

set_ss_ref = false;

for par = 1:p.NUMBER_OF_PARTICIPANTS
fprintf('Running participant %g of %g...\n',par,p.NUMBER_OF_PARTICIPANTS)
clearvars -except par p inputFol saveFol ss_ref set_ss_ref number_parts
load([inputFol sprintf('step3_organize3D_%s.mat',p.FILELIST_PAR_ID{par})])

%init cell matrix
ss = size(betas_3D_all);
ss = ss(1:3);

%check that dimensions are constant
if ~set_ss_ref
    set_ss_ref = true;
    
    ss_ref = ss;
    fprintf('3D Beta Matrix Size: %s\n', num2str(ss));
    
    number_voxels = prod(ss_ref);
    number_parts = ceil(number_voxels / p.SEARCHLIGHT_NUMBER_VOXELS_PER_FILE);
    fprintf('%d voxels will be split into %d files (%d voxels each)\n', number_voxels, number_parts, p.SEARCHLIGHT_NUMBER_VOXELS_PER_FILE);
    
else
    if any(ss ~= ss_ref)
        error('Sizes of 3D beta matrices are not consistent!')
    end
end

%sphere list prep (e.g., 33 positions if radius 2)
cubeList = [];
for x = -p.SEARCHLIGHT_RADIUS:p.SEARCHLIGHT_RADIUS
for y = -p.SEARCHLIGHT_RADIUS:p.SEARCHLIGHT_RADIUS
for z = -p.SEARCHLIGHT_RADIUS:p.SEARCHLIGHT_RADIUS
    if pdist([x y z; 0 0 0],'euclidean') <= p.SEARCHLIGHT_RADIUS %exclude corners
        cubeList = [cubeList; x y z];
    end
end
end
end

%is split used?
usedSplit = p.SEARCHLIGHT_USE_SPLIT;

%for each vox with data...
% c = 0;
% pctAchieved = 0;
% l = length(indxVoxWithData);
% tic

for part = 1:number_parts

%(re)init
RSMs = cell(ss);

part_min = 1 + ((part-1) * p.SEARCHLIGHT_NUMBER_VOXELS_PER_FILE);
part_max = part * p.SEARCHLIGHT_NUMBER_VOXELS_PER_FILE;

fprintf('-Starting part %d (voxels %d to %d)...\n', part, part_min, part_max);

indxVoxWithData_part = indxVoxWithData((indxVoxWithData >= part_min) & (indxVoxWithData <= part_max));

for voxInd = indxVoxWithData_part'
%     c=c+1;
%     pctDone = round(c/l*100*100)/100;
%     if floor(pctDone) > pctAchieved
%         pctAchieved = pctDone;
%         timeTaken = round(toc/60*100)/100;
%         timePerPctAvg = timeTaken/pctDone;
%         pctRemain = 100 - pctDone;
%         timeRemain = pctRemain * timePerPctAvg;
%         
%         fprintf('%g%% complete (%g minutes elapsed, ETA %g min)\n',pctDone,timeTaken,timeRemain)
%         
% %         fprintf('%g%% complete (%g minutes elapsed)\n',round(c/l*100*100)/100,round(toc/60*100)/100)
%     end
    
    %get XYZ coord of center
    [x_center,y_center,z_center] = ind2sub(ss,voxInd);
    
    %create list of XYZ of all vox in the mini-roi
    coordList = cubeList + repmat([x_center y_center z_center],size(cubeList,1),1);
    
    %collect betas from all valid voxels on the list
    numIncluded = 0;
    evens = [];
    odds = [];
    alls = [];
    for i = 1:length(coordList)
        x = coordList(i,1);
        y = coordList(i,2);
        z = coordList(i,3);
        
        if min(coordList(i,:))>0 %no coord is 0 or less
            if x<=ss(1) & y<=ss(2) & z<=ss(3) %doesn't exceed beta matrix size
                if sum(~isnan(squeeze(betas_3D_all(x,y,z,:)))) %doesn't contain data (there are a few of these)
                    numIncluded = numIncluded + 1;
                    if p.SEARCHLIGHT_USE_SPLIT
                        evens = [evens; squeeze(betas_3D_even(x,y,z,:))'];
                        odds = [odds; squeeze(betas_3D_odd(x,y,z,:))'];
                    else
                        %nonsplit
                        alls = [alls; squeeze(betas_3D_all(x,y,z,:))'];
                    end
                end
            end
        end
        
    end
    
    if ~p.USE_SLOW_RSM_CALCULATION
        %NORMAL METHOD:
        %if a nan made it in, remove it (this can happen at the edge)
        if numIncluded>1
            if p.SEARCHLIGHT_USE_SPLIT
                badRows = find(isnan(mean(odds' + evens')));
                if length(badRows)
                    numIncluded = numIncluded - length(badRows);
                    evens(badRows,:) = [];
                    odds(badRows,:) = [];
                end
            else
                %nonsplit
                badRows = find(isnan(alls'));
                if length(badRows)
                    numIncluded = numIncluded - length(badRows);
                    alls(badRows,:) = [];
                end
            end
        end

        if numIncluded>1 %at least two voxels (might want to increase this)
            clear rsm
            if p.SEARCHLIGHT_USE_SPLIT
                rsm = corr(evens,odds,'type','Pearson');
            else
                %nonsplit
                rsm = corr(alls,alls,'type','Pearson');
            end

            if sum(isnan(rsm(:)))
                warning('nans should not make it into rsm') %%this is happening
            else
                RSMs{x_center,y_center,z_center} = rsm;
            end
        end
    
    else %USE_SLOW_RSM_CALCULATION true
        %SLOW METHOD:
        rsm = nan(p.NUMBER_OF_CONDITIONS,p.NUMBER_OF_CONDITIONS);
        for r1 = 1:p.NUMBER_OF_CONDITIONS
            if p.SEARCHLIGHT_USE_SPLIT
                v1 = evens(:,r1);
            else
                %nonsplit
                v1 = alls(:,r1);
            end
        for r2 = 1:p.NUMBER_OF_CONDITIONS
            if p.SEARCHLIGHT_USE_SPLIT
                v2 = odds(:,r2);
            else
                %nonsplit
                v2 = alls(:,r2);
            end
            
            indGood = find(~isnan(v1)&~isnan(v2));
            if length(indGood)
                v1=v1(indGood);
                v2=v2(indGood);
                rsm(r1,r2) = corr(v1,v2,'type','Pearson');
            else
                rsm(r1,r2) = nan;
            end
        end
        end
        
        if sum(~isnan(rsm(:))) %so long as there is 1+ non-nan
            RSMs{x_center,y_center,z_center} = rsm;
        end
    end
    
end

%save part
fprintf('-Saving part %d (voxels %d to %d)...\n', part, part_min, part_max);
save([saveFol sprintf('step4_RSMs_%s_PART%02d',p.FILELIST_PAR_ID{par},part)],'indxVoxWithData','RSMs','usedSplit','vtcRes','part_min','part_max','ss_ref','number_parts','indxVoxWithData_part')

end

fprintf('done.\n')
end

fprintf('Completed RSM calculations.\n')

end