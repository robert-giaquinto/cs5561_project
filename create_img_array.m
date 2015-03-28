function img_array = create_img_array(file_name)
% load all the gif images
gif_data = importdata(file_name);
imgs = gif_data.cdata;
map = gif_data.colormap;

% convert from location + map to an image array
num_frames = size(imgs, 4);
img_sz = [size(imgs, 1) size(imgs, 2)];
% initialize output array
img_array = zeros([img_sz(1) img_sz(2) 3 num_frames]);
for frame=1:num_frames
    img_array(:,:, :, frame) = ind2rgb(imgs(:,:, 1, frame), map);
end
end