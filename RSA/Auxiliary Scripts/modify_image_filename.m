function [image_name] = modify_image_filename(condition_name)
image_name = condition_name;

%make any changes needed to get image filename from predictor name here:

% %Example: Carol 2018
% image_name(find(image_name==' ',1,'first')) = '_';
% image_name(find(image_name==' ',1,'first')) = '';