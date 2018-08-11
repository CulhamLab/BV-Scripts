%Works only if models contain only NaN and 2 non-nan values (e.g., 0 and 1)
function aux_createModelFigure(useConditionNames)

%default to using condition names
if ~exist('useConditionNames')
    useConditionNames = true;
end

%font size
FONT_SIZE = 4; %nan to leave as automatic

%colors
COLOUR_HIGH = [0 1 0];
COLOUR_LOW = [1 0 0];
COLOUR_EXCLUDED = [0 0 0];

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
cmap = [COLOUR_EXCLUDED; COLOUR_LOW; COLOUR_HIGH];

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
        switch split
            case 1
                model = p.MODELS.matrices{m};
            case 2
                model = p.MODELS.matricesNonsplit{m};
        end
        
        %set nans to -1
        model(isnan(model)) = -1;
        
        %select subplot
        subplot(numRow,numCol,m)
        
        %add image
        imagesc(model);
        
        %add condition names
        set(gca,'ytick',1:length(conditionNames),'yticklabel',conditionNames,'xtick',[])
        
        %set square
        axis square
        
        %colour axis
        caxis([-1 1]);
        
        %set colours
        colormap(cmap);
        
        %model name
        name = p.MODELS.names{m};
        name(name=='_') = ' ';
        title(name);
        if ~isnan(FONT_SIZE)
            set(gca,'fontsize',4);
        end
        
    end
    suptitle([splitNames{split} ': Green=high, Red=low, Black=exclude'])
    %saveas(fig,['Models_' splitNames{split} '.png'],'png')
    print('-dpng','-r500',['Models_' splitNames{split} '.png'])
end
close(fig)