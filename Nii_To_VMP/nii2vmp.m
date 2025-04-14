function nii2vmp

resolution = 3;

%% nii.gz to nii

list = dir('*.nii.gz');

for m = 1:length(list)
    fprintf('Unzipping %s\n', list(m).name);
    gunzip(list(m).name)
end

%% nii to vmp
list = dir('*.nii');

ne = neuroelf;

for m = 1:length(list)
    
    name = list(m).name;
%     name_noext = name(1:find(name=='.',1,'last')-1)
    name_noext = ['nii2vmp_' name(1:find(name=='_',1,'first')-1)];
    name_noext(name_noext==' ') = '_';
    
    fprintf('%s ==> %s\n',name,name_noext);
    
    vmp = ne.importvmpfromspms(name,[],[],resolution);
    vmp.Map(1).Name = name_noext;
    vmp.SaveAs([name_noext '.vmp']);

    if m==1
        vmp_main = vmp.Copy();
    else
        vmp_main.Map(m) = vmp.Map(1);
    end
    
    vmp.ClearObject;
    
end

vmp_main.SaveAs('nii2vmp.vmp')
vmp_main.ClearObject;