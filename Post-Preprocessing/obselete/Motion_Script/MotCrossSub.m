function MotCrossSub(search)

search = 'SUB';
list = dir([pwd '\Output(mat)\' search '*_motionanalyzed.mat']);

for sub = 1:length(list)
    load([pwd '\Output(mat)\' list(sub).name])
    ranges(sub,1:length(rangeByRun)) = rangeByRun;
    mvp(sub,1:length(mpvByRun)) = mpvByRun;
    sumMvts(sub,1:length(sumMvt)) = sumMvt;
    
    maxes(sub,:) = [max(rangeByRun) max(mpvByRun) max(sumMvt)];
end

ranges(~ranges) = nan;
mvp(~mvp) = nan;
sumMvts(~sumMvts) = nan;

disp(sprintf('Max range: %fmm', max(maxes(:,1))))
disp(sprintf('Max motion per volume: %fmm', max(maxes(:,2))))
disp(sprintf('Max motion/run: %fmm', max(maxes(:,3))))

end