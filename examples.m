% where are files located?
if strcmp(char(getHostAddress(java.net.InetAddress.getLocalHost)), '134.84.90.159')
    cd('/Users/robert/documents/UMN/5561_CV/project/code');
    data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
else
    cd('/Users/robert/documents/UMN/5561_CV/project/code');
    data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
end
file_names = dir(strcat(data_dir, '*.gif'));



% READ IN GIF, PUT IN IMAGE ARRAY
file = file_names(1);
file_name = strcat(data_dir, file.name);
img_array = create_img_array(file_name);
% display 10th image
img = img_array(:,:,:,10);
imshow(uint8(img*255)); title('Image from GIF, stored in 4D array');


% CONVERT 4D array to matrix for analysis
img_mat = array_to_matrix(img_array);
size(img_mat)

% CONVERT image matrix back to a viewable 4D array
img_array2 = matrix_to_array(img_mat, 480, 480);
img = img_array2(:,:,:,1)*255;
% does it look the same as original? yes.
figure('Name','Original Preserved','NumberTitle','off');
imshow(uint8(img)); title('Transformation Back to Original');


% CREATE BACKGROUND MODEL
% need to put images into a matrix form!!!!
% split image array into a training and test set
training_sz = 40;
x_train = img_mat(1:training_sz, :);
back_vec = background_model(x_train, 'median', 5);
back_img = matrix_to_array(back_vec, 480, 480);
imshow(uint8(back_img*255)); title('Background Image');


% CREATE FOREGROUND MASK
threshold = .45;
fore_mask = foreground_mask(back_vec, img_mat, threshold);
fore_mask_img = matrix_to_array(fore_mask, 480, 480);
figure('Name','Foreground Mask','NumberTitle','off');
for i = 1:9
    frame = fore_mask_img(:,:,:, i);
    subplot(3, 3, i);
    plot_title = sprintf('Frame %d', i);
    imshow(uint8(frame*255)); title(plot_title);
end

% EIGENBACKGROUND ALGORITHM: show only foreground
% applies some of the functions used above all in one step
fore_mat = eigenback(x_train, img_mat, threshold, 'median', 5);
fore_img = matrix_to_array(fore_mat, 480, 480);
figure('Name','Foreground Images','NumberTitle','off');
for i = 2:18
    if mod(i, 2) == 0
        frame = fore_img(:,:,:, i) * 255;
        subplot(3, 3, i/2);
        plot_title = sprintf('Frame %d', i);
        imshow(uint8(frame)); title(plot_title);
    end
end
