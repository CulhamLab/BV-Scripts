%places betas (odd and even, separate) from step2 in 3D matrices for easier searchlight-ing

function BOTH_step1_PREPARE5_convertTo3D

%params
[p] = ALL_STEP0_PARAMETERS;

%paths
inputFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '4. Demeaned and Averaged Betas' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '5. 3D Matrices of Betas' filesep];
if ~exist(saveFol,'dir')
    mkdir(saveFol);
end

doOnce = false;

for par = 1:p.NUMBER_OF_PARTICIPANTS
clearvars -except par p ss inputFol saveFol doOnce
fprintf('Running participant %g of %g...\n',par,p.NUMBER_OF_PARTICIPANTS)
load ([inputFol sprintf('step2_demeanAndAverageBetas_%s',p.FILELIST_PAR_ID{par})])

if ~doOnce
    ss = [floor(length(p.BBOX.XStart:p.BBOX.XEnd)/vtcRes) floor(length(p.BBOX.YStart:p.BBOX.YEnd)/vtcRes) floor(length(p.BBOX.ZStart:p.BBOX.ZEnd)/vtcRes)];
    fprintf('Data will be placed into matrix %d x %d x %d\n',ss)
    doOnce = true;
end

%box is now ready from vtc - already present in step2 file
%put into 3mm 3D matrix, keep start/end info
%box.XStart = min(vox(:,1));
%box.XEnd = max(vox(:,1));
%box.YStart = min(vox(:,2));
%box.YEnd = max(vox(:,2));
%box.ZStart = min(vox(:,3));
%box.ZEnd = max(vox(:,3));

% newVox(:,1) = ((vox(:,1) - box.XStart) / 3) + 1;
% newVox(:,2) = ((vox(:,2) - box.YStart) / 3) + 1;
% newVox(:,3) = ((vox(:,3) - box.ZStart) / 3) + 1;

% newVox(:,1) = ((vox(:,1) - min(vox(:,1))) / 3) + 1;
% newVox(:,2) = ((vox(:,2) - min(vox(:,2))) / 3) + 1;
% newVox(:,3) = ((vox(:,3) - min(vox(:,3))) / 3) + 1;

%use some tricks to get save coord XYZ
returnPath = pwd;
try
	cd('Required Methods')
% 	[X,Y,Z] = SAVE_SYSTEM_COORD_CONVERSION( (vox(:,[3 1 2])-(256/2))*-1 , vtcRes);
    [X,Y,Z] = SAVE_SYSTEM_COORD_CONVERSION( vox , vtcRes);
	cd ..
catch e
	cd(returnPath)
	rethrow(e)
end
newVox = [X Y Z];
r = range(newVox);
fprintf('This particiapnt uses sub-matrix %d x %d x %d\n',r)

% betas_3D_all = nan([max(newVox) p.NUMBER_OF_CONDITIONS]);
% betas_3D_even = nan([max(newVox) p.NUMBER_OF_CONDITIONS]);
% betas_3D_odd = nan([max(newVox) p.NUMBER_OF_CONDITIONS]);

betas_3D_all = nan([ss p.NUMBER_OF_CONDITIONS]);
betas_3D_even = nan([ss p.NUMBER_OF_CONDITIONS]);
betas_3D_odd = nan([ss p.NUMBER_OF_CONDITIONS]);

indxVoxWithData = sub2ind(ss,newVox(:,1),newVox(:,2),newVox(:,3));

for i = 1:p.NUMBER_OF_CONDITIONS
    thisBetaSlice_all = nan(ss);
    thisBetaSlice_even = nan(ss);
    thisBetaSlice_odd = nan(ss);
    
    thisBetaSlice_all(indxVoxWithData) = allBetas_MeanAcrossSub(:,i);
    thisBetaSlice_even(indxVoxWithData) = evenBetas_MeanAcrossSub(:,i);
    thisBetaSlice_odd(indxVoxWithData) = oddBetas_MeanAcrossSub(:,i);
    
    betas_3D_all(:,:,:,i) = thisBetaSlice_all;
    betas_3D_even(:,:,:,i) = thisBetaSlice_even;
    betas_3D_odd(:,:,:,i) = thisBetaSlice_odd;
end

runtime.Step5 = p.RUNTIME;
save([saveFol sprintf('step3_organize3D_%s',p.FILELIST_PAR_ID{par})],'indxVoxWithData','betas_3D_all','betas_3D_even','betas_3D_odd','conditions','vtcRes','runtime')

end

fprintf('Completed placing betas in 3D matrices.\n')

end
