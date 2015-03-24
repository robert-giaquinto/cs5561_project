% apply simple background subtraction
% this is a test program for different bgs algos

% import a gif
cd('/Users/robert/documents/UMN/5561_CV/project/code');
data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
file_names = dir(strcat(data_dir, '*.gif'));
file = file_names(1);
file_name = strcat(data_dir, file.name);
img_array = create_img_array(file_name);


% attempt 1: average last 10 frames 
num_frames = size(img_array, 4);
img_sz = [size(img_array, 1) size(img_array, 2) size(img_array, 3)];
history_sz = 10;
for i=(history_sz+1):num_frames
    back_imgs = img_array(:, :, :, (i-history_sz):(i-1));
    back_avg = sum(back_imgs, 4) / history_sz;
end
% not bad
imshow(uint8(back_avg*255));
% subtract background from each image
for i=(history_sz+1):num_frames
    fore_img = abs(img_array(:,:,:,i) - back_avg);
    % apply thresholding
    for c=1:3
        col_channel = fore_img(:,:,c);
        t_high = .8 * max(max(col_channel));
        col_channel(col_channel < t_high) = 0;
        fore_img(:,:,c) = col_channel;
    end
    % find total pixel intensities over rows and columns for find
    % object centers
    gray_img = rgb2gray(fore_img);
    gray_img = gray_img - min(min(gray_img));
    gray_img = gray_img*255 / max(max(gray_img));
    imshow(uint8(gray_img));
    
end
% note: can find location using this:
row_sum = sum(gray_img, 1)'; %transpose to column vector
col_sum = sum(gray_img, 2);
bar(row_sum) % to view histogram of row location
bar(col_sum) % to view histogram of col location
% just need to extract row and column that has max on the barplot
    
    