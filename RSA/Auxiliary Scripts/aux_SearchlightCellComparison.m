%%%%% What this script does:
% 1. For each test, for each searchlight sphere, for each participant:
%       calculate the nanmeans of two subsets of RSM cells
%
% 2. For each test, for each searchlight sphere:
%       perform a paired-samples t-test comparing the means from the two subsets
%
% 3. Create a VMP with 2 maps for each test:
%       [t-value map] with a default threshold of t>3
%       [one-minus-p map] with a default threshold of one-minus-p>0.95 (i.e., p < 0.05)
%       Note: use [BV-Scripts\VMP_Apply_FDR] to change these thresholds to FDR
%
%
%%%%% Requirements (in addition to NeuroElf)
% 1. Run [SEARCHLIGHT_STEP06_createRSMs.m] to calcualte the sphere RSMs
%
% 2. Define one or more cell comparisons in a single excel file following
%       the example in [aux_SearchlightCellComparison_Example.xlsx]
%       * the order must match [CONDITIONS.PREDICTOR_NAMES]
%       * one sheet per cell comparison, the sheet name will be used for labels
%       * populate conditions-condition cells with 1s, 0s, or leave empty to exclude
%       * the values must begin in cell (2,2)
%       * Note: in a right- or both-tailed test, a positive t-value indicates 1-cells > 0-cells

%% Specific Parameters

OUTPUT_SUFFIX = 'Example';
EXCEL_FILEPATH = 'aux_SearchlightCellComparison_Example.xlsx';
EXCEL_SHEETS = {'Diagonal' , 'RedGreen'};
TTEST_TAIL = 'right'; %right, left, or both
MINIMUM_NUMBER_PARTICIPANTS = 5; %min number of participants with data to run a sphere



%% ******* SHOULD NOT NEED TO EDIT BELOW THIS POINT *******



%% Get Main Parameters

returnPath = pwd;
try
    cd ..
    p = ALL_STEP0_PARAMETERS;
    cd(returnPath)
catch
    cd(returnPath)
    error('Failed to get RSA parameters')
end

if p.SEARCHLIGHT_USE_SPLIT
    split_suffix = '_SPLIT';
else
    split_suffix = '_NONSPLIT';
end

%% Delete Existing Outputs

output_mat = [mfilename '_' OUTPUT_SUFFIX split_suffix '.mat'];
output_vmp = [mfilename '_' OUTPUT_SUFFIX split_suffix '.vmp'];

if exist(output_mat, 'file')
    delete(output_mat)
end

if exist(output_vmp, 'file')
    delete(output_vmp)
end

%% Prepare Cell Comparisons

number_comparisons = length(EXCEL_SHEETS);
comparisons = [];
for c = 1:number_comparisons
    %load from excel
    [~,~,xls] = xlsread(EXCEL_FILEPATH, EXCEL_SHEETS{c});

    %excel data is large enough?
    if any(size(xls) < p.NUMBER_OF_CONDITIONS)
        error('[%s] does not contain enough rows and/or columns (should be at least 1 + NUMBER_OF_CONDITIONS)', EXCEL_SHEETS{c})
    end

    %get matrix
    matrix = cell2mat(xls(2:1+p.NUMBER_OF_CONDITIONS, 2:1+p.NUMBER_OF_CONDITIONS));

    %matrix values make sense?
    if any(~isnan(matrix(:)) & ~(matrix(:)==1) & ~(matrix(:)==0))
        error('[%s] matrix area contains values other than 1, 0, and empty/NaN', EXCEL_SHEETS{c})
    end

    %store values
    comparisons(c).Name = EXCEL_SHEETS{c};
    comparisons(c).Matrix = matrix;
    comparisons(c).Select(:,:,1) = matrix==1;
    comparisons(c).Select(:,:,2) = matrix==0;    
end

%% Load Participant 1 Part 1 for settings

input_dir = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_SEARCHLIGHT_DATA filesep '6. 3D Matrices of RSMs' filesep];

fprintf('-Loading participant 1, part 1 and initializing...\n');
step6 = load(sprintf('%sstep6_RSMs_%s_PART%02d%s.mat', input_dir, p.FILELIST_PAR_ID{1}, 1, split_suffix));
runtime = step6.runtime;
ss_ref = step6.ss_ref;
vtcRes = step6.vtcRes;
number_parts = step6.number_parts;

%valid version?
if ~isfield(step6, 'runtime') || ~isfield(step6.runtime, 'Step6') || step6.runtime.Step6.VERSION<1
    error('The odd//even split method has been improved. Rerun from step 6.')
end

%need to convert from squareform?
convert_sf_rsms = false;
if ~step6.usedSplit
    ind_first = find(~cellfun(@isempty, step6.RSMs), 1, 'first');
    if size(step6.RSMs{ind_first},1) == 1
        convert_sf_rsms = true;
    end
end

%% Initialize Output Matrices

for c = 1:number_comparisons
    comparisons(c).cell_means = repmat({nan([p.NUMBER_OF_PARTICIPANTS 2])}, ss_ref);
    comparisons(c).tvalues = nan(ss_ref);
    comparisons(c).pvalues = nan(ss_ref);
end

%% Run 

