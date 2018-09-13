function Merge_VOI_DiffTypes

%% Parameters
fields_compare = {'ReferenceSpace'
                  'FileVersion'
                  'Convention'
                  'OriginalVMRResolutionX'
                  'OriginalVMRResolutionY'
                  'OriginalVMRResolutionZ'
                  'OriginalVMROffsetX'
                  'OriginalVMROffsetY'
                  'OriginalVMROffsetZ'
				  'OriginalVMRFramingCubeDim'};

%% Select 2+ VOI files
[fns, pn, filter] = uigetfile('*.voi', 'Select VOI File(s)','MultiSelect', 'on');

%% Check inputs
if filter ~= 1
    error('Invalid selection.')
end
if ~iscell(fns)
    fns = {fns};
end

%% Init new VOI
voi = xff('voi');

%% Add each VOI to new VOI
num_file = length(fns);
for fid = 1:num_file
    fn = fns{fid};
    fprintf('File %d of %d: %s\n', fid, num_file, fn);
    
    %load
    voi_temp = xff([pn fn]);
    
    %compare
    if fid == 1
        for f = fields_compare'
            eval(sprintf('voi.%s = voi_temp.%s;', f{1}, f{1}));
        end
    else
        for f = fields_compare'
            eval(sprintf('val = (voi.%s == voi_temp.%s);', f{1}, f{1}));
            if ~val
                error('Incompatible VOIs!')
            end
        end
    end
    
    %add each voi
    for v = 1:voi_temp.NrOfVOIs
        fprintf('  Region %d of %d: %s\n', v, voi_temp.NrOfVOIs, voi_temp.VOI(v).Name);
        voi.NrOfVOIs = voi.NrOfVOIs + 1;
        voi.VOI(voi.NrOfVOIs) = voi_temp.VOI(v);
    end
    
    %clear
    voi_temp.ClearObject;
end

%% Save
[fn, pn, filter] = uiputfile('*.voi', 'Save New VOI', 'merged.voi');
voi.SaveAs([pn fn]);
fprintf('Added %d regions.\n', voi.NrOfVOIs)

%% Done
disp Done.