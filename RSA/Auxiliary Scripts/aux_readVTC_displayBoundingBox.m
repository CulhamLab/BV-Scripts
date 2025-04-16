%aux_readVTC_displayBoundingBox
%
%INSTRUCTIONS:
%Run the script and select an VTC when prompted. The order of conditions
%will be displayed (may include predictors such as translation, rotation,
%and constant).
%
%NOTE:
%Uses the "FILEPATH_TO_VTC_AND_SDM" parameter from BOTH_setep0_PARAMETERS.
%
function aux_readVTC_displayBoundingBox

%get params
returnPath = pwd;
cd ..
[p] = ALL_STEP0_PARAMETERS;
cd(returnPath)

%select file
[FileName,PathName,FilterIndex] = uigetfile(sprintf('%s*.vtc',p.FILEPATH_TO_VTC_AND_SDM));
if FilterIndex~=1
    error('Must select an VTC.')
end

%load
fpath = [PathName FileName];
fprintf('Reading %s\n',fpath)
vtc = xff(fpath);

%display
fprintf('XStart\t= %d\n',vtc.XStart);
fprintf('XEnd\t= %d\n',vtc.XEnd);
fprintf('YStart\t= %d\n',vtc.YStart);
fprintf('YEnd\t= %d\n',vtc.YEnd);
fprintf('ZStart\t= %d\n',vtc.ZStart);
fprintf('ZEnd\t= %d\n',vtc.ZEnd);
