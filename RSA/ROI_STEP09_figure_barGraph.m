function ROI_STEP9_figure_barGraph

%params
p = ALL_STEP0_PARAMETERS;

%paths
readFolA = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '6. ROI RSMs' filesep];
readFolB = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '7. ROI Model Correlations' filesep];
saveFol = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '9. Bar Graphs' filesep];

%create saveFol
if ~exist(saveFol)
    mkdir(saveFol)
end

%load
load([readFolA 'VOI_RSMs'])
load([readFolB 'VOI_corrs'])

%split?
if p.VOI_USE_SPLIT
    split_type = 'split';
    data_use = corrs_split;
else
    split_type = 'nonsplit';
    data_use = corrs_nonsplit;
end

%range
temp = nanmean(data_use,1);
ran = [min(temp(:)) max(temp(:))];
ran = [ran(1)-(range(ran)*0.1) ran(2)+(range(ran)*0.1)];

%fig
fig = figure('Position', get(0,'ScreenSize'));

%% for each roi

%colours
cs= jet(length(p.MODELS.names));

%how many row/col
r=0;
c=0;
while (r*c)<(length(voi_names))
    if r==c
        r=r+1;
    else
        c=c+1;
    end
end
r=r+3;

%plot
for voi = 1:length(voi_names)
    name = voi_names{voi};
    name(name=='_') = ' ';
    subplot(r,c,voi)
    corrs = nanmean(data_use(:,:,voi),1);
    hold on
    for i = 1:length(corrs)
        b(i) = bar(i,corrs(i));
        set(b(i), 'FaceColor', cs(i,:));
    end
    hold off
    set(gca,'xtick',[]);
    v=axis;
    axis([v(1:2) ran]);
    title(name);
end

%legend
l_all = cellfun(@(x) strrep(x,'_',' '),p.MODELS.names,'UniformOutput',false);
if length(l_all)<=10
    l = l_all;
    voi = ((r-2) * c) + round(c/2);
    s = subplot(r,c,voi);
    axis off
    legend(s,b,l)
else
    h = round(length(l_all)/2);
    
    l = l_all(1:h);
    voi = ((r-2) * c) + round(c/2);
    s = subplot(r,c,voi);
    axis off
    legend(s,b(1:h),l);
    
    l = l_all(h+1:end);
    voi = ((r-2) * c) + round(c/2) + 1;
    s = subplot(r,c,voi);
    axis off
    legend(s,b(h+1:end),l);
end

t = ['Mean Model Correlation For Each VOI (' split_type ')'];
suptitle(t);

saveas(fig,[saveFol t],'png')

%%
clf
clear b

%% for each model

%colours
cs= jet(length(voi_names));

%how many row/col
r=0;
c=0;
while (r*c)<(length(p.MODELS.names))
    if r==c
        r=r+1;
    else
        c=c+1;
    end
end
r=r+3;

%plot
for m = 1:length(p.MODELS.names)
    name = p.MODELS.names{m};
    name(name=='_') = ' ';
    subplot(r,c,m)
    corrs = nanmean(data_use(:,m,:),1);
    hold on
    for i = 1:length(corrs)
        b(i) = bar(i,corrs(i));
        set(b(i), 'FaceColor', cs(i,:)) 
    end
    hold off
    set(gca,'xtick',[]);
    v=axis;
    axis([v(1:2) ran]);
    title(name)
end

%legend
l_all = cellfun(@(x) strrep(x,'_',' '),voi_names,'UniformOutput',false);
if length(l_all)<=10
    l = l_all;
    m = ((r-2) * c) + round(c/2);
    s = subplot(r,c,m);
    axis off
    legend(s,b,l)
else
    h = round(length(l_all)/2);
    
    l = l_all(1:h);
    m = ((r-2) * c) + round(c/2);
    s = subplot(r,c,m);
    axis off
    legend(s,b(1:h),l)
    
    l = l_all(h+1:end);
    m = ((r-2) * c) + round(c/2) + 1;
    s = subplot(r,c,m);
    axis off
    legend(s,b(h+1:end),l)
end

t = ['Mean Model Correlation For Each Model (' split_type ')'];
suptitle(t);

saveas(fig,[saveFol t],'png')

%% done
close(fig)
close all
disp 'Done.'