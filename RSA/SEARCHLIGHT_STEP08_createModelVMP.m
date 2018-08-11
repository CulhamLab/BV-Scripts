function SEARCHLIGHT_STEP4_createModelVMP

%params
[p] = ALL_STEP0_PARAMETERS;

%paths
inputFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '7. 3D Matrices of Model RValues' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '8-9. VMPs' filesep];
if ~exist(saveFol,'dir')
    mkdir(saveFol);
end

%gather all maps
disp('Gathing r-maps...')
for par = 1:p.NUMBER_OF_PARTICIPANTS
clearvars -except par inputFol saveFol p maps

load([inputFol sprintf('step5_modelCorrelations_%s',p.FILELIST_PAR_ID{par})])

for m = 1:models.mNum
    %vmp map
    map = [];
    map = resultMat(:,:,:,m);
    ss = size(map);
    map(isnan(map)) = 0;
    
    %change left/right convention if needed
    if p.USE_OLD_LEFT_RIGHT_CONVENTION == true
        map = map(:,:,end:-1:1);
    end
    
    %put in cell mat
    maps{par,m} = map;

end
end

%create vmp for each model
clearvars -except sub inputFol saveFol p maps models vtcRes
disp('Saving to VMPs...')
for m = 1:models.mNum
    %prepare vmp struct
    clear vmp
    vmp = xff('vmp');

    %bounding box (defined from params)
    for f = fields(p.BBOX)'
        eval(['vmp.' f{1} ' = p.BBOX.' f{1} ';'])
    end
    
    %resolution (changing this SHOULD work)
    vmp.Resolution = vtcRes;
    
    if p.LAST_DITCH_EFFORT_VMP_FIX
        vmp.XEnd = vmp.XEnd+vmp.Resolution;
        vmp.YEnd = vmp.YEnd+vmp.Resolution;
        vmp.ZEnd = vmp.ZEnd+vmp.Resolution;
    end
    
    vmpName = sprintf('%s_rvalues',models.names{m});
    
    for par = 1:p.NUMBER_OF_PARTICIPANTS
        %defaults
        if par>1
            vmp.Map(par) = vmp.Map(par-1);
        end
        
        %model name
        vmp.Map(par).Name = sprintf('%s_%s',vmpName,p.FILELIST_PAR_ID{par});
        
        %default threshold
        vmp.Map(par).LowerThreshold = p.VMP_RMAP_LOWER_THRESHOLD;
        vmp.Map(par).UpperThreshold = 1.0;
        
        %map
        vmp.Map(par).VMPData = maps{par,m};
        
        %show all values
        vmp.Map(par).ShowPositiveNegativeFlag = p.VMP_RMAP_SHOW_POS_NEG;
        
        %no bonf
        vmp.Map(par).BonferroniValue = 0;
        
        %no DF
        vmp.Map(par).DF1 = 0;
        vmp.Map(par).DF2 = 0;
    end
   
    %number of maps
    vmp.NrOfMaps = p.NUMBER_OF_PARTICIPANTS;
    
    %save
    vmp.SaveAs([saveFol vmpName '.vmp']);
end
disp Done.