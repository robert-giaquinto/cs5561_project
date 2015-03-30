% GOBAL PARAMETERS;
NUM_ROWS = 480;
NUM_COLS = 480;

% where are files located?
user_name = strtrim(char(java.lang.System.getProperty('user.name')));
if strcmp(user_name, 'robert')
    cd('/Users/robert/documents/UMN/5561_CV/project/code');
    data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
else
    cd('/Users/tomringstrom/Documents/MATLAB/TrackingProject/cs5561_project/');
    data_dir = ('/Users/tomringstrom/Documents/MATLAB/TrackingProject/cs5561_project/data/');
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
img_array2 = matrix_to_array(img_mat, NUM_ROWS, NUM_COLS);
img = img_array2(:,:,:,1)*255;
% does it look the same as original? yes.
figure('Name','Original Preserved','NumberTitle','off');
imshow(uint8(img)); title('Transformation Back to Original');


% CREATE BACKGROUND MODEL
% need to put images into a matrix form!!!!
% split image array into a training and test set
training_sz = 40;
x_train = img_mat(1:training_sz, :);
num_components = 5;
back_vec = background_model(x_train, 'median', num_components);
back_img = matrix_to_array(back_vec, NUM_ROWS, NUM_COLS);
imshow(uint8(back_img*255)); title('Background Image');


% CREATE FOREGROUND MASK
threshold = .45;
fore_mask = foreground_mask(back_vec, img_mat, threshold);
fore_mask_img = matrix_to_array(fore_mask, NUM_ROWS, NUM_COLS);
figure('Name','Foreground Mask','NumberTitle','off');
for i = 1:9
    frame = fore_mask_img(:,:,:, i);
    subplot(3, 3, i);
    plot_title = sprintf('Frame %d', i);
    imshow(uint8(frame*255)); title(plot_title);
end

% Put kalman filter here.  % Work with fore_mask_img
imshow(fore_mask_img(:,:,:,1)*255);
pFrame = fore_mask_img(:,:,:,1);

feature1 = load('feat.mat');
feature1 = feature1.feat;
feature1 = rgb2gray(feature1);
feature2 = feature1;

featCoorMap = zeros(2,2,size(fore_mask_img,4)); % feature # X leftRight

for f = 2:size(fore_mask_img,4)
    cFrame = fore_mask_img(:,:,:,f);
    cFrame = rgb2gray(cFrame);
    
    % error occures at frame 23
    xcorrMat = normxcorr2(feature1, cFrame);
    [r,c] = find(xcorrMat == max(max(xcorrMat))); % why does this sometimes return vectors?
    r = r(1); c = c(1);
    flag = false;
    
    
    newFeature = cFrame(max(r - size(feature1,1),1):min(r-1,size(cFrame,1)), ...
        max(c - size(feature1,2),1):min(c-1,size(cFrame,1)));
    
%     if isequal(size(newFeature),size(feature1))
%         feature1 = newFeature; 
%     end
    newFeature = imresize(newFeature,size(feature1));
    r = min(max(floor(r - (size(feature1,1)/2)),1),size(cFrame,1));
    c = min(max(floor(c - (size(feature1,2)/2)),1),size(cFrame,2));
    
    
    featCoorMap(1,1:2,f) = [r,c];
    
    pFrame = cFrame;
end


% EIGENBACKGROUND ALGORITHM: show only foreground
% applies some of the functions used above all in one step
fore_mat = eigenback(x_train, img_mat, threshold, 'median', num_components);
fore_img = matrix_to_array(fore_mat, NUM_ROWS, NUM_COLS);
figure('Name','Foreground Images','NumberTitle','off');
f = load('featText.mat');
f = f.fe;
f = im2bw(f,0.9);
for i = 2:18
    if mod(i, 2) == 0
        frame = fore_img(:,:,:, i) * 255;
        subplot(3, 3, i/2);
        plot_title = sprintf('Frame %d', i);
        imshow(uint8(frame)); title(plot_title);
    end
end


% TOM'S CODE HERE-ish = LOCATION OF OBJECTS 
