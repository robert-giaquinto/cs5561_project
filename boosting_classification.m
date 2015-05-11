clear;
close;

%%
%%  PART ONE: TRAINING CLASSIFIER ON SYNTHETIC DATA --------------------
%%

% Import and clean data
% which datasets to use?
user_name = strtrim(char(java.lang.System.getProperty('user.name')));
if strcmp(user_name, 'robert')
    cd('/Users/robert/documents/UMN/5561_CV/project/code');
    data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
else
    cd('/Users/tomringstrom/Documents/MATLAB/TrackingProject/cs5561_project/');
    data_dir = ('/Users/tomringstrom/Documents/MATLAB/TrackingProject/cs5561_project/data/');
end
% FOR PROFESSOR OR TA:
data_dir = '';

file_names = dir(strcat(data_dir, 'beach*.csv'));
NUM_ROWS = 480;
NUM_COLS = 480;
% read in each of the files, stack them
all_data = read_csvs(data_dir, file_names);

% transform data to one row per video + frame,
% and extract features
data = transform_data(all_data, NUM_ROWS, NUM_COLS);

% split into test and training data
% variable names to train data on:
pred_vars = {'velocity', 'direction', ...
    'velocity_two', 'direction_two', ...
    'velocity_dif', 'direction_dif', 'distance'};
num_features = length(pred_vars);
% what behavior do we want to be able to recognize?
tar_var = {'target'};
[x_train, y_train, x_test, y_test] = split_data(data, pred_vars, tar_var, .3);

% fit model on training data
% fit one vs. all models (not as good):
% random_model = fitensemble(x_train, y_train(:,1), 'AdaBoostM1', 250, 'Tree');
% pursue_model = fitensemble(x_train, y_train(:,2), 'AdaBoostM1', 250, 'Tree');
% cutoff_model = fitensemble(x_train, y_train(:,3), 'AdaBoostM1', 250, 'Tree');
% fit each class at once (better):
tree_type = templateTree('MaxNumSplits',3); % change tree depth
model = fitensemble(x_train, y_train, 'AdaBoostM2', 250, tree_type);

% plot the model error vs. complexity
figure;
plot(loss(model, x_train, y_train, 'mode', 'cumulative'), 'b');
hold on;
plot(loss(model, x_test, y_test, 'mode', 'cumulative'), 'r');
hold off;
legend('Train','Test','Location','NE');
xlabel('Number of Trees');
ylabel('Classification Error');
title('AdaBoost Classification Error');
% What is overall accuracy
test_accuracy = loss(model, x_test, y_test, 'mode', 'ensemble')
train_accuracy = loss(model, x_train, y_train, 'mode', 'ensemble')

% plot accuracy from each of the 1 vs. all models
% figure;
% plot(loss(random_model, x_train, y_train(:, 1), 'mode', 'cumulative'), 'b');
% hold on;
% plot(loss(random_model, x_test, y_test(:, 1), 'mode', 'cumulative'), 'r');
% hold off;
% legend('Train','Test','Location','NE');
% xlabel('Number of Trees');
% ylabel('Classification Error');
% title('AdaBoost Classification Error: Random Motion Model');
% 
% figure;
% plot(loss(pursue_model, x_train, y_train(:, 2), 'mode', 'cumulative'), 'b');
% hold on;
% plot(loss(pursue_model, x_test, y_test(:, 2), 'mode', 'cumulative'), 'r');
% hold off;
% legend('Train','Test','Location','NE');
% xlabel('Number of Trees');
% ylabel('Classification Error');
% title('AdaBoost Classification Error: Pursuant Model');
% 
% figure;
% plot(loss(cutoff_model, x_train, y_train(:, 3), 'mode', 'cumulative'), 'b');
% hold on;
% plot(loss(cutoff_model, x_test, y_test(:, 3), 'mode', 'cumulative'), 'r');
% hold off;
% legend('Train','Test','Location','NE');
% xlabel('Number of Trees');
% ylabel('Classification Error');
% title('AdaBoost Classification Error: Being Cutoff Model');





%%
%% PART TWO: DEMO OF CLASSIFICATION ON SYNTHETIC DATA -------------------
%%

% import data to test on
demo_file = 'beach3_follow.csv';
demo_data = data(strcmp(data.file, demo_file), :);

% predict probability of each behavior
demo_data.prediction = predict(model, demo_data{:, pred_vars});


% also load a (different) gif to train background subtraction on
train_file = dir(strcat(data_dir, 'beach2_follow.gif'));
train_file_name = strcat(data_dir, train_file.name);
train_array = create_img_array(train_file_name);
train_mat = array_to_matrix(train_array);

% use train_mat to build background model
back_vec = background_model(train_mat, 'mean', 6);
demo_file_name = strcat(data_dir, demo_file(1:(end-3)), 'gif');
demo_array = create_img_array(demo_file_name);
demo_mat = array_to_matrix(demo_array);

% subtract background model from each image in test_mat
est_fore_mask = foreground_mask(back_vec, demo_mat, .175);

