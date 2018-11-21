%Uses "modify_image_filename.m", which will need to be modified if image
%filenames do not exactly match predictor names

function ROI_Image_MDS

%% parameters

%loaded images
image_folder = [pwd filesep 'images' filesep];
image_filetype = 'jpg';
scale_images = 0.25;
transparency_colour = [255 255 255];
transparency_threshold = 5;

%output image
image_output = [pwd filesep 'image_mds' filesep];
colour_background = [255 255 255];
area_size_pixels = 2000;

%% run

%make output folder if needed
if ~exist(image_output, 'dir')
    mkdir(image_output)
end

try
    %remember where to come back to
    return_path = pwd;
    
    %move to main folder
    cd ..
    
    %get params
    p = ALL_STEP0_PARAMETERS;
    
    %load coords
    fp_data = [p.FILEPATH_TO_SAVE_LOCATION p.SUBFOLDER_ROI_DATA filesep '8. Figures' filesep 'COND MDS' filesep 'mds_data.mat'];
    if ~exist(fp_data,'file')
        error('MDS data file not found! (%s)', fp_data)
    else
        load(fp_data);
    end
    
    %return to aux folder
    cd(return_path);
    
    %load all images
    num_cond = length(CONDITIONS);
    fprintf('Reading images in %s\n', image_folder);
    for c = 1:num_cond
        cond_name = CONDITIONS{c};
        fn = [modify_image_filename(cond_name) '.' image_filetype];
        fp = [image_folder fn];
        fprintf('%d of %d: %s ==> %s\n', c, num_cond, cond_name, fn)
        if ~exist(fp,'file')
            error('Cannot find image! (%s)', fp);
        else
            %load
            image = imread(fp);
            sz = size(image);
            
            %transparency
            trans_dif = mean(abs(single(image) - repmat(reshape(transparency_colour,[1 1 3]), [sz(1:2) 1])), 3);
            trans = trans_dif <= transparency_threshold;

            %resize
            images{c} = imresize(image, scale_images);
            foreground{c} = imresize(~trans, scale_images);
        end
    end
    
    %largest image dimension 
    largest_image_dim = max(cellfun(@(x) max(size(x)), images));
    adj = ((largest_image_dim / 2) / area_size_pixels) + 0.05;
    
    %create figures
    fig = figure('Position',get(0,'screensize'));
    num_voi = length(voi_names);
    fprintf('Create voi image mds in %s\n', image_output);
    for v = 1:num_voi
        voi_name = voi_names{v};
        fprintf('%d of %d: %s\n', v, num_voi, voi_name);
        
        MD2D = all_MD2D(:, :, v);
        
        %set range 0-1
        MD2D = MD2D - min(MD2D(:));
        MD2D = MD2D / max(MD2D(:));
        
        %adjust range so that no image is cutoff on the sides
        MD2D = round(((MD2D * (1 - (adj*2))) + adj) * area_size_pixels);
        
        %default figure
        output = uint8(repmat(reshape(colour_background, [1 1 3]), [area_size_pixels area_size_pixels]));
        
        %add condition images
        for c = 1:num_cond
            x = MD2D(c, 1);
            y = MD2D(c, 2);
            
            img = images{c};
            sz = size(img);
            ind = find(repmat(foreground{c}, [1 1 3]));
            [x_foreground, y_foreground, z_foreground] = ind2sub(sz, ind);
            x_foreground = round(x_foreground - (sz(1)/2) + x);
            y_foregorund = round(y_foreground - (sz(2)/2) + y);
            
            ind_fig = sub2ind(size(output), x_foreground, y_foregorund, z_foreground);
            
            output(ind_fig) = img(ind);
            
        end
        
        imagesc(output)
        title(strrep(voi_name,'_',' '));
        axis image
        drawnow
        
        fn = [image_output voi_name '.png'];
        fprintf('Writing: %s\n', fn);
        imwrite(output, fn, 'png');
    end
    close(fig);
    
    disp Complete!
    
catch err
    cd(return_path);
    rethrow(err)
end

