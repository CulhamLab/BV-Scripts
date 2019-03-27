% Old Method (correct, but memory-intensive)
% 1. load in [VOX x PRED] betas for each run to create [VOX x PRED x RUN] beta matrix
% 2. for each voxel, subtract out the [PRED x RUN] average
% 3. average across runs

% New Method (memory usage is approx #runs/3 to #runs/2 times less)
% 1. initialize a [VOX x PRED] matrix of betas sums and a [VOX x PRED] matrix of beta counts
% 2. load runs one at a time, add loaded betas to the sum matrix and tally non-zero values in count matrix
% 3. calculate [VOX x PRED] run-average as sum ./ count
% 4. perform weighted demean (if not weighted, then the output would be incorrect when any value is missing)
%    a) calculate [VOX x PRED] matrix of weighted voxel-predictor means as (run-average * count / voxel's total count)
%    b) calculate [VOX] array of weighted voxel means as the sum of (a) across predictors
%    c) subtract out the weighted voxel means from the run-averages

% function compare_demean_average_methods

%% parameters
PREDICTORS = 61;
RUNS = 8;
VOXELS = 1000;
BETA_RANGE = [-3 +3];

PERCENT_VOXELS_MISSING = 10;
PERCENT_EXTRA_BETAS_MISSING = 15;

% What to do when a voxel has data, but is missing one or more betas for a predictor in a run
% IGNORE   - ignore the missing values and use any remaining values 
% STOP     - throw a MATLAB error
% BALANCED - stop unless the number of non-zero values in even runs matches
%            the number of non-zero values in odd runs (a warning will still
%            be displayed in the command window)
MISSING_BETA_ACTION = 'BALANCED';

%% create test data for one participant

%create random data
allBetas = (rand(VOXELS, PREDICTORS, RUNS) * range(BETA_RANGE)) + min(BETA_RANGE);

%set some voxels to always zero (never any functional data - occurs in corners of bounding box when slices are angled)
if PERCENT_VOXELS_MISSING>0
    ind_voxel_missing = randperm(VOXELS, ceil(PERCENT_VOXELS_MISSING / 100 * VOXELS));
    allBetas(ind_voxel_missing,:,:) = 0;
end

%set some betas to zero in a run (can happen when a run does not have a condition
%occur or if somehow a functional voxel has no data in a run)
if PERCENT_EXTRA_BETAS_MISSING>0
    ind_beta_missing = randperm(numel(allBetas), ceil(PERCENT_EXTRA_BETAS_MISSING / 100 * numel(allBetas)));
    allBetas(ind_beta_missing) = 0;
end

allBetas_backup = allBetas;

%% old method
allBetas(allBetas==0) = nan;

ind_even = 2:2:RUNS;
ind_odd = 1:2:RUNS;

evenBetas = allBetas(:,:,ind_even);
oddBetas = allBetas(:,:,ind_odd);

%all
meanVector = nanmean(nanmean(allBetas,3),2);
meanMat = repmat(meanVector,[1 PREDICTORS RUNS]);
old_result.allBetas_MeanAcrossRun = nanmean(allBetas - meanMat,3);

%odd
meanVector = nanmean(nanmean(oddBetas,3),2);
meanMat = repmat(meanVector,[1 PREDICTORS ceil(RUNS/2)]);
old_result.oddBetas_MeanAcrossRun = nanmean(oddBetas - meanMat,3);

%even
meanVector = nanmean(nanmean(evenBetas,3),2);
meanMat = repmat(meanVector,[1 PREDICTORS floor(RUNS/2)]);
old_result.evenBetas_MeanAcrossRun = nanmean(evenBetas - meanMat,3);

%% clear/restore for next method
allBetas = allBetas_backup;
clearvars -except PREDICTORS RUNS VOXELS BETA_RANGE allBetas old_result

%% new method (requires much less memory)

%initialize sum/count matrices
odd_sum = zeros(VOXELS, PREDICTORS, 'double');
odd_count = zeros(VOXELS, PREDICTORS, 'single');
even_sum = zeros(VOXELS, PREDICTORS, 'double');
even_count = zeros(VOXELS, PREDICTORS, 'single');

%add runs one at a time (only one run would need to be in memory at any time)
for run = 1:RUNS
    %is run even or odd?
    is_odd = mod(run, 2);
    
    %simulate loading data
    run_data = allBetas(:,:,run);
    
    %set loaded nan to zero
    run_data(isnan(run_data)) = 0;
    
    %add data
    if is_odd
        odd_sum = odd_sum + run_data;
        odd_count = odd_count + single(run_data~=0);
    else
        even_sum = even_sum + run_data;
        even_count = even_count + single(run_data~=0);
    end
end

%combine even and odd runs for the all run set
all_sum = odd_sum + even_sum;
all_count = odd_count + even_count;

%check which voxels have no data


%%
old_result.allBetas_MeanAcrossRun - all_mean_demeaned