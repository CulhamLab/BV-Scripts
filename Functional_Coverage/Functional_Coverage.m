function Functional_Coverage

%% Parameters

%path
folder = 'put_path_here';

%IDs
sub_ids = arrayfun(@(x) sprintf('SUB%02d', x), 1:15, 'UniformOutput', false);
run_ids = arrayfun(@(x) sprintf('RUN%02d', x), 1:2, 'UniformOutput', false);

%[SUB] and [RUN] are automatically filled with IDs above
vtc_filename_format = '[SUB]_[RUN]_*.vtc';
%data is in participant subdirectories
SUBDIR = true;

%filepath for output
fp_output_vmp = 'Functional_Coverage.vmp';

%% Script

if folder(end) ~= filesep
    folder(end+1) = filesep;
end

num_sub = length(sub_ids);
num_run = length(run_ids);

fields_to_copy = {'XStart'
                  'XEnd'
                  'YStart'
                  'YEnd'
                  'ZStart'
                  'ZEnd'
                  'Resolution'};
              
vmp = xff('vmp');
vmp_initialized = false;

fprintf('Folder: %s\n', folder)

for sub = 1:num_sub
    sub_id = sub_ids{sub};
    fprintf('Sub %d of %d: %s\n', sub, num_sub, sub_id);
    
    if vmp_initialized
        any_vol_missing_sub = false(sz);
    end
    
    if SUBDIR
        sub_folder = [folder sub_id filesep];
    else
        sub_folder = folder;
    end
    
    for run = 1:num_run
        run_id = run_ids{run};
        fprintf('  Run %d of %d: %s\n', run, num_run, run_id);
        
        fn = strrep(strrep(vtc_filename_format, '[SUB]', sub_id), '[RUN]', run_id);
        fprintf('    Search: %s\n', fn);
        
        list = dir([sub_folder fn]);
        if ~length(list)
            warning('VTC not found! Skipping!')
			continue
        elseif length(list)>1
            warning('More than 1 VTC found for search criteria! Skipping!')
			continue
        else
            fprintf('      VTC: %s\n', list.name);
            
            fp = [sub_folder list.name];
            vtc = xff(fp);
            
            if ~vmp_initialized
                vmp_initialized = true;
                
                for i = 1:length(fields_to_copy)
                    field = fields_to_copy{i};
                    eval(sprintf('vmp.%s = vtc.%s;', field, field))
                end

                sz = size(vtc.VTCData);
                any_vol_missing_sub = false(sz);

                vmp.Map(1).Name = 'total volumes missing';
                vmp.Map(1).LowerThreshold = 0;
                vmp.Map(1).VMPData = single(zeros(sz(2:4)));

                vmp.Map(2) = vmp.Map(1);
                vmp.Map(2).Name = 'total runs with any volume missing';

                vmp.Map(3) = vmp.Map(1);
                vmp.Map(3).Name = 'total subs with any volume missing in any run';
            end
            
            if any(sz ~= size(vtc.VTCData))
                error('VTC dimensions are not consistent!')
            end
            
            missing = single(isnan(vtc.VTCData) | (vtc.VTCData == 0));
            missing = squeeze(sum(missing,1));
            
            vmp.Map(1).VMPData = vmp.Map(1).VMPData + missing;
            vmp.Map(2).VMPData(missing>0) = vmp.Map(2).VMPData(missing>0) + 1;
            any_vol_missing_sub(missing>0) = true;
            
            vtc.ClearObject;
        end
    end
    
    vmp.Map(3).VMPData(any_vol_missing_sub) = vmp.Map(3).VMPData(any_vol_missing_sub) + 1;
end       

num_maps = length(vmp.Map);
vmp.NrOfMaps = num_maps;
for map = 1:num_maps
    m = max(vmp.Map(map).VMPData(:));
    if m==0
        vmp.Map(map).UpperThreshold = 1;
    else
        vmp.Map(map).UpperThreshold = m;
    end
end
vmp.SaveAs(fp_output_vmp);
vmp.ClearObject;