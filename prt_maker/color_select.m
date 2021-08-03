% updated colours - 10*5 selections

function [colour_pick] = color_select()

% Loads colour bar for display and selection of condition colours.

colourbar = imread('colour_swatch_new.jpg');
hh = figure;
xx=[0:5];yy=[0:10];
imagesc(xx,yy,colourbar);
axis off;
set(hh,'Position',[905 98 150 800]);
set(hh,'menubar','none');
hhh=title('COLOURS');
set(hhh,'fontsize',15);
[x,y]=ginput(1);
close

colours=[255 255 255;225 225 225;155 155 155;120 120 120;80 80 80;255 220 220;255 155 155;255 100 100;255 0 0;200 0 0;255 193 230;255 129 231;255 35 213;208 0 168;146 0 118;240 215 255;221 165 255;199 109 255;177 51 255;121 0 196;196 193 255;162 157 255;116 109 255;42 31 255;9 0 188;193 239 255;141 225 255;91 212 255;0 187 254;0 136 184;193 255 239;141 255 225;71 255 207;0 216 159;0 150 111;194 254 197;151 253 156;90 252 98;4 208 14;3 135 9;254 254 194;252 252 104;236 231 5;200 195 4;139 136 3;254 222 190;253 192 131;252 165 78;244 124 4;193 98 3];

coord=(ceil(y)-1)*5+ceil(x);

colour_pick=colours(coord,:,:);

