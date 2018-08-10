function SEARCHLIGHT_STEP5_ttest

%params
[p] = ALL_STEP0_PARAMETERS;

%paths
vmpFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '8-9. VMPs' filesep];

%list vmp
list = dir([vmpFol '*rvalues.vmp']);

%create pmap vmp from this vmp
vmp = xff([vmpFol list(1).name]);
vmp.Map = vmp.Map(1);

%create tmap vmp
tvmp = xff([vmpFol list(1).name]);
tvmp.Map = tvmp.Map(1);

%ttest on each model
for m = 1:length(list)
    clear vmpModel
    vmpModel = xff([vmpFol list(m).name]);
    
    %name of model
    name = list(m).name;
    name = name(1: find(name=='_',1,'last')-1);
    
    %matlab ttest (for p-map)
    datmat = [];
    for i = 1:vmpModel.NrOfMaps
        datmat(i,:,:,:) = vmpModel.Map(i).VMPData;
    end
    [~,ttestMap] = ttest(datmat,0,p.VMP_TTEST_UPPER_P_THRESHOLD,'right');
    ttestMap = 1-squeeze(ttestMap);
    if m>1
        vmp.Map(m) = vmp.Map(m-1);
    end
    vmp.Map(m).VMPData = ttestMap;
    vmp.Map(m).LowerThreshold = (1-p.VMP_TTEST_UPPER_P_THRESHOLD);
    vmp.Map(m).UpperThreshold = 1;
    vmp.Map(m).ShowPositiveNegativeFlag = p.VMP_TTEST_SHOW_POS_NEG;
    vmp.Map(m).Name = [name '_ttest(one-minus-p)'];
    
    %BV ttest (for t-map)
    %NOTE: these were coded separately as a check for validity
    indMapUse = 1:vmpModel.NrOfMaps;
    formula = sprintf('sqrt(%d) .* mean($1:%d, 4) ./ std($1:%d, [], 4)',length(indMapUse),length(indMapUse),length(indMapUse));
    cfopts = struct('mapsel', indMapUse, 'name', [name '_ttest(t-map)'], 'DF1', length(indMapUse)-1);
    vmpModel.ComputeFormula(formula, cfopts);
    vmpModel.Map(end).ShowPositiveNegativeFlag = p.VMP_TTEST_SHOW_POS_NEG;
    vmpModel.Map(end).LowerThreshold = p.VMP_TTEST_LOWER_T_THRESHOLD;
    vmpModel.Map(end).UpperThreshold = vmpModel.Map(end).LowerThreshold;
    %tvmp.Map(m) = vmpModel.Map(end); %didn't work - using method below
    fnames = fields(vmpModel.Map(end));
    for f = fnames'
        f=f{1};
        eval(['tvmp.Map(m).' f ' = vmpModel.Map(end).' f ';'])
    end
end

%complete ttest one-minus-p map
vmp.NrOfMaps = length(list);
vmp.SaveAs([vmpFol 'TTEST_PMAP.vmp']);

%complete ttest t-map
tvmp.NrOfMaps = length(list);
tvmp.SaveAs([vmpFol 'TTEST_TMAP.vmp']);

disp Done.