% reduce noise of foreground:
% label connected regions, keep only regions 25% as large as largest region
est_fore_array = matrix_to_array(est_fore_mask, NUM_ROWS, NUM_COLS);
foreground = label_regions(est_fore_array, 4, .25);

num_frames = 50;
figure;
for i = 1:num_frames
    pause(0.05);
    fore_frame = foreground(:,:,:, i);
    x_test = demo_data(demo_data.step == i, :);
    if strcmp(x_test.prediction, 'pursue')
        % being followed, turn red!
        fore_frame(:,:,1) = fore_frame(:,:,1) * 255;
    elseif strcmp(x_test.prediction, 'cutoff')
        %being cutoff, turn blue!
        fore_frame(:,:,3) = fore_frame(:,:,3) * 255;
    else
        % no threat, turn green!
        fore_frame(:,:,2) = fore_frame(:,:,2) * 255;
    end
    imshow(uint8(fore_frame));
    drawnow;
end





%%
%% PART THREE: DEMO CLASSIFICATION ON REAL DATA -------------------------
%%
% import real video
nthFrame = 5; % Take every nth frame from the video.
frameStart = 1500;
frameStop = 3400;
vid = VideoReader(strcat(data_dir, 'GOPR0303.mp4'));
vidWidth = vid.Width;
vidHeight = vid.Height;
nFrames = ((frameStop-frameStart)/nthFrame);

% Make frames smaller, faster to compute.
frameSizeFactor = 4; 
img_array = zeros(vidHeight/frameSizeFactor,vidWidth/frameSizeFactor,3, nFrames);
vidIndexList = frameStart:nthFrame:frameStop; % holds all of the indicies of the frames to be used.
for k = 1:length(vidIndexList)
    IMG = read(vid, vidIndexList(k));
    img_array(:,:,:,k) = im2double(imresize(IMG,[vidHeight/frameSizeFactor vidWidth/frameSizeFactor]));
end
NUM_ROWS = vidHeight/frameSizeFactor;
NUM_COLS = vidWidth/frameSizeFactor;

% APPLY IMAGE DENOISING TECHNIQUES
% Convert to 4D array to matrix for analysis
img_mat = array_to_matrix(img_array);
% CREATE BACKGROUND MODEL
% split image array into a training and test set
training_sz = nFrames*.5;
x_train = img_mat(1:training_sz, :);
num_components = 5;
% use Oliver's eigenbackground approach, taking mean in low D space
back_vec = background_model(x_train, 'mean', num_components);

% CREATE FOREGROUND MASK
threshold = .075;
fore_mask = foreground_mask(back_vec, img_mat, threshold); % threshold should be 0.05 for video
fore_array = matrix_to_array(fore_mask, NUM_ROWS, NUM_COLS);

% reduce noise of foreground:
% label connected regions, keep only regions 25% as large as largest region
fore_mask_img = label_regions(fore_array, 4, .33);

% track locations of objects
pFrame = fore_mask_img(:,:,:,1);
feature1 = load('feat.mat');
feature1 = feature1.feat;
feature1 = rgb2gray(feature1);
feature2 = feature1;
feature1 = load('featureP.mat');
feature1 = feature1.featureP;
featCoorMap = zeros(2,2,size(fore_mask_img,4)); % feature # X leftRight
numOfObjects = 2;
for f = 2:size(fore_mask_img,4)
    cFrame = fore_mask_img(:,:,:,f);
    cFrame = rgb2gray(cFrame);
    a = 1;
    xcorrMat = normxcorr2(feature1, cFrame);
    for i = 1:numOfObjects
        
        [r,c] = find(xcorrMat == max(max(xcorrMat)));
        r = r(1); c = c(1);
        
        ydist = (size(feature1,1)/2)+5;
        xdist = (size(feature1,2)/2)+2;
        ytodel = r-floor(ydist):ceil(r+ydist);
        xtodel = c-floor(xdist):ceil(c+xdist);
        xcorrMat(ytodel,xtodel) = 0;
        flag = false;
        
        r = min(max(floor(r - (size(feature1,1)/2)),1),size(cFrame,1));
        c = min(max(floor(c - (size(feature1,2)/2)),1),size(cFrame,2));
        
        featCoorMap(i,1:2,f) = [r,c]; %1 = y, 2 = x
    end
    newFeature = cFrame(max(r - size(feature1,1),1):min(r-1,size(cFrame,1)), ...
        max(c - size(feature1,2),1):min(c-1,size(cFrame,1)));
    pFrame = cFrame;
end

