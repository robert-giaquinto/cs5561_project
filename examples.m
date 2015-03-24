% where are files located?
cd('/Users/robert/documents/UMN/5561_CV/project/code');
data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
file_names = dir(strcat(data_dir, '*.gif'));

% READ IN GIF, PUT IN IMAGE ARRAY
file = file_names(1);
file_name = strcat(data_dir, file.name);
img_array = create_img_array(file_name);
% display 10th image
img = img_array(:,:,:,10);
imshow(uint8(img*255));

% CONVERT 4D array to matrix for analysis
img_mat = array_to_matrix(img_array);
size(img_mat)

% CONVERT image matrix back to a viewable 4D array
img_array2 = matrix_to_array(img_mat, 480, 480);
img = img_array2(:,:,:,1)*255;
% does it look the same as original? yes.
imshow(uint8(img));

% CREATE BACKGROUND MODEL
% need to put images into a matrix form!!!!
% split image array into a training and test set
training_sz = 40;
x_train = rgb2gray(img_array(:, :, :, 1:training_sz));
x_test = rgb2gray(img_array(:, :, :, (training_sz+1):50));