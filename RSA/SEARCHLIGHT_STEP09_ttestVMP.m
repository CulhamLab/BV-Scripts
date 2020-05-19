function SEARCHLIGHT_STEP5_ttest

%params
[p] = ALL_STEP0_PARAMETERS;

%paths
vmpFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '8-9. VMPs' filesep];

%suffix
if p.SEARCHLIGHT_USE_SPLIT
    suffix = '_SPLIT';
else
    suffix = '_NONSPLIT';
end

%% t-tests vs zero

%list vmp
list = dir([vmpFol '*rvalues' suffix '.vmp']);

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
    
    %number of voxels for bonf
    vmp.Map(m).BonferroniValue = sum(vmp.Map(m).VMPData(:) ~= 0);
    
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
vmp.SaveAs([vmpFol 'TTEST_PMAP' suffix '.vmp']);

%complete ttest t-map
tvmp.NrOfMaps = length(list);
tvmp.SaveAs([vmpFol 'TTEST_TMAP' suffix '.vmp']);

%clear
vmp.ClearObject;

%% Model Comarison t-tests

%do model comparisons?
if ~isempty(p.SEARCHLIGHT_MODEL_COMPARISON_TTEST)
    
    %disp
    number_comparisons = size(p.SEARCHLIGHT_MODEL_COMPARISON_TTEST, 1);
    fprintf('Computing %d model comparisons...\n', number_comparisons);
    
    %use t-value vmp, clear all but first map
    tvmp.Map = tvmp.Map(1);
    sz = size(tvmp.Map(1).VMPData);
    
    %expected df
    expected_df = p.NUMBER_OF_PARTICIPANTS - 1;
    
    %perform each comparison...
    for c = 1:number_comparisons
        model_names = p.SEARCHLIGHT_MODEL_COMPARISON_TTEST(c,:);
        model_fp = cellfun(@(x) [vmpFol x '_rvalues' suffix '.vmp'], model_names, 'UniformOutput', false);
        
        fprintf('\tProcessing %d of %d: %s > %s\n', c, number_comparisons, model_names{:});
        
        if length(unique(model_names)) ~= 2
            tvmp.ClearObject;
            error('Comparing model to itself')
        end
        
        if any(~cellfun(@(x) exist(x,'file'), model_fp))
            tvmp.ClearObject;
            error('Could not find expected rvalue VMPs')
        end
        
        %load data into [participant , x , y, z , model] (xyz must be last for fast t-test method)
        fprintf('\t\tLoading and organizing data...\n');
        values = nan([p.NUMBER_OF_PARTICIPANTS sz 2]);
        for m = 1:2
            vmp = xff(model_fp{m});
            
            if vmp.NrOfMaps ~= p.NUMBER_OF_PARTICIPANTS
                vmp.ClearObject;
                tvmp.ClearObject;
                error('Loaded rvalue VMP contains unexpected number of participant maps')
            end
            
            for par = 1:p.NUMBER_OF_PARTICIPANTS
                values(par, :, :, :, m) = vmp.Map(par).VMPData;
            end
            
            vmp.ClearObject;
        end
        
        %set zeros to nan
        values(values == 0) = nan;
        
        %calculate t-maps
        fprintf('\t\tCalculating t-map...\n');
        [~,~,~,stats] = ttest( values(:,:,:,:,1) , values(:,:,:,:,2) );
        
        %missing subject data?
        actual_df = nanmax(stats.df(:));
        if actual_df ~= expected_df
            tvmp.ClearObject;
            error('Actual df (%d) is not equal to expected (%d)', actual_df, expected_df);
        end
        
        %organize
        fprintf('\t\tOrganizing result...\n');
        tmap = squeeze(stats.tstat);
        tmap(isnan(tmap)) = 0;
        ind = length(tvmp.Map) + 1;
        tvmp.Map(ind) = tvmp.Map(1);
        
        tvmp.Map(ind).VMPData = tmap;
        
        tvmp.Map(ind).Name = sprintf('%s > %s', model_names{:});
        tvmp.Map(ind).DF1 = actual_df;
        tvmp.Map(ind).BonferroniValue = sum(tvmp.Map(ind).VMPData(:) ~= 0);
               
    end
    
    %clear template map
    tvmp.Map = tvmp.Map(2:end);
    tvmp.NrOfMaps = length(tvmp.Map);
    
    %save
    fprintf('\tSaving VMP...\n');
    tvmp.SaveAs([vmpFol 'ModelComparison_TMAP' suffix '.vmp']);
    
%end of model comparisons
end

%clear vmp
tvmp.ClearObject;

%% Done

disp Done.