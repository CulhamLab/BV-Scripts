function step1_MotExtractFromSDM

%create input folder if it doesn't exist  to clarify where inputs should go
inFolName = 'Input(sdm)';
if ~exist('Input(sdm)','dir')
    mkdir(inFolName)
end

%create output folder
outmatFolName = 'Output(mat)';
if ~exist('Output(mat)','dir')
    mkdir(outmatFolName)
end

%create output folder
outfigFolName = 'Output(png)';
if ~exist('Output(png)','dir')
    mkdir(outfigFolName)
end

%list sdm
list = dir([pwd filesep inFolName filesep '*.sdm']);

%initialize
nameList = {};
nameID = zeros(1,length(list));
nCount = 1;
fileListByGroup = {};

%group by whatever proceeds the first "searchChar" (e.g., '_')
searchChar = '_';
for i = 1:length(list)
    if ~nameID(i)
        f = find(list(i).name==searchChar,1);
        f = list(i).name(1:f-1);
        nameList{nCount} = f;
        for ii = 1:length(list)
            ff = find(list(ii).name==searchChar,1);
            ff = list(ii).name(1:ff-1);
            if strcmp(f,ff) & ~nameID(ii)
                nameID(ii) = nCount;
                fileListByGroup{nCount,sum(nameID==nCount)} = list(ii).name;
            end
        end
        nCount = nCount + 1;
    end
end

%for each group, load the sdms (in a study-specific order) and grab the
%xyz and rotation values
for group = 1:length(unique(nameID))
    numInGroup = sum(nameID==group);
    
    memberOrder = [];
    
    %%
    %study-specific ordering bit - can do this any way you like so long as
    %you reorder [1:numInGroup] into a variable called memberOrder
    
%     %Scott
%     for order = 1:8
%         found = 0;
%         for member = 1:numInGroup
%             searchfor{order} = ['Order' num2str(order)];
%             if strfind(fileListByGroup{group,member},searchfor{order})
%                 memberOrder = [memberOrder member];
%                 found = 1;
%             end
%         end
%         if ~found;
%             memberOrder = [memberOrder 0];
%         end
%     end
    
    for order = 1:8
        found = 0;
        for member = 1:numInGroup
            searchfor{order} = sprintf('S1R%d_',order);
            if strfind(fileListByGroup{group,member},searchfor{order})
                memberOrder = [memberOrder member];
                found = 1;
            end
        end
        if ~found;
            memberOrder = [memberOrder 0];
        end
    end

    %Odd Even Re-Order
    doOddEven = 0;
    if doOddEven
        oe = [1:2:numInGroup 2:2:numInGroup];
        for i = 1:numInGroup
            t = oe(i);
            temp{i} = searchfor{t};
        end
        searchfor = temp;
        memberOrder = memberOrder(oe);
    end
    %%
    
    %output member order to check
    orderedNames = cell(length(memberOrder),1);
    for order = 1:length(memberOrder)
        if ~memberOrder(order)
            disp 'Not Found'
        else
            disp(fileListByGroup{group,memberOrder(order)})
            orderedNames{order} = fileListByGroup{group,memberOrder(order)};
        end
    end
    disp ' '
    
    %initialize cell arrays
    x = {};
    y = {};
    z = {};
    rx = {};
    ry = {};
    rz = {};
    
    %read in sdm to cell array
    for order = 1:length(memberOrder)
        if memberOrder(order)
            sdm = BVQXfile([pwd filesep inFolName filesep fileListByGroup{group,memberOrder(order)}]);
            for i = 1:length(sdm.PredictorNames)
                switch sdm.PredictorNames{i}
                    case 'Translation BV-X [mm]'
                        x{order} = sdm.SDMMatrix(:,i);
                    case 'Translation BV-Y [mm]'
                        y{order} = sdm.SDMMatrix(:,i);
                    case 'Translation BV-Z [mm]'
                        z{order} = sdm.SDMMatrix(:,i);
                    case 'Rotation BV-X [deg]'
                        rx{order} = sdm.SDMMatrix(:,i);
                    case 'Rotation BV-Y [deg]'
                        ry{order} = sdm.SDMMatrix(:,i);
                    case 'Rotation BV-Z [deg]'
                        rz{order} = sdm.SDMMatrix(:,i);
                end
            end
        end
    end
    
    filename = [pwd filesep outmatFolName filesep nameList{group} '_motionparams'];
    save(filename,'x','y','z','rx','ry','rz','orderedNames','searchfor')
end


% for file = 1:length(list)
%     sdm = BVQXfile([pwd '\sdms\' list(file).name]);
% 
%     for i = 1:length(sdm.PredictorNames)
%         switch sdm.PredictorNames{i}
%             case 'Translation BV-X [mm]'
%                 x = sdm.SDMMatrix(:,i);
%             case 'Translation BV-Y [mm]'
%                 y = sdm.SDMMatrix(:,i);
%             case 'Translation BV-Z [mm]'
%                 z = sdm.SDMMatrix(:,i);
%             case 'Rotation BV-X [deg]'
%                 rx = sdm.SDMMatrix(:,i);
%             case 'Rotation BV-Y [deg]'
%                 ry = sdm.SDMMatrix(:,i);
%             case 'Rotation BV-Z [deg]'
%                 rz = sdm.SDMMatrix(:,i);
%         end
%     end
%     
%     filename = find(list(file).name == '.',1,'last');
%     filename = list(file).name(1:filename-1);
%     save([pwd '\motionparams\' filename '_motionparams'],'x','y','z','rx','ry','rz')
% end

end