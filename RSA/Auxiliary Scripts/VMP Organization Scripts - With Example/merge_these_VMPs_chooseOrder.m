function merge_these_VMPs

%% Params
applyMask = true;

%% Not params
list = dir('VMPs_*.vmp');

%% Reorder
%display list
while 1
for fid = 1:length(list)
    fprintf('%g. %s\n',fid,list(fid).name);
end
in = input(sprintf('Please enter order to use. Format is "1 3 8 9" without quotes.\nYou may omit maps. Enter "exit" without quotes to end.\nMaps to use:'),'s');
if strcmp(lower(in),'exit')
    error('Manually ended.')
else
    in = str2num(in);
    if isnumeric(in)
        list = list(in);
        break;
    end
end
end

%% collect and mask

if applyMask
    msk = xff('15Ss_AvgVTC_TAL_MASK.msk');
end

vmpMain = xff(list(1).name);
vmpMain.Map(2:end) = [];

for fid = 2:length(list)
    vmpThis = xff(list(fid).name);
    
    vmpMain.Map(fid) = vmpThis.Map(1);
end

for mid = 1:length(list)
    if applyMask
        vmpMain.Map(mid).VMPData(~(msk.Mask(:))) = 0;
    end
    
%     vmpMain.Map(mid).LowerThreshold = 3;
end


vmpMain.NrOfMaps = length(vmpMain.Map);

if applyMask
    vmpMain.SaveAs('All_Models_TMaps_Masked_ReOrdered.vmp');
else
    vmpMain.SaveAs('All_Models_TMaps_ReOrdered.vmp');
end

disp('done')