% transform kalman filter coordinates to 2D table
real_data = zeros(nFrames-1, num_features);
locations = zeros(nFrames-1, 4);
% normalization constant relative to size of frame:
normalization = sqrt(NUM_ROWS^2 + NUM_COLS^2);
% ignore first frame, kalman filter has no estimates there
for i = 2:nFrames
    y1 = featCoorMap(1,1,i);
    x1 = featCoorMap(1,2,i);
    y2 = featCoorMap(2,1,i);
    x2 = featCoorMap(2,2,i);
    locations(i-1,1) = y1;
    locations(i-1,2) = x1;
    locations(i-1,3) = y2;
    locations(i-1,4) = x2;
    % distance between each other
    real_data(i-1,7) = sqrt((x2-x1)^2 + (y2-y1)^2) / normalization;
    
    if i > 2
        % find velocity features
        y1_dif = y1 - featCoorMap(1,1,i-1);
        x1_dif = x1 - featCoorMap(1,2,i-1);
        y2_dif = y2 - featCoorMap(2,1,i-1);
        x2_dif = x2 - featCoorMap(2,2,i);
        real_data(i-1,1) = sqrt(x1_dif^2 + y1_dif^2) / normalization;
        real_data(i-1,3) = sqrt(x1_dif^2 + y1_dif^2) / normalization;
        real_data(i-1,5) = real_data(i-1,1) - real_data(i-1,5);
    
        % find directional changes
        unit_scale1 = sqrt(x1_dif^2 + y1_dif^2);
        direction1 = atan((y1_dif/unit_scale1) / (x1_dif/unit_scale1));
        unit_scale2 = sqrt(x2_dif^2 + y2_dif^2);
        direction2 = atan((y2_dif/unit_scale2) / (x2_dif/unit_scale2));
        if direction1 < -1 * pi
            direction1 = direction1 + (2 * pi);
        elseif direction1 > pi
            direction1 = direction1 - (2 * pi);
        elseif isnan(direction1)
            direction1 = sign(y1_dif) * pi/2;
        end
        real_data(i-1,2) = direction1;
        if direction2 < -1  * pi
            direction2 = direction2 + (2 * pi);
        elseif direction2 > pi
            direction2 = direction2 - (2 * pi);
        elseif isnan(direction2)
            direction2 = sign(y2_dif) * pi/2;
        end
        real_data(i-1,4) = direction2;
        real_data(i-1,6) = direction1 - direction2;
    end
end
% normalize the features
for i = 1:num_features
    real_data(:,i) = real_data(:,i) * (mean(x_train(:,i)) / mean(real_data(:,i)));
end

% predict what is happening using trained model
prediction = predict(model, real_data);

figure;
block_sz = 4;
for i = 1:(nFrames-1)    
    pause(0.05);
    fore_frame = fore_mask_img(:,:,:, i) * 255;
    x1 = locations(i,1);
    y1 = locations(i,2);
    x2 = locations(i,3);
    y2 = locations(i,4);
    x1mb = max(x1 - block_sz, 1);
    x1pb = min(x1 + block_sz, NUM_ROWS);
    x2mb = max(x2 - block_sz, 1);
    x2pb = min(x2 + block_sz, NUM_ROWS);
    y1mb = max(y1 - block_sz, 1);
    y1pb = min(y1 + block_sz, NUM_COLS);
    y2mb = max(y2 - block_sz, 1);
    y2pb = min(y2 + block_sz, NUM_COLS);
    
    if strcmp(prediction(i), 'pursue')
        % being followed, turn red!
        fore_frame(x1mb:x1pb, y1mb:y1pb, 1) = 255;
        fore_frame(x2mb:x2pb, y2mb:y2pb, 1) = 255;
        fore_frame(x1mb:x1pb, y1mb:y1pb, 2) = 0;
        fore_frame(x2mb:x2pb, y2mb:y2pb, 2) = 0;
        fore_frame(x1mb:x1pb, y1mb:y1pb, 3) = 0;
        fore_frame(x2mb:x2pb, y2mb:y2pb, 3) = 0;
    elseif strcmp(prediction(i), 'cutoff')
        %being cutoff, turn blue!
        fore_frame(x1mb:x1pb, y1mb:y1pb, 3) = 255;
        fore_frame(x2mb:x2pb, y2mb:y2pb, 3) = 255;
        fore_frame(x1mb:x1pb, y1mb:y1pb, 2) = 0;
        fore_frame(x2mb:x2pb, y2mb:y2pb, 2) = 0;
        fore_frame(x1mb:x1pb, y1mb:y1pb, 1) = 0;
        fore_frame(x2mb:x2pb, y2mb:y2pb, 1) = 0;
    else
        % no threat, turn green!
        fore_frame(x1mb:x1pb, y1mb:y1pb, 1) = 0;
        fore_frame(x2mb:x2pb, y2mb:y2pb, 1) = 0;
        fore_frame(x1mb:x1pb, y1mb:y1pb, 2) = 255;
        fore_frame(x2mb:x2pb, y2mb:y2pb, 2) = 255;
        fore_frame(x1mb:x1pb, y1mb:y1pb, 3) = 0;
        fore_frame(x2mb:x2pb, y2mb:y2pb, 3) = 0;
    end
    imshow(uint8(fore_frame));
    text(NUM_COLS/3, 4*NUM_ROWS/5, strcat('\bf\color{white}\fontsize{24}', prediction(i)));
    drawnow;s
end
matlabmail('giaquinto.ra@gmail.com','hi','successfully ran boosting classification, go check results','trdummy4@gmail.com','matlabpw?);


