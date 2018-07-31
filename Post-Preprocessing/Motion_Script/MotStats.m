function MotStats(filename) %Motion Stats
% close all

% filename = 'SUB01';
load([pwd '\Output(mat)\' filename '_motionparams'])

fol_mat = [pwd filesep 'Output(mat)' filesep];
fol_img = [pwd filesep 'Output(png)' filesep];

%Raw XYZ is used to create a "XYZ" (position) value equal to the euclidean
%distance from [0 0 0] and a "deltaXYZ" (translation) value equal to the
%euclidian distance between each volume and the prior volume;

%Raw rotation is usd to create "meanRotation" (angle) value
%equal to mean of X, Y, and Z rotation. deltaRotation (rotation) equals the
%difference between meanRotation for each volume and the prior volume.

%initialize
numRuns = length(x);
deltaXYZ = [];
XYZ = [];
meanRotation = [];
vals = [];
runStart = [];

%calculate values
for i = 1:numRuns
    runStart = [runStart length(XYZ) + 1];%first volume of each run
    if length(x{i})
        val = [x{i} y{i} z{i} rx{i} ry{i} rz{i}];
        vals = [vals; val];
        
        %deltaXYZ = [deltaXYZ 0];
        XYZ = [XYZ pdist([val(1,1:3); 0 0 0])];
        for ii = 2:length(x{i})
            %deltaXYZ = [deltaXYZ pdist([val(ii,1:3); val(ii-1,1:3)])];
            XYZ = [XYZ pdist([val(ii,1:3); 0 0 0])];
        end
        meanRotation =[meanRotation mean(abs(val(:,4:6)),2)'];
    end
end
deltaXYZ = [0 (XYZ(2:end) - XYZ(1:end-1))];
deltaXYZ(runStart) = 0;
deltaRotation = [0 (meanRotation(2:end)-meanRotation(1:end-1))];
deltaRotation(runStart) = 0;

%for figures
len = 1:length(vals(:,1));
fig = figure('Position', [1 1 5000 2000]); %get(0,'ScreenSize')); 

%find the volume alligned to
volAligned = runStart(find(XYZ(runStart)==0)); %XYZ is exactly 0 here
if length(volAligned) > 1
    volAligned = length(vals(:,1)) * 2; %offscreen
end

%remove '_' from searchfor
for i = 1:length(searchfor)
    searchforUsed{i} = searchfor{i}(searchfor{i}~='_');
end

%raw figure 1
subplot(4,1,1)
plot(len,vals(:,1),'r',len,vals(:,2),'g',len,vals(:,3),'b')
a = axis;
hold on
for r = 1:length(runStart)
    i = runStart(r);
    plot([i i],[a(3) a(4)],'k')
    text(i,a(3) + range(a(3:4))*0.03,searchforUsed{r})
end
text(volAligned,a(4) - range(a(3:4))*0.04,'Alignment Volume','Color','m')
hold off
legend({'X','Y','Z'}, 'Location', 'EastOutside')
ylabel('mm/deg')
xlabel('Volumes')
title('Raw Position')


%raw figure 2
subplot(4,1,2)
plot(len,vals(:,4),'r',len,vals(:,5),'g',len,vals(:,6),'b')
a = axis;
hold on
for r = 1:length(runStart)
    i = runStart(r);
    plot([i i],[a(3) a(4)],'k')
    text(i,a(3) + range(a(3:4))*0.03,searchforUsed{r})
end
text(volAligned,a(4) - range(a(3:4))*0.04,'Alignment Volume','Color','m')
hold off
legend({'Rotation X','Rotation Y','Rotation Z'}, 'Location', 'EastOutside')
ylabel('mm/deg')
xlabel('Volumes')
title('Raw Rotation')

%position figure
subplot(4,1,3)
plot(len,XYZ,'b',len,meanRotation,'g')
a = axis;
hold on
for r = 1:length(runStart)
    i = runStart(r);
    plot([i i],[a(3) a(4)],'k')
    text(i,a(3) + range(a(3:4))*0.03,searchforUsed{r})
end
text(volAligned,a(4) - range(a(3:4))*0.04,'Alignment Volume','Color','m')
hold off
legend({'Position (euclidean distance)','Angle (mean of absolutes)'}, 'Location', 'EastOutside')
xlabel('Volumes')
ylabel('mm/deg')
title('Location')

%motion figure
subplot(4,1,4)
plot(len,deltaXYZ+0.5,'b',len,deltaRotation-0.5,'g')
a = axis;
hold on
for r = 1:length(runStart)
    i = runStart(r);
    plot([i i],[a(3) a(4)],'k')
    text(i,a(3) + range(a(3:4))*0.03,searchforUsed{r})
end
text(volAligned,a(4) - range(a(3:4))*0.04,'Alignment Volume','Color','m')
hold off
legend({'Translation (centered on 0.5)','Rotation (centered on -0.5)'}, 'Location', 'EastOutside')
xlabel('Volumes')
ylabel('mm/deg')
title('Motion Per Volume')

saveas(fig,[fol_img filename '_params.png'],'png')

%% Parameters
%motionPerVolumeToWarrantSpikeSearch = mean(abs(deltaXYZ)) + std(abs(deltaXYZ))*5; %if any volumes exceed this much motion, do a search for spikes (cluster analysis)
%could have a set number here instead

motionPerVolumeToWarrantSpikeSearch = 0.35; %mm/volume
distanceToFlagSustainedChange = 0.35;

%% Stats
spikes = [];
spikeWithSustainedChange = [];
sustainedChange = [];

%motion per volume
for run = 1:numRuns
    if run ~= numRuns
        rng = runStart(run):runStart(run+1)-1;
    else
        rng = runStart(run):length(vals(:,1));
    end
    mpvByRun(run) = max(abs(deltaXYZ(rng)));
    rangeByRun(run) = range(XYZ(rng));
    
    if mpvByRun(run) > motionPerVolumeToWarrantSpikeSearch
%         %cluster analysis worked just as well, but it's not as simple.
%         Z = linkage(abs(deltaXYZ(rng)'));
%         T = cluster(Z,'MaxClust',2); %could use more clusters
%         safeVal = T(find(deltaXYZ(rng)==min(deltaXYZ(rng)),1));
%         spikes = [spikes (find(T~=safeVal)+runStart(run)-1)'];
        newSpikes = (find(abs(deltaXYZ(rng)) > motionPerVolumeToWarrantSpikeSearch)+runStart(run)-1);
        spikes = [spikes newSpikes];
        
        for spk = newSpikes            
            if (spk < (max(rng)-10)) & (spk > (min(rng)+10))
                before = mean(XYZ(spk-10:spk-1));
                after = mean(XYZ(spk+1:spk+10));
                if abs(before-after) > distanceToFlagSustainedChange
                    spikeWithSustainedChange = [spikeWithSustainedChange spk];
                    sustainedChange(spk) = abs(before-after);
                end
            end
        end
    end
    sumMvt(run) = sum(abs(deltaXYZ(rng)));
end

disp 'Run - Ranges (mm):'
disp([(1:numRuns)' rangeByRun'])
disp 'Run - Max Motion Per Volume (mm, absolute)'
disp([(1:numRuns)' mpvByRun'])
disp 'Run - Sum of all movement (mm, absolute):'
disp([(1:numRuns)' sumMvt'])
disp 'Session - Range (mm):'
disp(range(XYZ))
disp 'Session - Max Motion Per Volume (mm, absolute)'
disp(max(mpvByRun'))
disp 'Session - Sum of all movement (mm, absolute)'
disp(sum(sumMvt))
disp(sprintf('Spikes (criteria: |translation| > %03fmm)',motionPerVolumeToWarrantSpikeSearch))
disp(sprintf('    Run-Vol  Motion(mm)'))
for spike = spikes
    %which run
    run = max(find(runStart<=spike));
    runvol = spike - runStart(run) + 1;
    disp(sprintf('    %d-%d  %03f',run,runvol,deltaXYZ(spike)))
end
disp(sprintf('\nSpikes resulting in sustained position change (criteria: |mean10VolBefore-mean10VolAfter| > %03fmm)',distanceToFlagSustainedChange))
disp(sprintf('    Run-Vol  Difference(mm)'))
for spike = spikeWithSustainedChange
    %which run
    run = max(find(runStart<=spike));
    runvol = spike - runStart(run) + 1;
    disp(sprintf('    %d-%d  %03f',run,runvol,sustainedChange(spike)))
end
disp ' '

%% Graph
% fig = figure('Position', get(0,'ScreenSize')); 
clf
hold on
main = plot([XYZ' abs(deltaXYZ)']);
a = axis;
for r = 1:length(runStart)
    i = runStart(r);
    plot([i i],[a(3) a(4)],'k')
    text(i,a(4) - range(a(3:4))*0.03,searchforUsed{r})
end
spkWSV = plot([0 0],[0 0],'y');
for i = spikeWithSustainedChange'
    for ii = i-10:i+10
        spkWSV = plot([ii ii],[a(3) a(4)],'y');
    end
end
spk = plot([0 0],[0 0],'r:'); %makes legend command work
for spike = spikes'
    spk = plot([spike spike],[a(3) a(4)],'r:');
end
plot([XYZ' abs(deltaXYZ)']); %first time gives axies, second writes over lines
set(gca,'XTick',[]);
if (length(filename)>3) && (filename(1:3) == 'SUB')%sara's
    i = [];
    ii = [];
    for r = 1:length(runStart)
        try
            load(sprintf('C:\\Users\\kstubbs4\\Dropbox\\Grasp Taxonomy project overview\\code 280113\\SelectedResultsGraspTax_SUB%s_RUN%d',filename(4:5),r));
        catch
            continue
        end
        start = round(DataToSave(1,3)/2);
        fin = round(DataToSave(end,4)/2);
        i = [i (runStart(r) + start)];
        i = [i (runStart(r) + fin)];
        ii = [ii start fin];
        plot([start start]+runStart(r),[a(3) a(4)],':k')
        plot([fin fin]+runStart(r),[a(3) a(4)],':k')
    end
    set(gca,'XTick',i,'XTickLabel',ii);
end
ylabel('mm')
xlabel('Volumes')
title('Motion Analysis')
legend([main',spk(1),spkWSV(1)],'Position (euclidean distance)','Translation/Volume (absolute)','Motion Spike','Spike with sustained change')
hold off
saveas(fig,[fol_img filename '_spikes.png'],'png')

%Histagram of motion
% fig = figure('Position', get(0,'ScreenSize')); 
clf
subplot(2,1,1)
hist(deltaXYZ)
ylabel('# Volumes')
xlabel('Translation/Volume (mm)')
subplot(2,1,2)
hist(deltaRotation)
ylabel('# Volumes')
xlabel('Rotation/Volume (deg)')
saveas(fig,[fol_img filename '_hist.png'],'png')

close(fig)

%save variables
filename = [fol_mat filename '_motionanalyzed'];
save(filename,'x','y','z','rx','ry','rz','vals','orderedNames','searchfor','XYZ','deltaXYZ','spikes','deltaRotation','volAligned','meanRotation','rangeByRun','mpvByRun','runStart','sumMvt')
