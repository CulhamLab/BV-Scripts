%aux_copyRenameVTCandSDM(inputPath,outputPath,subIDs,runIDs)
%aux_copyRenameVTCandSDM(inputPath,outputPath,subIDs,runIDs,vtcRequirement,sdmRequirement)
%
%Copies the VTC and SDM files from the folder "inputPath" to the folder
%"outputPath" while renaming to SUB##_RUN##* convention.
%
%INPUTS:
%inputPath and outputPath are both strings. subIDs and runIDs are both cell
%arrays of strings. For each pairing of a subID string with a runID string,
%there must be exactly one VTC and one SDM that contain both strings in the
%filename. vtcRequirement and sdmRequirement are optional string arguments.
%
%WILDCARD(*):
%Wildcard notation will work for subIDs and runIDs, but not vtcRequirement
%and sdmRequirement.
%
%EXAMPLE:
%%Copies all VTC/SDM from "C:\in" to "C:\out". There are 3 subjects, each
%%with 5 runs. A vtc have a names like
%%"AB11_1_SCSAI_3DMCTS_LTR_THP3c_TAL_SD3DVSS6.00mm.vtc"
%inputPath = 'C:\in';
%outputPath = 'C:\out';
%subIDs = {'AB11_' 'CD22_' 'EF33_'};
%runIDs = {'_1_' '_2_' '_3_' '_4_' '_5_'};
%aux_copyRenameVTCandSDM(inputPath,outputPath,subIDs,runIDs)
%%or if you need the sdm filename to contain "TAL followed by "72Cond"
%%(with anything in between TAL and 72Cond)
%vtcRequirement = '';
%sdmRequirement = 'TAL*72Cond';
%aux_copyRenameVTCandSDM(inputPath,outputPath,subIDs,runIDs,vtcRequirement,sdmRequirement)

function aux_copyRenameVTCandSDM(inputPath,outputPath,subIDs,runIDs,vtcRequirement,sdmRequirement)

% % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FOR CRISTINA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % inputPath = '/home/smacd49/Documents/C-Users/Scott/Kevin_RSA_script_files/SDMs_and_VTCs';
% % % % outputPath = '/home/smacd49/Documents/C-Users/Scott/Kevin_RSA_script_files/SDMs_and_VTCs/aux_SDMs_VTCs';
% % % % subs = [1:12]; %give arbitrary numbers 1-4 to subjects
% % % % for s = subs
% % % %     subIDs{s} = sprintf('SUB%02d',s);
% % % % end
% % % % runs = 1:8;
% % % % for s = subs
% % % %     runIDs{s} = sprintf('RUN%d',s);
% % % % end
% % % % %didn't need vtcRequirement or sdmRequirement
% % % % 
% % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%minimum requirement
if ~exist('inputPath') || ~exist('outputPath') || ~exist('subIDs') || ~exist('runIDs')
    help(mfilename)
end

%check types
if ~ischar(inputPath) | ~ischar(outputPath) | ~iscell(subIDs) | ~iscell(runIDs)
    error('Arguments did not have the correct type. aux_copyRenameVTCandSDM(string,string,cell,cell).')
end

%stop if subIDs or runIDs contain duplicates
if length(subIDs)~=length(unique(subIDs))
    error('subIDs contains duplicates.')
end
if length(runIDs)~=length(unique(runIDs))
    error('runIDs contains duplicates.')
end

%add filesep if needed
if inputPath(end)~=filesep
    inputPath = [inputPath filesep];
end
if outputPath(end)~=filesep
    outputPath = [outputPath filesep];
end

%check input path exists
if ~exist(inputPath,'dir')
    error(sprintf('Input path does not exist.\nTried to locate: %s\n',inputPath))
end

%create output folder if needed
if ~exist(outputPath,'dir')
    warning(sprintf('Output path does not exist. Creating folder: %s\n',outputPath))
    mkdir(outputPath)
end

%display folders/IDs
fprintf('Input folder: %s\nOutput folder: %s\n',inputPath,outputPath)
fprintf('subIDs: %s\nrunIDs: %s\n\n',sprintf('"%s" ',subIDs{:}),sprintf('"%s" ',runIDs{:}))

%check that all files exist + keep filenames
numSub = length(subIDs);
numRun = length(runIDs);
for s = 1:numSub
    %vtc list
    listVTCSub = dir([inputPath '*' subIDs{s} '*.vtc']);
    listVTCSub = struct2cell(listVTCSub);
    listVTCSub = listVTCSub(1,:);
    if exist('vtcRequirement','var')
        listVTCSub = listVTCSub(find(cellfun(@(x) any(strfind(x,vtcRequirement)),listVTCSub)));
    end
    
    %sdm list
    listSDMSub = dir([inputPath '*' subIDs{s} '*.sdm']);
    listSDMSub = struct2cell(listSDMSub);
    listSDMSub = listSDMSub(1,:);
    if exist('sdmRequirement','var')
        listSDMSub = listSDMSub(find(cellfun(@(x) any(strfind(x,sdmRequirement)),listSDMSub)));
    end
    
    for r = 1:numRun
        %vtc
        indContains = cellfun(@(x) any(strfind(x,runIDs{r})),listVTCSub);
        if sum(indContains)>1
            listVTCSub(indContains)'
            error(sprintf('Too many vtc files found for "%s" + "%s".\n',subIDs{s},runIDs{r}))
        elseif ~sum(indContains)
            warning(sprintf('No vtc files found for "%s" + "%s". Skipping this combination.\n',subIDs{s},runIDs{r}))
            sdmNames{s,r} = nan;
            vtcNames{s,r} = nan;
            continue
        else
            vtcNames{s,r} = listVTCSub{find(indContains)};
        end 
        
        %sdm
        indContains = cellfun(@(x) any(strfind(x,runIDs{r})),listSDMSub);
        if sum(indContains)>1
            listSDMSub(indContains)'
            error(sprintf('Too many sdm files found for "%s" + "%s".\n',subIDs{s},runIDs{r}))
        elseif ~sum(indContains)
            warning(sprintf('No sdm files found for "%s" + "%s". Skipping this combination.\n',subIDs{s},runIDs{r}))
            sdmNames{s,r} = nan;
            vtcNames{s,r} = nan;
        else
            sdmNames{s,r} = listSDMSub{find(indContains)};
        end 
    end
end

%display filenames used
fprintf('The following are the VTC filenames used: SUBJECT# (row) by RUN# (column)\n')
disp(vtcNames)
fprintf('The following are the SDM filenames used: SUBJECT# (row) by RUN# (column)\n')
disp(sdmNames)

%copy/rename
disp('Copying/renaming files now. If an error occurs here, it is likely that you do not have write permission. To fix this, open matlab as admin.')
for s = 1:numSub
    for r = 1:numRun
        if ~isnan(sdmNames{s,r})
            %vtc
            newName = sprintf('SUB%02d_RUN%02d_%s',s,r,vtcNames{s,r});
            copyfile([inputPath vtcNames{s,r}],[outputPath newName])
            
            %sdm
            newName = sprintf('SUB%02d_RUN%02d_%s',s,r,sdmNames{s,r});
            copyfile([inputPath sdmNames{s,r}],[outputPath newName])
        end
    end
end

%done
disp('Complete.')