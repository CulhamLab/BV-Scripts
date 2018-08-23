function Brain_Drawing_Tool(load_prior)

%% Close all prior figures
closeAllFigures

%% Init global stuct
global g
g = struct;

%% Parameters
g.PARAM.COORD.TAL = [-127 : 128];
g.PARAM.COORD.SYS = [1 : 256];
g.PARAM.COORD.CONVERT_ORDER = [3 1 2];
g.PARAM.COORD.SIZE = 256;
g.PARAM.FILENAME.PRIOR = 'prior_session.mat';

%% Colours
g.colours.crosshair = [1 1 0];
g.colours.mask = [0 0 1];
g.colours.vertex = [0 1 1];
g.colours.vertex_highlight = [1 0 0];

%% Prepare Main GUI

%prevent drawing axes until setup is complete
g.allow_draw = false;

%load fig
g.fig.main = hgload([pwd filesep 'GUI' filesep 'Brain_Drawing_Tool.fig']);
set(g.fig.main,'units','normalized','outerposition',[0 0 1 1]); %maximize

%set anat colours
set(g.fig.main, 'ColorMap', repmat([0:255]/255,[3 1])'); %256 grayscale values

%get tags
addTags

%update g
global g

%set display positions
g.tag.sag = g.tag.axes.TL;
g.tag.cor = g.tag.axes.TR;
g.tag.tra = g.tag.axes.BR;

%draw blank image in bottom left
imagesc(0,'Parent',g.tag.bgd)

%set colourmap bounds
% % for id = [cellfun(@(x) eval(['g.tag.axes.' x]), fields(g.tag.axes))' g.tag.bgd]
% %     caxis(id,[0 255])
% % end
for id = [cellfun(@(x) ['g.tag.axes.' x],fields(g.tag.axes),'UniformOutput',false)' 'g.tag.bgd']
    eval(['caxis(' id{1}  ',[0 255])'])
end

%% Prepare VMP GUI
% set(g.fig.vmp,'CloseRequestFcn','@hello')

%% Session Info / Initialization
%general settings
g.settings.large_saves = false;

%no vmr
g.vmp.show = false;
g.vmp.active = nan;

%no known filepaths
g.filepath.save = nan;
g.filepath.vmr = nan;
g.filepath.vmp = nan;
g.filepath.active = [pwd filesep];

%non-saving drawing info
g.draw_instance.highlight = nan;
g.draw_instance.latest_type = 'sag';

%default view
g.view.display = 'default';
g.view.flipLR = false;
g.view.crosshair = true;

%default draw settings
g.draw.brush_dim = 3;
g.draw.separate_voxels = true;
setBrush(2);

%mouse/keyboard
g.kb.Modifier = {};
g.kb.Key = '';
g.mouse_down = false;

%blank brain map
g.brain = zeros([g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE]);

%masks
g.mask.empty = false([g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE]);
g.mask.image = repmat(reshape(g.colours.mask,[1 1 3]),[g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE 1]);

%add the empty mask
createMask;

%position
g.pos.sys.x = nan;
g.pos.sys.y = nan;
g.pos.sys.z = nan;
updatePosition_TAL(0,0,0)

%% Activate
%can now draw
g.allow_draw = true;

%add callbacks
addCallbacks

%% Hide things that might not be needed immediately
set(g.tag.sag,'visible','off')
set(g.tag.tra,'visible','off')
set(g.tag.cor,'visible','off')

%% Load and Refresh GUI
if (~exist('load_prior','var') | load_prior) & exist(g.PARAM.FILENAME.PRIOR,'file')
    loadSession(g.PARAM.FILENAME.PRIOR)
end
refresh

end %end of main

%% General

function closeAllFigures
    %working with gui figs so close all won't work
    delete(findall(0, 'type', 'figure'))
end

%% GUI Setup

function addCallbacks
    global g
    %menu
    tags = {
    'menu_file_new',
    'menu_file_load',
    'menu_file_save',
    'menu_file_saveas',
    'menu_file_load_vmr',
    'menu_file_load_vmp',
    'menu_file_import_voi',
    'menu_file_export_msk',
    'menu_file_export_voi',
    'menu_file_export_vmp_map',
    'menu_file_export_vmp_mask',
    'menu_view_default',
    'menu_view_sag',
    'menu_view_cor',
    'menu_view_tra',
    'menu_view_radio',
    'menu_view_neuro',
    'menu_view_crosshair',
    'menu_mask_mask_brain_this',
    'menu_mask_mask_brain_all',
    'menu_mask_mask_vmp_this',
    'menu_mask_mask_vmp_all',
    'menu_drawing_size',
    'menu_drawing_2D',
    'menu_drawing_3D',
    'menu_mask_separate_voxels',
    'menu_create_clone',
    'menu_create_combine_vertex',
    'menu_create_combine_voxel_and',
    'menu_create_combine_voxel_or',
    'menu_create_sphere',
    'menu_vmp_show',
    'menu_vmp_menu',
    'menu_vmp_search_max',
    'menu_vmp_search_min',
    'menu_settings_large_saves',
    'menu_help_hotkey'
    };
    for t = tags'
        id = findall(g.fig.main, 'tag', t{1});
        set(id,'Callback', eval(['@' t{1}]));
        eval(['g.tag.menu.' t{1} ' = id;'])
    end
    
    %xyz
    set(g.tag.pos.x,'Callback',@callbackXYZ)
    set(g.tag.pos.y,'Callback',@callbackXYZ)
    set(g.tag.pos.z,'Callback',@callbackXYZ)
    
    %figure
    set(g.fig.main,'WindowButtonMotionFcn',@callbackMouse)
    set(g.fig.main,'WindowButtonDownFcn',@callbackMouseDown)
    set(g.fig.main,'WindowButtonUpFcn',@callbackMouseUp)
    set(g.fig.main,'KeyPressFcn',@callbackKey) 
    set(g.fig.main,'KeyReleaseFcn',@callbackKeyUp)
    set(g.fig.main,'DeleteFcn',@callbackDelete)
    
    %buttons
    set(g.tag.mask.new,'Callback',{@callbackShiftFocusRelay @callbackMaskNew})
    set(g.tag.mask.del,'Callback',{@callbackShiftFocusRelay @callbackMaskDel})
    set(g.tag.mask.rename,'Callback',{@callbackShiftFocusRelay @callbackMaskRename})
    set(g.tag.mask.optimize,'Callback',{@callbackShiftFocusRelay @callbackMaskOptimize})
    
    %mask list
    set(g.tag.mask.list,'Callback',{@callbackShiftFocusRelay @callbackMaskList})
    
end

function addTags
    global g

    g.tag.bgd = findall(g.fig.main, 'tag', 'axes_bgd');

    g.tag.axes.TL = findall(g.fig.main, 'tag', 'axes_TL');
    g.tag.axes.TR = findall(g.fig.main, 'tag', 'axes_TR');
    g.tag.axes.BR = findall(g.fig.main, 'tag', 'axes_BR');
    g.tag.axes.BIG = findall(g.fig.main, 'tag', 'axes_BIG');

    g.tag.pos.x = findall(g.fig.main, 'tag', 'edit_x');
    g.tag.pos.y = findall(g.fig.main, 'tag', 'edit_y');
    g.tag.pos.z = findall(g.fig.main, 'tag', 'edit_z');

    g.tag.mask.list = findall(g.fig.main, 'tag', 'list_masks');
    g.tag.mask.new = findall(g.fig.main, 'tag', 'button_new');
    g.tag.mask.del = findall(g.fig.main, 'tag', 'button_del');
    g.tag.mask.rename = findall(g.fig.main, 'tag', 'button_rename');
    g.tag.mask.optimize = findall(g.fig.main, 'tag', 'button_optimize');
end

%% GUI Operations

function refresh
    updateCoordBoxes
    draw
    updateMenuChecks
    updateMaskList
end

function updatePosition_SYS(x,y,z)
    global g
    prior = g.pos.sys;
    for i = {'x' 'y' 'z'}
        i=i{1};
        val = eval([i ';']);
        
        if ischar(val)
            val = str2num(val);
        end
        
        if ~length(val)
            val = eval(['g.pos.sys.' i]);
        elseif length(val)>1
            val = val(1);
        end
        
        if val < g.PARAM.COORD.SYS(1) 
            val = g.PARAM.COORD.SYS(1);
        elseif val > g.PARAM.COORD.SYS(end)
            val = g.PARAM.COORD.SYS(end);
        end
        
        eval(['g.pos.sys.' i ' = val;'])
    end
    
    [g.pos.tal.x, g.pos.tal.y, g.pos.tal.z] = sys2tal(g.pos.sys.x,g.pos.sys.y,g.pos.sys.z);
    
    updateCoordBoxes
    
    if (prior.x ~= g.pos.sys.x) | (prior.y ~= g.pos.sys.y) | (prior.z ~= g.pos.sys.z)
        draw
    end
end

function updatePosition_TAL(x,y,z)
    global g
    prior = g.pos.sys;
    for i = {'x' 'y' 'z'}
        i=i{1};
        val = eval([i ';']);
        
        if ischar(val)
            val = str2num(val);
        end
        
        if ~length(val)
            val = eval(['g.pos.tal.' i]);
        elseif length(val)>1
            val = val(1);
        end
        
        if val < g.PARAM.COORD.TAL(1) 
            val = g.PARAM.COORD.TAL(1);
        elseif val > g.PARAM.COORD.TAL(end)
            val = g.PARAM.COORD.TAL(end);
        end
        
        eval(['g.pos.tal.' i ' = val;'])
        eval(['set(g.tag.pos.' i ',''String'',val);'])
    end
    
    [g.pos.sys.x, g.pos.sys.y, g.pos.sys.z] = tal2sys(g.pos.tal.x,g.pos.tal.y,g.pos.tal.z);
    
    updateCoordBoxes
    
    if (prior.x ~= g.pos.sys.x) | (prior.y ~= g.pos.sys.y) | (prior.z ~= g.pos.sys.z)
        draw
    end
end

function updateCoordBoxes
    global g
    for i = {'x' 'y' 'z'}
        i=i{1};
        eval(['set(g.tag.pos.' i ',''String'', num2str(g.pos.tal.' i ') );'])
    end
end

function [xy,type,xyz] = getMousePosition %xy is in-axes coord, type is display mode of moused axes, xyz is sys coord
    global g
    ids = [g.tag.sag g.tag.cor g.tag.tra g.tag.axes.BIG];
    xy = get(ids,'CurrentPoint');
    xy = cellfun(@(x) x(1,1:2), xy, 'UniformOutput', false);
    inside = cellfun(@(x) ~any(x(:)<0 | x(:)>g.PARAM.COORD.SIZE), xy);

    if strcmp(g.view.display,'default') & any(inside(1:3))
        ind = find(inside,1,'first');
        xy = xy{ind};
        switch ind
            case 1
                type = 'sag';
            case 2
                type = 'cor';
            case 3
                type = 'tra';
            otherwise
                error('Unknown axes.');
        end
    elseif ~strcmp(g.view.display,'default') & inside(4)
        xy = xy{4};
        type = g.view.display;
    else
        xy = nan;
        xyz = nan;
        type = nan;
        return
    end
    xy = ceil(xy);
    
    %also return sys coord
    switch type
        case 'sag'
            xyz = [xy(1) xy(2) g.pos.sys.z];
        case 'cor'
            xyz = [g.pos.sys.x xy(2) xy(1)];
        case 'tra'
            xyz = [xy(2) g.pos.sys.y xy(1)];
        otherwise
            errorViewType
    end
end

function [mouse_click_type] = getLatestMouseClickType
    global g
    mouse_click_type = get(g.fig.main,'SelectionType');
    switch mouse_click_type
        case 'normal'
            mouse_click_type = 'left';
        case 'alt'
            mouse_click_type = 'right';
        case 'open'
            mouse_click_type = 'double';
        otherwise
            mouse_click_type = 'both';
    end
end

function mouseEvent(mouse_state)
    global g
    
    [xy,type,xyz] = getMousePosition;
    
    if isnan(type)
        return
    end
    
    if any(strcmp({'up' 'down'},mouse_state))
        g.draw_instance.latest_type = type;
    end
    
    [mouse_click_type] = getLatestMouseClickType;

    if any(strcmp(g.kb.Modifier,'control'))
        brush(xyz,type,any(strcmp(g.kb.Modifier,'shift')))
    else
        if strcmp('left',mouse_click_type)
            if strcmp(g.kb.Key,'alt') & ~isnan(g.draw_instance.highlight)
                g.mask.masks(g.mask.active).vertices(g.draw_instance.highlight,:) = xyz;
                computeMaskVoxels;
                %voxel order may have changed
                v = g.mask.masks(g.mask.active).vertices;
                g.draw_instance.highlight = find(v(:,1)==xyz(1) & v(:,2)==xyz(2) & v(:,3)==xyz(3),1,'first');
                draw
            else
                [x,y,z] = getCoord(xy,type);
                updatePosition_SYS(x,y,z);
            end
        elseif strcmp(mouse_state,'down')
            if any(strcmp(g.kb.Modifier,'alt')) & strcmp('right',mouse_click_type) %ALT + right click

               if strcmp(g.view.display,'default')
                   g.view.display = type;
               else
                   g.view.display = 'default';
               end
               draw
               updateMenuChecks
            end
        end
    end
end

function updateMenuChecks
    global g
    
    %view - display mode
    for v = {'sag' 'cor' 'tra' 'default'}
        v = v{1};
        if strcmp(g.view.display,v)
            eval(['set(g.tag.menu.menu_view_' v ',''Checked'',''on'');'])
        else
            eval(['set(g.tag.menu.menu_view_' v ',''Checked'',''off'');'])
        end
    end
    
    %view - flip L/R
    if g.view.flipLR
        set(g.tag.menu.menu_view_neuro,'Checked','on')
        set(g.tag.menu.menu_view_radio,'Checked','off')
    else
        set(g.tag.menu.menu_view_neuro,'Checked','off')
        set(g.tag.menu.menu_view_radio,'Checked','on')
    end
    
    %view - crosshair
    if g.view.crosshair
        set(g.tag.menu.menu_view_crosshair,'Checked','on')
    else
        set(g.tag.menu.menu_view_crosshair,'Checked','off')
    end
    
    %draw
    set(g.tag.menu.menu_drawing_size,'Label',['Set Brush Size: ' num2str(g.draw.brush_size)])
    if g.draw.brush_dim == 3
        set(g.tag.menu.menu_drawing_2D,'Checked','off')
        set(g.tag.menu.menu_drawing_3D,'Checked','on')
    else
        set(g.tag.menu.menu_drawing_2D,'Checked','on')
        set(g.tag.menu.menu_drawing_3D,'Checked','off')
    end
    if g.draw.separate_voxels
        set(g.tag.menu.menu_mask_separate_voxels,'Checked','on')
    else
        set(g.tag.menu.menu_mask_separate_voxels,'Checked','off')
    end
    
    %vmp
    if g.vmp.show
        set(g.tag.menu.menu_vmp_show,'Checked','on')
    else
        set(g.tag.menu.menu_vmp_show,'Checked','off')
    end
    
    %settings
    if g.settings.large_saves
        set(g.tag.menu.menu_settings_large_saves,'Checked','on')
    else
        set(g.tag.menu.menu_settings_large_saves,'Checked','off')
    end
end

function updateMaskList
    global g
    set(g.tag.mask.list,'String',{g.mask.masks.name},'Value',g.mask.active)
end

function setView(type)
    global g
    g.view.display = type;
    draw
    updateMenuChecks
end

function setFlipLR(value)
    global g
    g.view.flipLR = value;
    draw
    updateMenuChecks
end

function setCrosshair(value)
    global g
    if ~nargin
        g.view.crosshair = ~g.view.crosshair;
    else
        g.view.crosshair = value;
    end
    draw
    updateMenuChecks
end

%% IO

function saveSession(fp)
    global g
    if ~nargin | isnan(fp)
        [fn,pn] = uiputfile([g.filepath.active '*.mat']);
        fp = [pn fn];
        if isnumeric(fp)
            return
        end
        g.filepath.active = pn;
    end
    
    g.filepath.save = fp;
    
    session.filepath = g.filepath;
    session.pos = g.pos;
    session.mask = g.mask;
    session.view = g.view;
    session.fig_pos = get(g.fig.main,'outerposition');
    session.draw = g.draw;
    session.settings = g.settings;
    
    if g.settings.large_saves
        session.brain = g.brain;
        session.vmp = g.vmp;
    end
    
    m = msgbox('Saving Session...');
    
    save(fp,'session')
    if ~strcmp(fp,g.PARAM.FILENAME.PRIOR)
        save(g.PARAM.FILENAME.PRIOR,'session')
    end
    
    if isgraphics(m)
        delete(m)
    end
end

function loadSession(fp)
    global g
    if ~nargin
        [fn,pn] = uigetfile([g.filepath.active '*.mat']);
        fp = [pn fn];
        if isnumeric(fp)
            return
        end
        g.filepath.active = pn;
    end
    
    try
        m = msgbox('Loading Session...');
        
        load(fp)

        if isgraphics(m)
            delete(m)
        end

        g.filepath = session.filepath;
        g.pos = session.pos;
        g.mask = session.mask;
        g.view = session.view;
        g.draw = session.draw;
        g.settings = session.settings;

        set(g.fig.main,'outerposition',session.fig_pos)

        if g.settings.large_saves
            g.brain = session.brain;
            g.vmp = session.vmp;
        else
            if ~isnan(g.filepath.vmr)
                loadVMR(g.filepath.vmr)
            end
            if ~isnan(g.filepath.vmp)
                loadVMP(g.filepath.vmp)
            end
        end
    
    catch err
        warning('Could not reload prior session.')
        Brain_Drawing_Tool(false)
        return
    end
        
    refresh
end

function loadVMR(fp)
    global g
    if ~nargin
        [fn,pn] = uigetfile('*.vmr','Select Anatomical VMR');
        fp = [pn fn];
        if isnumeric(fp)
            return
        end
        g.filepath.active = pn;
    end
    
    g.filepath.vmr = fp;
    
    m = msgbox('Loading VMR...');
    
    if exist(fp,'file')
        vmr = xff(fp);

        if any([vmr.DimX vmr.DimY vmr.DimZ] ~= g.PARAM.COORD.SIZE)
            errordlg('VMR dimensions are invalid.');
            return
        end
        
        g.brain = single(vmr.VMRData)/255;
    else
        msgbox('Saved VMR file could not be found.')
    end
    
    if isgraphics(m)
        delete(m)
    end
    
    draw
end

function exportVOI(fp)
    global g
    if ~nargin | isnan(fp)
        [fn,pn] = uiputfile([g.filepath.active '*.voi']);
        fp = [pn fn];
        if isnumeric(fp)
            return
        end
        g.filepath.active = pn;
    end
    
    m = msgbox('Exporting VOI...');
    
    voi = xff('voi');
    number_masks = length(g.mask.masks);
    colours = jet(number_masks);
    voi.NrOfVOIs = number_masks;
    for v = 1:number_masks
        mask = g.mask.masks(v).map_vertex | g.mask.masks(v).map_draw;
        [x,y,z] = ind2sub([g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE],find(mask(:)));
        [x,y,z] = sys2tal(x,y,z);
        
        voi.VOI(v).Name = g.mask.masks(v).name;
        voi.VOI(v).Color = colours(v,:);
        voi.VOI(v).Voxels = [x y z];
        voi.VOI(v).NrOfVoxels = length(x);
    end
    voi.SaveAs(fp);
    voi.Clear;
    
    if isgraphics(m)
        delete(m)
    end
end

function importVOI(fp)
    global g
    if ~nargin | isnan(fp)
        [fn,pn] = uigetfile([g.filepath.active '*.voi']);
        fp = [pn fn];
        if isnumeric(fp)
            return
        end
        g.filepath.active = pn;
    end
    
    m = msgbox('Importing VOI...');
    
    %clear current mask if in default state
    if length(g.mask.masks)==1 & ~any(g.mask.masks(1).map_vertex(:)) & ~any(g.mask.masks(1).map_draw(:))
        g.mask.masks = [];
    end
    
    voi = xff(fp);
    number_masks = voi.NrOfVOIs;
    for v = 1:number_masks
        position = createMask(voi.VOI(v).Name);
        [x,y,z] = tal2sys(voi.VOI(v).Voxels(:,1),voi.VOI(v).Voxels(:,2),voi.VOI(v).Voxels(:,3));
        ind = sub2ind([g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE],x,y,z);
        g.mask.masks(position).map_draw(ind) = true;
    end
    voi.Clear;
    
    draw
    
    if isgraphics(m)
        delete(m)
    end
end

function loadVMP(fp)
    global g
    if ~nargin | isnan(fp)
        [fn,pn] = uigetfile([g.filepath.active '*.vmp']);
        fp = [pn fn];
        if isnumeric(fp)
            return
        end
        g.filepath.active = pn;
    end
    
    g.filepath.vmp = fp;
    
    m = msgbox('Loading VOI...');
    
    vmp = xff(fp);
    for i = 1:vmp.NrOfMaps
        %get map
        map = vmp.Map(i).VMPData;
        
        %put in 1mm space
        for j = 1:3
            inds{j} = ceil( (1/vmp.Resolution) : (1/vmp.Resolution) : size(map,j) );
        end
        map = map(inds{1},inds{2},inds{3});
        
        %create full map
        g.vmp.map(i).map = nan(g.PARAM.COORD.SIZE,g.PARAM.COORD.SIZE,g.PARAM.COORD.SIZE);
        g.vmp.map(i).map( vmp.XStart:(vmp.XEnd-1) , vmp.YStart:(vmp.YEnd-1) , vmp.ZStart:(vmp.ZEnd-1) ) = map;
        
        %other info
        for c = {'Name' 'LowerThreshold' 'UpperThreshold' 'UseValuesAboveThresh' 'ShowPositiveNegativeFlag' 'RGBLowerThreshPos' 'RGBUpperThreshPos' 'RGBLowerThreshNeg' 'RGBUpperThreshNeg'}
            c=c{1};
            eval(['g.vmp.map(i).' c ' = vmp.Map(i).' c ';'])
        end
        
        %colours and thresholds
        g.vmp.map(i).map_colour = nan(g.PARAM.COORD.SIZE,g.PARAM.COORD.SIZE,g.PARAM.COORD.SIZE,3);
    end
    vmp.Clear;
    
    g.vmp.active = 1;
    g.vmp.show = true;
    updateMenuChecks
    
    updateVMPMap
    draw
    
    if isgraphics(m)
        delete(m)
    end
end

%% Coordinates

function [x,y,z] = tal2sys(x_tal,y_tal,z_tal)
    global g
    L = length(g.PARAM.COORD.TAL);
    for i = {'x' 'y' 'z'}
        i=i{1};
        eval(['tal = ' i '_tal;'])
        ind = arrayfun(@(c) find(g.PARAM.COORD.TAL==c),tal); %find(g.PARAM.COORD.TAL==tal);
        ind = L-ind+1;
        eval([i '_sys = g.PARAM.COORD.SYS(ind);'])
    end
    coords = {x_sys' y_sys' z_sys'};
    x = coords{find(g.PARAM.COORD.CONVERT_ORDER==1)};
    y = coords{find(g.PARAM.COORD.CONVERT_ORDER==2)};
    z = coords{find(g.PARAM.COORD.CONVERT_ORDER==3)};
end

function [x,y,z] = sys2tal(x_sys,y_sys,z_sys)
    global g
    L = length(g.PARAM.COORD.TAL);
    for i = {'x' 'y' 'z'}
        i=i{1};
        eval(['sys = ' i '_sys;'])
        ind = arrayfun(@(c) find(g.PARAM.COORD.SYS==c),sys); %find(g.PARAM.COORD.SYS==sys);
        ind = L-ind+1;
        eval([i '_tal = g.PARAM.COORD.TAL(ind);'])
    end
    coords = {x_tal' y_tal' z_tal'};
    x = coords{g.PARAM.COORD.CONVERT_ORDER(1)};
    y = coords{g.PARAM.COORD.CONVERT_ORDER(2)};
    z = coords{g.PARAM.COORD.CONVERT_ORDER(3)};
end

function [x,y,z] = getCoord(xy,type)
    global g
    L = size(xy,1);
    x = repmat(g.pos.sys.x,[L 1]);
    y = repmat(g.pos.sys.y,[L 1]);
    z = repmat(g.pos.sys.z,[L 1]);
    switch type
        case 'sag'
            x = xy(:,1);
            y = xy(:,2);
        case 'cor'
            z = xy(:,1);
            y = xy(:,2);
        case 'tra'
            z = xy(:,1);
            x = xy(:,2);
        otherwise
            errorViewType
    end
end

function [dim] = getInactiveDim(type)
    switch type
        case 'sag'
            dim = 3;
        case 'cor'
            dim = 1;
        case 'tra'
            dim = 2;
        otherwise
            errorViewType
    end
end

%% Masks / VMP

function [isValid] = isValidMaskName(name)
    global g
    isValid = true;
    
    if ~ischar(name)
        isValid = false;
    elseif ~length(name)
        isValid = false;
    elseif any(strcmp(fields(g.mask),'masks')) & length(g.mask.masks)
        ind_other = 1:length(g.mask.masks);
        ind_other(g.mask.active) = [];
        if any(strcmp({g.mask.masks(ind_other).name},name))
            isValid = false;
        end
    end
end

function [number_voxels] = computeMaskVoxels(dont_update,vertices)
    global g

    %get vertices, remove duplicates
    if ~exist('vertices','var')
        vertices = g.mask.masks(g.mask.active).vertices;
        vertices = unique(vertices,'rows');
        g.mask.masks(g.mask.active).vertices = vertices;
    end
    
    %stop if no vertices
    number_vertices = size(vertices,1);
    if ~size(vertices,1)
        number_voxels = 0;
        return
    end
    
    %create list of potential voxels
    map = g.mask.empty;
    map( min(vertices(:,1)):max(vertices(:,1)) , min(vertices(:,2)):max(vertices(:,2)) , min(vertices(:,3)):max(vertices(:,3))) = true;
    ind_use = find(map(:));
    [x,y,z] = ind2sub([g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE], ind_use);
    voxels = [x y z];
    
    %extend vertices
    vertices_extended = nan(number_vertices*6,3);
    counter = 0;
    for v = 1:number_vertices
        for i = 1:3
            adder = [0 0 0];
            for j = [-1 +1]/10
                adder(i) = j;
                counter = counter + 1;
                vertices_extended(counter,:) = vertices(v,:) + adder;
            end
        end
    end
    
    %find which voxels are inside
    inside = inhull(voxels,vertices_extended,[],1);
    index_inside = ind_use(inside);
    
    %count included voxels
    number_voxels = size(index_inside,1);
    
    %set mask
    if ~exist('dont_update','var') | ~dont_update
        g.mask.masks(g.mask.active).map_vertex = g.mask.empty;
        g.mask.masks(g.mask.active).map_vertex(index_inside) = true;
    end
    
%%% old method, too slow
%     if size(vertices,1) < 4
%         return
%     end
    
%     x_ver = (vertices(:,1));
%     y_ver = (vertices(:,2));
%     z_ver = (vertices(:,3));
%     
%     tri = delaunayn([x_ver y_ver z_ver]);
%     tn = tsearchn([x_ver y_ver z_ver], tri, g.all_voxels);
%     
%     inside = ~isnan(tn);
    
end

function [position] = createMask(name,position)
    global g

    if ~exist('position','var')
        if ~any(strcmp(fields(g.mask),'active'))
            position = 1;
        else
            position = length(g.mask.masks) + 1;
        end
    end
    
    if ~exist('name','var') | ~isValidMaskName(name)
        name = ['default' num2str(position)];
        while ~isValidMaskName(name)
            name(end+1) = 'x';
        end
    end
    
    g.mask.masks(position).name = name;
    g.mask.masks(position).map_vertex = g.mask.empty;
    g.mask.masks(position).map_draw = g.mask.empty;
    g.mask.masks(position).vertices = [];
    
    g.mask.active = position;
    
    draw
    updateMaskList
end

function setBrush(size)
    if size<1
        size = 1;
    end

    global g
    
    xyz = [];
    for x = [-size:+size]
        for y = [-size:+size]
            for z = [-size:+size]
                if sqrt(sqrt(x^2 + y^2)^2 + z^2) <= size %pdist([0 0 0; x y z])<=size
                    xyz(end+1,:) = [x y z];
                end
            end
        end
    end
    
    g.draw.brush_size = size;
    g.draw.brush = xyz;
end

function brush(xyz,type,is_erase)
    global g
    
    %get coords
    coord = g.draw.brush;
    coord = coord + repmat(xyz,[size(coord,1) 1]);
    
    %remove outsize
    ind = ~any(coord<1 | coord>g.PARAM.COORD.SIZE,2);
    coord = coord(ind,:);
    
    %restrict to 2D?
    if g.draw.brush_dim == 2
        dim_names = 'xyz';
        dim_ignore = getInactiveDim(type);
        eval(['coord(:,dim_ignore) = g.pos.sys.' dim_names(dim_ignore) ';'])
    end
    
    %set in map
    ind = sub2ind([g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE],coord(:,1),coord(:,2),coord(:,3));
    g.mask.masks(g.mask.active).map_draw(ind) = ~is_erase;
    
    %update
    draw
end

function updateVMPMap(map_number)
    global g
    number_maps = length(g.vmp.map);
    if ~exist('map_number','var') | ~isnumeric(map_number)
        map_number = 1:number_maps;
    end
    map_number(map_number<1) = 1;
    map_number(map_number>number_maps) = number_maps;
    map_number = unique(map_number);
    
    for mn = map_number
        vmp = g.vmp.map(mn);
        
        %initialize
        dim = [g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE g.PARAM.COORD.SIZE];
        g.vmp.map(mn).map_colour = nan([dim 3]);
        
        %select voxels to show
        map_thresh = abs(vmp.map) > vmp.LowerThreshold;
        do_pos = true;
        do_neg = true;
        if vmp.ShowPositiveNegativeFlag == 1
            do_neg = false;
        elseif vmp.ShowPositiveNegativeFlag == 2
            do_pos = false;
        end
        
        %colour - negatives
        if do_neg
            updateVMPMap_addColour(find(map_thresh & vmp.map<=0), dim, mn, vmp.LowerThreshold, vmp.UpperThreshold, vmp.RGBLowerThreshNeg, vmp.RGBUpperThreshNeg)
        end
        
        %colour - positives
        if do_pos
            updateVMPMap_addColour(find(map_thresh & vmp.map>=0), dim, mn, vmp.LowerThreshold, vmp.UpperThreshold, vmp.RGBLowerThreshPos, vmp.RGBUpperThreshPos)
        end
        
    end
end

function updateVMPMap_addColour(ind, dim, map_number, threshLow, threshHigh, colourLow, colourHigh)
    global g
    [x,y,z] = ind2sub(dim,ind);
    
    values = abs(g.vmp.map(map_number).map(ind));
    values = (values - threshLow) / threshHigh;
    values(values>1) = 1;
    
    number_values = length(values);
    
    colours = ((values * [colourHigh-colourLow]) + repmat(colourLow,[number_values 1]))/255;
    
    for i = 1:3
        ind = sub2ind([dim 3],x,y,z,ones(number_values,1)*i);
        g.vmp.map(map_number).map_colour(ind) = colours(:,i);
    end
end

%% Drawing (axes)

function draw
    global g
    if ~g.allow_draw
        return
    end
    
    %draw axes
    if strcmp(g.view.display,'default')
        cla(g.tag.axes.BIG)
        set(g.tag.axes.BIG,'visible','off')
        drawSag(g.tag.sag)
        drawCor(g.tag.cor)
        drawTra(g.tag.tra)
    else
        cla(g.tag.sag)
        cla(g.tag.cor)
        cla(g.tag.tra)
        set(g.tag.axes.BIG,'visible','on')
        switch g.view.display
            case 'sag'
                drawSag(g.tag.axes.BIG)
            case 'cor'
                drawCor(g.tag.axes.BIG)
            case 'tra'
                drawTra(g.tag.axes.BIG)
            otherwise
                errorViewType
        end
    end
end

function drawSag(ax)
    global g
    
    coord.xyz = {1:g.PARAM.COORD.SIZE 1:g.PARAM.COORD.SIZE g.pos.sys.z};
    coord.dims = 'yx';
    coord.rotate = true;
    coord.type = 'sag';

    drawAxes(ax,coord);

end

function drawCor(ax)
    global g
    
    coord.xyz = {g.pos.sys.x 1:g.PARAM.COORD.SIZE 1:g.PARAM.COORD.SIZE};
    coord.dims = 'zy';
    coord.rotate = false;
    coord.type = 'cor';

    drawAxes(ax,coord);
end

function drawTra(ax)
    global g
    
    coord.xyz = {1:g.PARAM.COORD.SIZE g.pos.sys.y 1:g.PARAM.COORD.SIZE};
    coord.dims = 'zx';
    coord.rotate = false;
    coord.type = 'tra';

    drawAxes(ax,coord);
end

function drawAxes(ax,coord)
    global g
    
    %Anat
    img = squeeze(g.brain(coord.xyz{1},coord.xyz{2},coord.xyz{3}));
    img = repmat(img,[1 1 3]);
    
    %VMP Overlay
    if g.vmp.show & ~isnan(g.vmp.active)
        map_colour = squeeze(g.vmp.map(g.vmp.active).map_colour(coord.xyz{1},coord.xyz{2},coord.xyz{3},:));
        ind = ~isnan(map_colour);
        img(ind) = map_colour(ind);
    end
    
    %Masks
    mask_draw = squeeze(g.mask.masks(g.mask.active).map_draw(coord.xyz{1},coord.xyz{2},coord.xyz{3}));
    mask_vertex = squeeze(g.mask.masks(g.mask.active).map_vertex(coord.xyz{1},coord.xyz{2},coord.xyz{3}));
    if g.draw.separate_voxels
        %Mask - Draw
        mask = repmat(mask_draw,[1 1 3]);
        img(mask) = img(mask)*2/3 + g.mask.image(mask)/3;

        %Mask - Vertex
        mask = repmat(mask_vertex,[1 1 3]);
        img(mask) = img(mask)*2/3 + g.mask.image(mask)/3;
    else
        %Mask - Combine
        mask = repmat(mask_draw | mask_vertex,[1 1 3]);
        img(mask) = img(mask)*2/3 + g.mask.image(mask)/3;
    end
    
    %Mask Vertices
    vertices = g.mask.masks(g.mask.active).vertices;
    number_vertices = size(vertices,1);
    if number_vertices
        dim_ignore = getInactiveDim(coord.type);
        vertices_2D = vertices;
        vertices_2D(:,dim_ignore) = [];
        
        ind = find(vertices(:,dim_ignore) == coord.xyz{dim_ignore});
        vertices_2D_this = vertices_2D(ind,:);
        for v = 1:size(vertices_2D_this,1)
            img(vertices_2D_this(v,1),vertices_2D_this(v,2),:) = g.colours.vertex;
        end
    
        %Highlight Vertex
        ind = g.draw_instance.highlight;
        if ~isnan(ind) & ind<=number_vertices
            img(vertices_2D(ind,1),vertices_2D(ind,2),:) = g.colours.vertex_highlight;
        end
    end
    
    %Crosshair
    if g.view.crosshair
        eval(['d1 = g.pos.sys.' coord.dims(1) ';'])
        eval(['d2 = g.pos.sys.' coord.dims(2) ';'])
        img(:,d1,:) = repmat(reshape(g.colours.crosshair,[1 1 3]),[g.PARAM.COORD.SIZE 1 1]);
        img(d2,:,:) = repmat(reshape(g.colours.crosshair,[1 1 3]),[1 g.PARAM.COORD.SIZE 1]);
    end
    
    %Draw
    if coord.rotate
        for i = 1:3
            img(:,:,i) = img(:,:,i)';
        end
    end
    img(img>1) = 1;
    img(img<0) = 0;
    imagesc( img , 'Parent' , ax);
    
    %Rearrange
    if g.view.flipLR & any(coord.dims=='z')
        set(ax,'XDir','reverse')
    else
        set(ax,'XDir','normal')
    end
    set(ax,'YDir','reverse')
    axis(ax,'square')
    axis(ax,'off')
end

%%%% Stacking images/plots/etc with hold takes too long and results in a
%%%% non-correcting slow-down
% % % % function drawAxes(ax,coord)
% % % %     global g
% % % %     
% % % %     drawAnat(ax,coord)
% % % %     
% % % %     if g.view.flipLR & any(coord.dims=='z')
% % % %         set(ax,'XDir','reverse')
% % % %     else
% % % %         set(ax,'XDir','normal')
% % % %     end
% % % %     
% % % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % %     hold(ax,'on')
% % % % 
% % % %     if g.view.crosshair
% % % %         drawCrosshair(ax,coord)
% % % %     end
% % % %     
% % % %     for x = 1:10
% % % %         for y = 1:10
% % % %             
% % % %         end
% % % %     end
% % % %     
% % % %     hold(ax,'off')
% % % %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % %     
% % % %     set(ax,'YDir','reverse')
% % % %     axis(ax,'square')
% % % %     axis(ax,'off')
% % % % end
% % % % 
% % % % function drawAnat(ax,coord)
% % % %     global g
% % % %     img = squeeze(g.brain(coord.xyz{1},coord.xyz{2},coord.xyz{3}));
% % % %     if coord.rotate
% % % %         img = img';
% % % %     end
% % % %     imagesc( img , 'Parent' , ax);
% % % % end
% % % % 
% % % % function drawCrosshair(ax,coord)
% % % %     global g
% % % %     eval(['d1 = g.pos.sys.' coord.dims(1) ';'])
% % % %     plot(ax,[d1 d1],[1 g.PARAM.COORD.SIZE],'Color',g.colours.crosshair)
% % % %     eval(['d2 = g.pos.sys.' coord.dims(2) ';'])
% % % %     plot(ax,[1 g.PARAM.COORD.SIZE],[d2 d2],'Color',g.colours.crosshair)
% % % % end

%% GUI Callbacks

function callbackXYZ(fig,evg)
    global g
    updatePosition_TAL( get(g.tag.pos.x,'String') , get(g.tag.pos.y,'String') , get(g.tag.pos.z,'String') )
end

function callbackMouse(fig,evt)
    global g
    
    need_to_draw = false;
    if ~g.mouse_down & strcmp(g.kb.Key,'alt')
        %determine which vertex to highlight, if any
        prior = g.draw_instance.highlight;
        g.draw_instance.highlight = nan;
        if any(strcmp(g.kb.Modifier,'alt'))
            [xy,type,xyz] = getMousePosition;
            if ~isnan(type)
                vertices = unique(g.mask.masks(g.mask.active).vertices,'rows');
                g.mask.masks(g.mask.active).vertices = vertices;
                number_vertices = size(vertices,1);
                if number_vertices
                    dim_ignore = getInactiveDim(type);
                    xyz(dim_ignore) = [];
                    vertices(:,dim_ignore) = [];
                    [m,g.draw_instance.highlight] = min(sum((vertices - repmat(xyz,[number_vertices 1])) .^ 2,2));
                end
            end
        end
        if g.draw_instance.highlight ~= prior
            need_to_draw = true;
        end
    end
    
    if g.mouse_down
        mouseEvent('drag')
    elseif need_to_draw
        draw
    end
end

function callbackMouseUp(fig,evt)
    global g
    g.mouse_down = false;
    mouseEvent('up')
end

function callbackMouseDown(fig,evt)
    global g
    g.mouse_down = true;
    mouseEvent('down')
end

function callbackKey(fig,evt)
    global g
    g.kb = evt;
    if strcmp(g.kb.Key,'s') & length(g.kb.Modifier)==1 & strcmp(g.kb.Modifier{1},'control') %CTRL+S = save
        saveSession(g.filepath.save)
    elseif strcmp(g.kb.Key,'v')
        [xy,type,xyz] = getMousePosition;
        if ~isnan(type)
            g.mask.masks(g.mask.active).vertices(end+1,:) = xyz;
        end
    elseif strcmp(g.kb.Key,'alt')
        if isnan(g.draw_instance.highlight)
            callbackMouse
        end
    end
    
    %arrow key movement
    if ~isempty(strfind(g.kb.Key,'arrow'))
        switch g.draw_instance.latest_type
            case 'sag'
                dims = 'xy';
            case 'cor'
                dims = 'zy';
            case 'tra'
                dims = 'zx';
            otherwise
                errorViewType
        end
        
        switch g.kb.Key
            case 'leftarrow'
                dim = dims(1);
                shift = '-1';
            case 'rightarrow'
                dim = dims(1);
                shift = '+1';
            case 'downarrow'
                dim = dims(2);
                shift = '+1';
            case 'uparrow'
                dim = dims(2);
                shift = '-1';
            otherwise
                error('Uknown arrow key.')
        end
        eval(['val = g.pos.sys.' dim shift ';'])
        if val>1 & val<g.PARAM.COORD.SIZE
            eval(['g.pos.sys.' dim ' = val;'])
            updatePosition_SYS(g.pos.sys.x,g.pos.sys.y,g.pos.sys.z)
            draw
        end
    end
end

function callbackKeyUp(fig,evt)
    global g
    g.kb = evt;
    
    if strcmp(g.kb.Key,'v')
        computeMaskVoxels;
        draw
    elseif strcmp(g.kb.Key,'alt')
        g.draw_instance.highlight = nan;
        draw
    elseif strcmp(g.kb.Key,'shift')
        if ~isnan(g.draw_instance.highlight)
            g.mask.masks(g.mask.active).vertices(g.draw_instance.highlight,:) = [];
            g.draw_instance.highlight = nan;
            computeMaskVoxels;
            draw
        end
    end
    
    if any(strcmp(g.kb.Modifier,'alt'))
        g.kb.Key = 'alt';
    else
		mod = g.kb.Modifier;
        g.kb = [];
		g.kb.Key = '';
		g.kb.Modifier = mod;
    end
    set(0,'CurrentFigure',g.fig.main)
end

function callbackDelete(fig,evt)
    global g
    saveSession(g.PARAM.FILENAME.PRIOR)
    closeAllFigures
end

function callbackMaskNew(fig,evt)
    name = newid('Mask Name:','New Mask');
    if ~length(name)
        return
    else
        createMask(name{1});
    end
end

function callbackMaskDel(fig,evt)
    global g
    g.mask.masks(g.mask.active) = [];
    if g.mask.active > length(g.mask.masks)
        g.mask.active = g.mask.active - 1;
    end
    if g.mask.active <= 0
        createMask;
    else
        draw
    end
    updateMaskList
end

function callbackMaskRename(fig,evt)
    global g
    while 1
        name = newid('Mask Name:','New Mask');
        if ~length(name)
            return
        end
        name = name{1};
        if isValidMaskName(name)
            break
        end
    end
    g.mask.masks(g.mask.active).name = name;
    updateMaskList
end

function callbackMaskOptimize(fig,evt)
    global g
    
    m = msgbox('Optimizing mask vertices...');
    
    %remove duplicates
    vertices = g.mask.masks(g.mask.active).vertices;
    vertices = unique(vertices,'rows');

    %compute number of voxels
    number_voxels = computeMaskVoxels(true,vertices);
    
    %find redundant vertices
    number_vertices = size(vertices,1);
    if number_vertices>1
        for v = number_vertices:-1:1
            vert = vertices;
            vert(v,:) = [];
            vox = computeMaskVoxels(true,vert);
            if vox == number_voxels
                vertices(v,:) = [];
            end
        end
    end
    
    %update
    g.mask.masks(g.mask.active).vertices = vertices;
    
    if isgraphics(m)
        delete(m)
    end
    
    draw
end

function callbackMaskList(fig,evt)
    global g
    g.mask.active = get(g.tag.mask.list,'Value');
    draw
    updateMaskList
end

function callbackShiftFocusRelay(fig,evt,next_function)
    id = gco;
    set(id,'Enable','off')
    drawnow
    set(id,'Enable','on')
    if isa(next_function,'function_handle')
        next_function()
    end
end

%% Menu Callbacks

function menu_file_new(fig,evt)
    %recall main
    Brain_Drawing_Tool(false)
end

function menu_file_load(fig,evt)
    loadSession
end

function menu_file_save(fig,evt)
    global g
    saveSession(g.filepath.save)
end

function menu_file_saveas(fig,evt)
    saveSession
end

function menu_file_load_vmr(fig,evt)
    loadVMR
end

function menu_file_load_vmp(fig,evt)
    loadVMP
end

function menu_file_import_voi(fig,evt)
    importVOI
end

function menu_file_export_msk(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_file_export_voi(fig,evt)
    exportVOI
end

function menu_file_export_vmp_map(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_file_export_vmp_mask(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_view_default(fig,evt)
    setView('default')
end

function menu_view_sag(fig,evt)
    setView('sag')
end

function menu_view_cor(fig,evt)
    setView('cor')
end

function menu_view_tra(fig,evt)
    setView('tra')
end

function menu_view_radio(fig,evt)
    setFlipLR(false)
end

function menu_view_neuro(fig,evt)
	setFlipLR(true)
end

function menu_view_crosshair(fig,evt)
    setCrosshair
end

function menu_mask_mask_brain_this(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_mask_mask_brain_all(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_mask_mask_vmp_this(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_mask_mask_vmp_all(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_drawing_size(fig,evt)
    global g
    size = newid('Brush Size:','Set Brush Size',1,{num2str(g.draw.brush_size)});
    if ~length(size)
        return
    end
    size = size{1};
    size = str2num(size);
    if ~length(size)
        return
    end
    setBrush(size)
    updateMenuChecks
end

function menu_drawing_2D(fig,evt)
    global g
    g.draw.brush_dim = 2;
    updateMenuChecks
end

function menu_drawing_3D(fig,evt)
    global g
    g.draw.brush_dim = 3;
    updateMenuChecks
end

function menu_mask_separate_voxels(fig,evt)
    global g
    g.draw.separate_voxels = ~g.draw.separate_voxels;
    updateMenuChecks
    draw
end

function menu_create_clone(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_create_combine_vertex(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_create_combine_voxel_and(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_create_combine_voxel_or(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_create_sphere(fig,evt)
    global g
    old_size = g.draw.brush_size;
    size = newid('Brush Size:','Set Brush Size',1,{num2str(g.draw.brush_size)});
    if ~length(size)
        return
    end
    size = size{1};
    size = str2num(size);
    if ~length(size)
        return
    end
    setBrush(size)
    brush([g.pos.sys.x g.pos.sys.y g.pos.sys.z],g.view.display,false)
    setBrush(old_size)
end

function menu_vmp_show(fig,evt)
    global g
    g.vmp.show = ~g.vmp.show;
    updateMenuChecks
    draw
end

function menu_vmp_menu(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_vmp_search_max(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_vmp_search_min(fig,evt)
    errordlg('This operation has not been implemented.');
end

function menu_settings_large_saves(fig,evt)
    global g
    g.settings.large_saves = ~g.settings.large_saves;
    updateMenuChecks
end

function menu_help_hotkey(fig,evt)
    helpdlg(sprintf(['LEFT-CLICK/DRAG: Navigate\n\n' ...
                     'ALT+RIGHT-CLICK: Change View\n\n' ...
                     'ARROW KEYS: Navigate\n\n' ...
                     '--------------------------------------------------------------\n\n' ...
                     'V: Add Vertex\n\n', ...
                     'ALT: Select Nearest Vertex\n\n' ...
                     'ALT+LEFT-CLICK: Move Selected Vertex\n\n' ...
                     'ALT+SHIFT: Delete Selected Vertex\n\n' ...
                     '--------------------------------------------------------------\n\n' ...
                     'CTRL+CLICK: Draw\n\n' ...
                     'CTRL+SHIFT+CLICK: Erase\n\n' ...
                     '--------------------------------------------------------------\n\n' ...
                     'CTRL+S: Save\n\n' ...
                     ]),'Hotkeys')
end

%% Error Messages
function errorViewType
    error('Unknown view type.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function used for searching voxels within polyhedron from vertices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % Copyright (c) 2009, John D'Errico
% % All rights reserved.
% % 
% % Redistribution and use in source and binary forms, with or without
% % modification, are permitted provided that the following conditions are
% % met:
% % 
% %     * Redistributions of source code must retain the above copyright
% %       notice, this list of conditions and the following disclaimer.
% %     * Redistributions in binary form must reproduce the above copyright
% %       notice, this list of conditions and the following disclaimer in
% %       the documentation and/or other materials provided with the distribution
% % 
% % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% % AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% % IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% % ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% % LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% % CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% % SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% % INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% % CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% % ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% % POSSIBILITY OF SUCH DAMAGE.
function in = inhull(testpts,xyz,tess,tol)
% inhull: tests if a set of points are inside a convex hull
% usage: in = inhull(testpts,xyz)
% usage: in = inhull(testpts,xyz,tess)
% usage: in = inhull(testpts,xyz,tess,tol)
%
% arguments: (input)
%  testpts - nxp array to test, n data points, in p dimensions
%       If you have many points to test, it is most efficient to
%       call this function once with the entire set.
%
%  xyz - mxp array of vertices of the convex hull, as used by
%       convhulln.
%
%  tess - tessellation (or triangulation) generated by convhulln
%       If tess is left empty or not supplied, then it will be
%       generated.
%
%  tol - (OPTIONAL) tolerance on the tests for inclusion in the
%       convex hull. You can think of tol as the distance a point
%       may possibly lie outside the hull, and still be perceived
%       as on the surface of the hull. Because of numerical slop
%       nothing can ever be done exactly here. I might guess a
%       semi-intelligent value of tol to be
%
%         tol = 1.e-13*mean(abs(xyz(:)))
%
%       In higher dimensions, the numerical issues of floating
%       point arithmetic will probably suggest a larger value
%       of tol.
%
%       DEFAULT: tol = 0
%
% arguments: (output)
%  in  - nx1 logical vector
%        in(i) == 1 --> the i'th point was inside the convex hull.
%  
% Example usage: The first point should be inside, the second out
%
%  xy = randn(20,2);
%  tess = convhulln(xy);
%  testpoints = [ 0 0; 10 10];
%  in = inhull(testpoints,xy,tess)
%
% in = 
%      1
%      0
%
% A non-zero count of the number of degenerate simplexes in the hull
% will generate a warning (in 4 or more dimensions.) This warning
% may be disabled off with the command:
%
%   warning('off','inhull:degeneracy')
%
% See also: convhull, convhulln, delaunay, delaunayn, tsearch, tsearchn
%
% Author: John D'Errico
% e-mail: woodchips@rochester.rr.com
% Release: 3.0
% Release date: 10/26/06

% get array sizes
% m points, p dimensions
p = size(xyz,2);
[n,c] = size(testpts);
if p ~= c
  error 'testpts and xyz must have the same number of columns'
end
if p < 2
  error 'Points must lie in at least a 2-d space.'
end

% was the convex hull supplied?
if (nargin<3) || isempty(tess)
  tess = convhulln(xyz);
end
[nt,c] = size(tess);
if c ~= p
  error 'tess array is incompatible with a dimension p space'
end

% was tol supplied?
if (nargin<4) || isempty(tol)
  tol = 0;
end

% build normal vectors
switch p
  case 2
    % really simple for 2-d
    nrmls = (xyz(tess(:,1),:) - xyz(tess(:,2),:)) * [0 1;-1 0];
    
    % Any degenerate edges?
    del = sqrt(sum(nrmls.^2,2));
    degenflag = (del<(max(del)*10*eps));
    if sum(degenflag)>0
      warning('inhull:degeneracy',[num2str(sum(degenflag)), ...
        ' degenerate edges identified in the convex hull'])
      
      % we need to delete those degenerate normal vectors
      nrmls(degenflag,:) = [];
      nt = size(nrmls,1);
    end
  case 3
    % use vectorized cross product for 3-d
    ab = xyz(tess(:,1),:) - xyz(tess(:,2),:);
    ac = xyz(tess(:,1),:) - xyz(tess(:,3),:);
    nrmls = cross(ab,ac,2);
    degenflag = false(nt,1);
  otherwise
    % slightly more work in higher dimensions, 
    nrmls = zeros(nt,p);
    degenflag = false(nt,1);
    for i = 1:nt
      % just in case of a degeneracy
      % Note that bsxfun COULD be used in this line, but I have chosen to
      % not do so to maintain compatibility. This code is still used by
      % users of older releases.
      %  nullsp = null(bsxfun(@minus,xyz(tess(i,2:end),:),xyz(tess(i,1),:)))';
      nullsp = null(xyz(tess(i,2:end),:) - repmat(xyz(tess(i,1),:),p-1,1))';
      if size(nullsp,1)>1
        degenflag(i) = true;
        nrmls(i,:) = NaN;
      else
        nrmls(i,:) = nullsp;
      end
    end
    if sum(degenflag)>0
      warning('inhull:degeneracy',[num2str(sum(degenflag)), ...
        ' degenerate simplexes identified in the convex hull'])
      
      % we need to delete those degenerate normal vectors
      nrmls(degenflag,:) = [];
      nt = size(nrmls,1);
    end
end

% scale normal vectors to unit length
nrmllen = sqrt(sum(nrmls.^2,2));
% again, bsxfun COULD be employed here...
%  nrmls = bsxfun(@times,nrmls,1./nrmllen);
nrmls = nrmls.*repmat(1./nrmllen,1,p);

% center point in the hull
center = mean(xyz,1);

% any point in the plane of each simplex in the convex hull
a = xyz(tess(~degenflag,1),:);

% ensure the normals are pointing inwards
% this line too could employ bsxfun...
%  dp = sum(bsxfun(@minus,center,a).*nrmls,2);
dp = sum((repmat(center,nt,1) - a).*nrmls,2);
k = dp<0;
nrmls(k,:) = -nrmls(k,:);

% We want to test if:  dot((x - a),N) >= 0
% If so for all faces of the hull, then x is inside
% the hull. Change this to dot(x,N) >= dot(a,N)
aN = sum(nrmls.*a,2);

% test, be careful in case there are many points
in = false(n,1);

% if n is too large, we need to worry about the
% dot product grabbing huge chunks of memory.
memblock = 1e6;
blocks = max(1,floor(n/(memblock/nt)));
aNr = repmat(aN,1,length(1:blocks:n));
for i = 1:blocks
   j = i:blocks:n;
   if size(aNr,2) ~= length(j),
      aNr = repmat(aN,1,length(j));
   end
   in(j) = all((nrmls*testpts(j,:)' - aNr) >= -tol,1)';
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Input Dialogue that accepts ENTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Answer=newid(Prompt, Title, NumLines, DefAns, Resize)
%INPUTDLG Input dialog box.
%  ANSWER = INPUTDLG(PROMPT) creates a modal dialog box that returns user
%  input for multiple prompts in the cell array ANSWER. PROMPT is a cell
%  array containing the PROMPT strings.
%
%  INPUTDLG uses UIWAIT to suspend execution until the user responds.
%
%  ANSWER = INPUTDLG(PROMPT,NAME) specifies the title for the dialog.
%
%  ANSWER = INPUTDLG(PROMPT,NAME,NUMLINES) specifies the number of lines for
%  each answer in NUMLINES. NUMLINES may be a constant value or a column
%  vector having one element per PROMPT that specifies how many lines per
%  input field. NUMLINES may also be a matrix where the first column
%  specifies how many rows for the input field and the second column
%  specifies how many columns wide the input field should be.
%
%  ANSWER = INPUTDLG(PROMPT,NAME,NUMLINES,DEFAULTANSWER) specifies the
%  default answer to display for each PROMPT. DEFAULTANSWER must contain
%  the same number of elements as PROMPT and must be a cell array of
%  strings.
%
%  ANSWER = INPUTDLG(PROMPT,NAME,NUMLINES,DEFAULTANSWER,OPTIONS) specifies
%  additional options. If OPTIONS is the string 'on', the dialog is made
%  resizable. If OPTIONS is a structure, the fields Resize, WindowStyle, and
%  Interpreter are recognized. Resize can be either 'on' or
%  'off'. WindowStyle can be either 'normal' or 'modal'. Interpreter can be
%  either 'none' or 'tex'. If Interpreter is 'tex', the prompt strings are
%  rendered using LaTeX.
%
%  Examples:
%
%  prompt={'Enter the matrix size for x^2:','Enter the colormap name:'};
%  name='Input for Peaks function';
%  numlines=1;
%  defaultanswer={'20','hsv'};
%
%  answer=inputdlg(prompt,name,numlines,defaultanswer);
%
%  options.Resize='on';
%  options.WindowStyle='normal';
%  options.Interpreter='tex';
%
%  answer=inputdlg(prompt,name,numlines,defaultanswer,options);
%
%  See also DIALOG, ERRORDLG, HELPDLG, LISTDLG, MSGBOX,
%    QUESTDLG, TEXTWRAP, UIWAIT, WARNDLG .

%  Copyright 1994-2005 The MathWorks, Inc.
%  $Revision: 1.58.4.11 $

%%%%%%%%%%%%%%%%%%%%
%%% Nargin Check %%%
%%%%%%%%%%%%%%%%%%%%
error(nargchk(0,5,nargin));
error(nargoutchk(0,1,nargout));

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Handle Input Args %%%
%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<1
    Prompt='Input:';
end
if ~iscell(Prompt)
    Prompt={Prompt};
end
NumQuest=numel(Prompt);


if nargin<2,
    Title=' ';
end

if nargin<3
    NumLines=1;
end

if nargin<4 
    DefAns=cell(NumQuest,1);
    for lp=1:NumQuest
        DefAns{lp}='';
    end
end

if nargin<5
    Resize = 'off';
end
WindowStyle='modal';
Interpreter='none';

Options = struct([]); %#ok
if nargin==5 && isstruct(Resize)
    Options = Resize;
    Resize  = 'off';
    if isfield(Options,'Resize'),      Resize=Options.Resize;           end
    if isfield(Options,'WindowStyle'), WindowStyle=Options.WindowStyle; end
    if isfield(Options,'Interpreter'), Interpreter=Options.Interpreter; end
end

[rw,cl]=size(NumLines);
OneVect = ones(NumQuest,1);
if (rw == 1 & cl == 2) %#ok Handle []
    NumLines=NumLines(OneVect,:);
elseif (rw == 1 & cl == 1) %#ok
    NumLines=NumLines(OneVect);
elseif (rw == 1 & cl == NumQuest) %#ok
    NumLines = NumLines';
elseif (rw ~= NumQuest | cl > 2) %#ok
    error('MATLAB:inputdlg:IncorrectSize', 'NumLines size is incorrect.')
end

if ~iscell(DefAns),
    error('MATLAB:inputdlg:InvalidDefaultAnswer', 'Default Answer must be a cell array of strings.');
end

%%%%%%%%%%%%%%%%%%%%%%%
%%% Create InputFig %%%
%%%%%%%%%%%%%%%%%%%%%%%
FigWidth=175;
FigHeight=100;
FigPos(3:4)=[FigWidth FigHeight];  %#ok
FigColor=get(0,'DefaultUicontrolBackgroundcolor');

InputFig=dialog(                     ...
    'Visible'          ,'off'      , ...
    'KeyPressFcn'      ,@doFigureKeyPress, ...
    'Name'             ,Title      , ...
    'Pointer'          ,'arrow'    , ...
    'Units'            ,'pixels'   , ...
    'UserData'         ,'Cancel'   , ...
    'Tag'              ,Title      , ...
    'HandleVisibility' ,'callback' , ...
    'Color'            ,FigColor   , ...
    'NextPlot'         ,'add'      , ...
    'WindowStyle'      ,WindowStyle, ...
    'DoubleBuffer'     ,'on'       , ...
    'Resize'           ,Resize       ...
    );


%%%%%%%%%%%%%%%%%%%%%
%%% Set Positions %%%
%%%%%%%%%%%%%%%%%%%%%
DefOffset    = 5;
DefBtnWidth  = 53;
DefBtnHeight = 23;

TextInfo.Units              = 'pixels'   ;   
TextInfo.FontSize           = get(0,'FactoryUIControlFontSize');
TextInfo.FontWeight         = get(InputFig,'DefaultTextFontWeight');
TextInfo.HorizontalAlignment= 'left'     ;
TextInfo.HandleVisibility   = 'callback' ;

StInfo=TextInfo;
StInfo.Style              = 'text'  ;
StInfo.BackgroundColor    = FigColor;


EdInfo=StInfo;
EdInfo.FontWeight      = get(InputFig,'DefaultUicontrolFontWeight');
EdInfo.Style           = 'edit';
EdInfo.BackgroundColor = 'white';

BtnInfo=StInfo;
BtnInfo.FontWeight          = get(InputFig,'DefaultUicontrolFontWeight');
BtnInfo.Style               = 'pushbutton';
BtnInfo.HorizontalAlignment = 'center';

% Add VerticalAlignment here as it is not applicable to the above.
TextInfo.VerticalAlignment  = 'bottom';
TextInfo.Color              = get(0,'FactoryUIControlForegroundColor');


% adjust button height and width
btnMargin=1.4;
ExtControl=uicontrol(InputFig   ,BtnInfo     , ...
                     'String'   ,'OK'        , ...
                     'Visible'  ,'off'         ...
                     );

% BtnYOffset  = DefOffset;
BtnExtent = get(ExtControl,'Extent');
BtnWidth  = max(DefBtnWidth,BtnExtent(3)+8);
BtnHeight = max(DefBtnHeight,BtnExtent(4)*btnMargin);
delete(ExtControl);

% Determine # of lines for all Prompts
TxtWidth=FigWidth-2*DefOffset;
ExtControl=uicontrol(InputFig   ,StInfo     , ...
                     'String'   ,''         , ...
                     'Position' ,[ DefOffset DefOffset 0.96*TxtWidth BtnHeight ] , ...
                     'Visible'  ,'off'        ...
                     );

WrapQuest=cell(NumQuest,1);
QuestPos=zeros(NumQuest,4);

for ExtLp=1:NumQuest
    if size(NumLines,2)==2
        [WrapQuest{ExtLp},QuestPos(ExtLp,1:4)]= ...
            textwrap(ExtControl,Prompt(ExtLp),NumLines(ExtLp,2));
    else
        [WrapQuest{ExtLp},QuestPos(ExtLp,1:4)]= ...
            textwrap(ExtControl,Prompt(ExtLp),80);
    end
end % for ExtLp

delete(ExtControl);
QuestWidth =QuestPos(:,3);
QuestHeight=QuestPos(:,4);

TxtHeight=QuestHeight(1)/size(WrapQuest{1,1},1);
EditHeight=TxtHeight*NumLines(:,1);
EditHeight(NumLines(:,1)==1)=EditHeight(NumLines(:,1)==1)+4;

FigHeight=(NumQuest+2)*DefOffset    + ...
          BtnHeight+sum(EditHeight) + ...
          sum(QuestHeight);

TxtXOffset=DefOffset;

QuestYOffset=zeros(NumQuest,1);
EditYOffset=zeros(NumQuest,1);
QuestYOffset(1)=FigHeight-DefOffset-QuestHeight(1);
EditYOffset(1)=QuestYOffset(1)-EditHeight(1);

for YOffLp=2:NumQuest,
    QuestYOffset(YOffLp)=EditYOffset(YOffLp-1)-QuestHeight(YOffLp)-DefOffset;
    EditYOffset(YOffLp)=QuestYOffset(YOffLp)-EditHeight(YOffLp);
end % for YOffLp

QuestHandle=[]; %#ok
EditHandle=[];

AxesHandle=axes('Parent',InputFig,'Position',[0 0 1 1],'Visible','off');

inputWidthSpecified = false;

for lp=1:NumQuest,
    if ~ischar(DefAns{lp}),
        delete(InputFig);
        %error('Default Answer must be a cell array of strings.');
        error('MATLAB:inputdlg:InvalidInput', 'Default Answer must be a cell array of strings.');
    end

    EditHandle(lp)=uicontrol(InputFig    , ...
                             EdInfo      , ...
                             'Max'        ,NumLines(lp,1)       , ...
                             'Position'   ,[ TxtXOffset EditYOffset(lp) TxtWidth EditHeight(lp) ], ...
                             'String'     ,DefAns{lp}           , ...
                             'Tag'        ,'Edit',                ...
                              'Callback' ,@doEnter);
                             

    QuestHandle(lp)=text('Parent'     ,AxesHandle, ...
                         TextInfo     , ...
                         'Position'   ,[ TxtXOffset QuestYOffset(lp)], ...
                         'String'     ,WrapQuest{lp}                 , ...
                         'Interpreter',Interpreter                   , ...
                         'Tag'        ,'Quest'                         ...
                         );

    MinWidth = max(QuestWidth(:));
    if (size(NumLines,2) == 2)
        % input field width has been specified.
        inputWidthSpecified = true;
        EditWidth = setcolumnwidth(EditHandle(lp), NumLines(lp,1), NumLines(lp,2));
        MinWidth = max(MinWidth, EditWidth);
    end
    FigWidth=max(FigWidth, MinWidth+2*DefOffset);

end % for lp

% fig width may have changed, update the edit fields if they dont have user specified widths.
if ~inputWidthSpecified
    TxtWidth=FigWidth-2*DefOffset;
    for lp=1:NumQuest
        set(EditHandle(lp), 'Position', [TxtXOffset EditYOffset(lp) TxtWidth EditHeight(lp)]);
    end
end

FigPos=get(InputFig,'Position');

FigWidth=max(FigWidth,2*(BtnWidth+DefOffset)+DefOffset);
FigPos(1)=0;
FigPos(2)=0;
FigPos(3)=FigWidth;
FigPos(4)=FigHeight;

set(InputFig,'Position',getnicedialoglocation(FigPos,get(InputFig,'Units')));

OKHandle=uicontrol(InputFig     ,              ...
                   BtnInfo      , ...
                   'Position'   ,[ FigWidth-2*BtnWidth-2*DefOffset DefOffset BtnWidth BtnHeight ] , ...
                   'KeyPressFcn',@doControlKeyPress , ...
                   'String'     ,'OK'        , ...
                   'Callback'   ,@doCallback , ...
                   'Tag'        ,'OK'        , ...
                   'UserData'   ,'OK'          ...
                   );

setdefaultbutton(InputFig, OKHandle);

CancelHandle=uicontrol(InputFig     ,              ...
                       BtnInfo      , ...
                       'Position'   ,[ FigWidth-BtnWidth-DefOffset DefOffset BtnWidth BtnHeight ]           , ...
                       'KeyPressFcn',@doControlKeyPress            , ...
                       'String'     ,'Cancel'    , ...
                       'Callback'   ,@doCallback , ...
                       'Tag'        ,'Cancel'    , ...
                       'UserData'   ,'Cancel'      ...
                       ); %#ok

handles = guihandles(InputFig);
handles.MinFigWidth = FigWidth;
handles.FigHeight   = FigHeight;
handles.TextMargin  = 2*DefOffset;
guidata(InputFig,handles);
set(InputFig,'ResizeFcn', {@doResize, inputWidthSpecified});

% make sure we are on screen
movegui(InputFig)

% if there is a figure out there and it's modal, we need to be modal too
if ~isempty(gcbf) && strcmp(get(gcbf,'WindowStyle'),'modal')
    set(InputFig,'WindowStyle','modal');
end

set(InputFig,'Visible','on');
drawnow;

if ~isempty(EditHandle)
    uicontrol(EditHandle(1));
end

uiwait(InputFig);

if ishandle(InputFig)
    Answer={};
    if strcmp(get(InputFig,'UserData'),'OK'),
        Answer=cell(NumQuest,1);
        for lp=1:NumQuest,
            Answer(lp)=get(EditHandle(lp),{'String'});
        end
    end
    delete(InputFig);
else
    Answer={};
end

end

function doFigureKeyPress(obj, evd) %#ok
switch(evd.Key)
 case {'return','space'}
  set(gcbf,'UserData','OK');
  uiresume(gcbf);
 case {'escape'}
  delete(gcbf);
end

end

function doControlKeyPress(obj, evd) %#ok
switch(evd.Key)
 case {'return'}
  if ~strcmp(get(obj,'UserData'),'Cancel')
      set(gcbf,'UserData','OK');
      uiresume(gcbf);
  else
      delete(gcbf)
  end
 case 'escape'
  delete(gcbf)
end

end

function doCallback(obj, evd) %#ok
if ~strcmp(get(obj,'UserData'),'Cancel')
    set(gcbf,'UserData','OK');
    uiresume(gcbf);
else
    delete(gcbf)
end

end

function doEnter(obj, evd) %#ok

h = get(obj,'Parent');
x = get(h,'CurrentCharacter');
if unicode2native(x) == 13
    doCallback(obj,evd);
end

end

function doResize(FigHandle, evd, multicolumn) %#ok
% TBD: Check difference in behavior w/ R13. May need to implement
% additional resize behavior/clean up.

Data=guidata(FigHandle);

resetPos = false; 

FigPos = get(FigHandle,'Position');
FigWidth = FigPos(3);
FigHeight = FigPos(4);

if FigWidth < Data.MinFigWidth
    FigWidth  = Data.MinFigWidth;
    FigPos(3) = Data.MinFigWidth;
    resetPos = true;
end

% make sure edit fields use all available space if 
% number of columns is not specified in dialog creation.
if ~multicolumn
    for lp = 1:length(Data.Edit)
        EditPos = get(Data.Edit(lp),'Position');
        EditPos(3) = FigWidth - Data.TextMargin;
        set(Data.Edit(lp),'Position',EditPos);
    end
end

if FigHeight ~= Data.FigHeight
    FigPos(4) = Data.FigHeight;
    resetPos = true;
end

if resetPos
    set(FigHandle,'Position',FigPos);  
end

end

% set pixel width given the number of columns
function EditWidth = setcolumnwidth(object, rows, cols)
% Save current Units and String.
old_units = get(object, 'Units');
old_string = get(object, 'String');
old_position = get(object, 'Position');

set(object, 'Units', 'pixels')
set(object, 'String', char(ones(1,cols)*'x'));

new_extent = get(object,'Extent');
if (rows > 1)
    % For multiple rows, allow space for the scrollbar
    new_extent = new_extent + 19; % Width of the scrollbar
end
new_position = old_position;
new_position(3) = new_extent(3) + 1;
set(object, 'Position', new_position);

% reset string and units
set(object, 'String', old_string, 'Units', old_units);

EditWidth = new_extent(3);

end

function figure_size = getnicedialoglocation(figure_size, figure_units)
% adjust the specified figure position to fig nicely over GCBF
% or into the upper 3rd of the screen

%  Copyright 1999-2010 The MathWorks, Inc.

parentHandle = gcbf;
convertData.destinationUnits = figure_units;
if ~isempty(parentHandle)
    % If there is a parent figure
    convertData.hFig = parentHandle;
    convertData.size = get(parentHandle,'Position');
    convertData.sourceUnits = get(parentHandle,'Units');  
    c = []; 
else
    % If there is no parent figure, use the root's data
    % and create a invisible figure as parent
    convertData.hFig = figure('visible','off');
    convertData.size = get(0,'ScreenSize');
    convertData.sourceUnits = get(0,'Units');
    c = onCleanup(@() close(convertData.hFig));
end

% Get the size of the dialog parent in the dialog units
container_size = hgconvertunits(convertData.hFig, convertData.size ,...
    convertData.sourceUnits, convertData.destinationUnits, get(convertData.hFig,'Parent'));

delete(c);

figure_size(1) = container_size(1)  + 1/2*(container_size(3) - figure_size(3));
figure_size(2) = container_size(2)  + 2/3*(container_size(4) - figure_size(4));

end

function setdefaultbutton(figHandle, btnHandle)
% WARNING: This feature is not supported in MATLAB and the API and
% functionality may change in a future release.

%SETDEFAULTBUTTON Set default button for a figure.
%  SETDEFAULTBUTTON(BTNHANDLE) sets the button passed in to be the default button
%  (the button and callback used when the user hits "enter" or "return"
%  when in a dialog box.
%
%  This function is used by inputdlg.m, msgbox.m, questdlg.m and
%  uigetpref.m.
%
%  Example:
%
%  f = figure;
%  b1 = uicontrol('style', 'pushbutton', 'string', 'first', ...
%       'position', [100 100 50 20]);
%  b2 = uicontrol('style', 'pushbutton', 'string', 'second', ...
%       'position', [200 100 50 20]);
%  b3 = uicontrol('style', 'pushbutton', 'string', 'third', ...
%       'position', [300 100 50 20]);
%  setdefaultbutton(b2);
%

%  Copyright 2005-2007 The MathWorks, Inc.

%--------------------------------------- NOTE ------------------------------------------
% This file was copied into matlab/toolbox/local/private.
% These two files should be kept in sync - when editing please make sure
% that *both* files are modified.

% Nargin Check
narginchk(1,2)

if (usejava('awt') == 1)
    % We are running with Java Figures
    useJavaDefaultButton(figHandle, btnHandle)
else
    % We are running with Native Figures
    useHGDefaultButton(figHandle, btnHandle);
end

    function useJavaDefaultButton(figH, btnH)
        % Get a UDD handle for the figure.
        fh = handle(figH);
        % Call the setDefaultButton method on the figure handle
        fh.setDefaultButton(btnH);
    end

    function useHGDefaultButton(figHandle, btnHandle)
        % First get the position of the button.
        btnPos = getpixelposition(btnHandle);

        % Next calculate offsets.
        leftOffset   = btnPos(1) - 1;
        bottomOffset = btnPos(2) - 2;
        widthOffset  = btnPos(3) + 3;
        heightOffset = btnPos(4) + 3;

        % Create the default button look with a uipanel.
        % Use black border color even on Mac or Windows-XP (XP scheme) since
        % this is in natve figures which uses the Win2K style buttons on Windows
        % and Motif buttons on the Mac.
        h1 = uipanel(get(btnHandle, 'Parent'), 'HighlightColor', 'black', ...
            'BorderType', 'etchedout', 'units', 'pixels', ...
            'Position', [leftOffset bottomOffset widthOffset heightOffset]);

        % Make sure it is stacked on the bottom.
        uistack(h1, 'bottom');
    end
end