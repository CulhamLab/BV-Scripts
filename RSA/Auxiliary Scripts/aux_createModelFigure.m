%Works only if models contain only NaN and 2 non-nan values (e.g., 0 and 1)
function aux_createModelFigure(useConditionNames)

%default to using condition names
if ~exist('useConditionNames')
    useConditionNames = true;
end

%font size
FONT_SIZE = 4; %nan to leave as automatic

%get params (contains models)
returnPath = pwd;
cd ..
[p] = ALL_STEP0_PARAMETERS;
cd(returnPath)

%calc number of subplots
numModels = length(p.MODELS.names);
numRow = round(sqrt(numModels));
numCol = ceil(sqrt(numModels));

%figure
fig = figure('Position', get(0,'ScreenSize'));

%colormap
% cmap = [COLOUR_EXCLUDED; COLOUR_LOW; COLOUR_HIGH];
% cmap = jet(100);
cmap = p.RSM_COLOURMAP;
cmap(end+1,:) = [0 0 0];

% % %load condition names
% % fp = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SHARED_DATA filesep '1. Betas' filesep 'SUB01_RUN01.mat'];
% % if exist('CondNames.mat','file') && useConditionNames==true
% %     condNamesFile = load('CondNames.mat');
% %     conditionNames = condNamesFile.conditionNames;
% %     conditionNames = conditionNames(1:p.NUMBER_OF_CONDITIONS);
% % elseif exist(fp,'file') && useConditionNames==true
% %     betaFile = load(fp);
% %     conditionNames = betaFile.conditionNames;
% % else
% %     warning('Either opted not to use condition names or could not find SUB01_RUN01.mat beta file to read condition names from. Conditions will be named numerically.')
% %     conditionNames = mat2cell(1:p.NUMBER_OF_CONDITIONS);
% % end
conditionNames = p.CONDITIONS.DISPLAY_NAMES;

%for each split/nonsplit
splitNames = {'SPLIT' 'NONSPLIT'};
for split = 1:2
    clf
    for m = 1:length(p.MODELS.names)
        %get model
        clear model
        
        %start with non split
        model = p.MODELS.matrices{m};
        
        %if indiv, average
        if size(model,3) > 1
            averaged = true;
            model = nanmean(model, 3);
        else
            averaged = false;
        end
        
        %reorder model
        if isfield(p, 'RSM_PREDICTOR_ORDER') & ~isnan(p.RSM_PREDICTOR_ORDER)
            model = model(p.RSM_PREDICTOR_ORDER, p.RSM_PREDICTOR_ORDER);
            conditionNames_use = conditionNames(p.RSM_PREDICTOR_ORDER);
        else
            conditionNames_use = conditionNames;
        end
        
        %redo split
        if split == 2
            sz = size(model,1);
            for i = 1:sz
                for j = i:sz
                    model(i,j) = nan;
                end
            end
        end
        
%         u = unique(model(~isnan(model)));
%         if length(u)==2
%             h = max(u);
%             l = min(u);
%             model(model==h) = 1;
%             model(model==l) = -1;
%         end

        model = (model - nanmin(model(:)));
        model = (model / (0.5 * nanmax(model(:)))) - 1;
        
        %set nans to -1
        model(isnan(model)) = inf;
        
        %select subplot
        subplot(numRow,numCol,m)
        
        %add image
        imagesc(model);
        
        %add condition names
        set(gca,'ytick',1:length(conditionNames_use),'yticklabel',strrep(conditionNames_use,'_','-'),'xtick',[])
        
        %set square
        axis square
        
        %colour axis
        caxis([-1 +1.05]);
        colorbar
        
        %set colours
        colormap(cmap);
        
        %model name
        name = p.MODELS.names{m};
        name(name=='_') = ' ';
        if averaged
            name = [name ' (avg of indiv)'];
        end
        title(name);
        if ~isnan(FONT_SIZE)
            set(gca,'fontsize',4);
        end
        
    end
    suptitle([splitNames{split} ': excluded cells are set black'])
    %saveas(fig,['Models_' splitNames{split} '.png'],'png')
    print('-dpng','-r500',['Models_' splitNames{split} '.png'])
end
close(fig)