function merge_these_VMPs

%% Params
applyMask = true;

%% Not params

list = dir('VMPs_*.vmp');

vmpMain = xff(list(1).name);
vmpMain.Map(2:end) = [];

if applyMask
    msk = xff('15Ss_AvgVTC_TAL_MASK.msk');
end

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
    vmpMain.SaveAs('All_Models_TMaps_Masked.vmp');
else
    vmpMain.SaveAs('All_Models_TMaps.vmp');
end