%calculate the cell subset means...
for par = 1:p.NUMBER_OF_PARTICIPANTS
    fprintf('\nRunning participant %g of %g...\n',par,p.NUMBER_OF_PARTICIPANTS)
    clearvars -except par p input_dir ss_ref vtcRes split_suffix convert_sf_rsms number_parts runtime comparisons number_comparisons TTEST_TAIL MINIMUM_NUMBER_PARTICIPANTS output_mat output_vmp

    %process each part
    for part = 1:number_parts
        fprintf('-Processing part %d of %d...\n', part, number_parts);
        
        %load
        step6 = load(sprintf('%sstep6_RSMs_%s_PART%02d%s.mat', input_dir, p.FILELIST_PAR_ID{par}, part, split_suffix));
    
        %check size
        if any(step6.ss_ref ~= ss_ref)
            error('Size is not constant (ss_ref)!')
        end
	    
	    %check vtcRes
        if any(step6.vtcRes ~= vtcRes)
            error('VTC resolution is not constant (vtcRes)!')
        end
	    
	    %check usedSplit
	    if (step6.usedSplit ~= p.SEARCHLIGHT_USE_SPLIT)
		    error('Split is not constant (usedSplit)!')
        end
        
        %check number_parts
        if (step6.number_parts ~= number_parts)
            error('Number of parts is not constant (number_parts)!')
        end
        
        %convert squareform rdms back to RSMs (may stored this way in nonsplit mode to save time/space)
        if convert_sf_rsms
            ind = find(~cellfun(@isempty, step6.RSMs));
            step6.RSMs(ind) = cellfun(@(x) 1 - squareform(x), step6.RSMs(ind), 'UniformOutput', false);
        end

        %loop through part voxels
        for i = step6.indxVoxWithData_part'
            %has result in this sphere?
            if ~isempty(step6.RSMs{i})

                %for each test...
                for c = 1:number_comparisons
                    %calculate nanmean of cell subset
                    for subset = 1:2
                        comparisons(c).cell_means{i}(par,subset) = nanmean(step6.RSMs{i}(comparisons(c).Select(:,:,subset)));
                    end
                end
            end
        end
    end
end


%% Run t-tests

for c = 1:number_comparisons
    fprintf('\nPerforming t-tests for comparison %d of %d: %s\n', c, number_comparisons, comparisons(c).Name);

    for vox = 1:prod(ss_ref)
        %get subset means
        means = comparisons(c).cell_means{vox};

        %remove participants with NaN for either subset
        means(any(isnan(means),2),:) = [];

        %skip if less than [MINIMUM_NUMBER_PARTICIPANTS] participants
        if size(means,1) < MINIMUM_NUMBER_PARTICIPANTS
            continue
        end

        %otherwise... run t-test
        [~,pval,~,stats] = ttest(means(:,1), means(:,2), 'Tail', TTEST_TAIL);

        %store results
        comparisons(c).tvalues(vox) = stats.tstat;
        comparisons(c).pvalues(vox) = pval;
    end
end

%% Save Mat

fprintf('Saving mat: %s\n', output_mat);
save(output_mat, 'comparisons', 'number_comparisons', 'p', 'MINIMUM_NUMBER_PARTICIPANTS', 'TTEST_TAIL')

%% Create VMP

fprintf('Saving vmp: %s\n', output_vmp);

%initialize vmp
vmp = xff('vmp');

%bounding box (defined from params)
for f = fields(p.BBOX)'
    eval(['vmp.' f{1} ' = p.BBOX.' f{1} ';'])
end

%resolution (changing this SHOULD work)
vmp.Resolution = vtcRes;

%apply [LAST_DITCH_EFFORT_VMP_FIX] if needed
if p.LAST_DITCH_EFFORT_VMP_FIX
    vmp.XEnd = vmp.XEnd+vmp.Resolution;
    vmp.YEnd = vmp.YEnd+vmp.Resolution;
    vmp.ZEnd = vmp.ZEnd+vmp.Resolution;
end

%add maps...
map_ind = 0;
for c = 1:number_comparisons
    for type = ['t' 'p']
        switch type
            case 't'
                map_type = 1;
                show_pos_neg = 3;
                df1 = p.NUMBER_OF_PARTICIPANTS - 1;
                df2 = 0;
                type_label = 't-value';
                map = comparisons(c).tvalues;
                default_thresh_min = 3;
                default_thresh_max = 8;
            case 'p'
                map_type = 16;
                show_pos_neg = 1;
                df1 = 0;
                df2 = 0;
                type_label = 'one-minus-p';
                map = 1 - comparisons(c).pvalues;
                default_thresh_min = 0.95;
                default_thresh_max = 1.00;
            otherwise
                error('Undefinied')
        end

        %map index in vmp
        map_ind = map_ind + 1;
        vmp.Map(map_ind) = vmp.Map(1);

        %map name
        vmp.Map(map_ind).Name = sprintf('%s: %s', comparisons(c).Name, type_label);

        %default thresholds
        vmp.Map(map_ind).LowerThreshold = default_thresh_min;
        vmp.Map(map_ind).UpperThreshold = default_thresh_max;

        %map
        vmp.Map(map_ind).VMPData = map;

        %show pos and neg
        vmp.Map(map_ind).ShowPositiveNegativeFlag = show_pos_neg;

        %number of voxels for bonf
        vmp.Map(map_ind).BonferroniValue = sum(vmp.Map(map_ind).VMPData(:) ~= 0 & ~isnan(vmp.Map(map_ind).VMPData(:)));

        %map type
        vmp.Map(map_ind).Type = map_type;

        %degrees of freedom
        vmp.Map(map_ind).DF1 = df1;
        vmp.Map(map_ind).DF2 = df2;
    end
end

%number of maps
vmp.NrOfMaps = map_ind;

%save vmp
vmp.SaveAs(output_vmp);

%% Done!

disp Done!