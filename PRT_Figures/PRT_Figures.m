function PRT_Figures

%% Parameters
NUMBER_VOLUMES = 340;
X_TICK_DISTANCE = 10;

%% Select Files
file_list = dir('*.prt');
number_files = length(file_list);
if ~number_files
    error('No PRT files found')
end

%% Generate Figures
fig = figure('Position',get(0,'screensize'));
for i = 1:number_files
    fn = file_list(i).name;
    fprintf('Processing %d of %d: %s\n', i, number_files, fn);
    
    fn_out = strrep(fn, '.prt', '.png');
    if exist(fn_out, 'file')
        warning('File already exists and will NOT be overwritten: %s', fn_out)
    end
    
    prt = xff(fn);
    
    clf
    
    axis([1 NUMBER_VOLUMES 0 1]);
    set(gca,'ytick',[],'xtick',1:X_TICK_DISTANCE:NUMBER_VOLUMES)
    xlabel('Volumes')
    
    hold on
    
    rectangle('Position', [1 0 NUMBER_VOLUMES 1], 'FaceColor', 'k', 'EdgeColor', 'k');
    r(1) = plot(0,0,'LineWidth',10,'Color','k');
    name{1} = 'Baseline';
    
    colours = jet(prt.NrOfConditions);
    for p = 1:prt.NrOfConditions
        name{1+p} = prt.Cond(p).ConditionName{1};
        r(1+p) = plot(0,0,'LineWidth',10,'Color',colours(p,:));
        for j = 1:prt.Cond(p).NrOfOnOffsets
            rectangle('Position', [prt.Cond(p).OnOffsets(j,1) 0 (range(prt.Cond(p).OnOffsets(j,:))+1) 1], 'FaceColor', colours(p,:), 'EdgeColor', colours(p,:));
        end
    end
    
    for x = get(gca, 'xtick')
        plot([x x],[0 1],':','Color',[0.5 0.5 0.5]);
    end
    
    hold off
    
    legend(r, name, 'Location', 'EastOutside');
    
    title(strrep(fn,'_','\_'))
    
    saveas(fig, fn_out, 'png')
    
    prt.ClearObject;
    clear prt;
end
close(fig);