% EVALUATE METHODS
clear;
close;

%% GOBAL PARAMETERS -----------------------------------
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


file_names = dir(strcat(data_dir, 'beach*_follow.gif'));



%% Background subtraction ----------------------------
% load a single gif to train on
train_file = file_names(1);
train_file_name = strcat(data_dir, train_file.name);
train_array = create_img_array(train_file_name);
train_mat = array_to_matrix(train_array);
% use train_mat to build background model
back_vec = background_model(train_mat, 'mean', 5);

% loop through remaining gifs, find pct correct
num_gifs = size(file_names,1);
mean_pct_correct = zeros([num_gifs-1, 3]);
for g = 2:num_gifs
    % import a gif to test background model on
    test_file = file_names(g);
    test_file_name = strcat(data_dir, test_file.name);
    test_array = create_img_array(test_file_name);
    test_mat = array_to_matrix(test_array);

    % load true foregorund for this test file
    mask_file = strcat(data_dir, test_file.name(1:(end-4)), '_mask.gif');
    mask_gif = importdata(mask_file);
    true_fore_array = mask_gif.cdata > 0;
    % convert to a logical matrix, ignore color channels
    true_fore_array = max(true_fore_array, [], 3) > 0;
    num_frames = size(true_fore_array, 4);
    true_foreground = zeros(num_frames, (NUM_ROWS * NUM_COLS));
    for f=1:num_frames
        true_foreground(f,:) = reshape(true_fore_array(:,:,1,f), [1 NUM_ROWS * NUM_COLS]);
    end

    
    % subtract background model from each image in test_mat
    est_fore_mask = foreground_mask(back_vec, test_mat, .15);
    
    % reduce noise of foreground:
    % label connected regions, keep only regions 25% as large as largest region
    est_fore_array = matrix_to_array(est_fore_mask, NUM_ROWS, NUM_COLS);
    est_fore_array_labeled = label_regions(est_fore_array, 4, .5);
    % convert to logical matrix
    est_fore_array = max(est_fore_array_labeled, [], 3) > 0;
    estimated_foreground = zeros(num_frames, (NUM_ROWS * NUM_COLS));
    for f=1:num_frames
        estimated_foreground(f,:) = reshape(est_fore_array(:,:,1,f), [1 NUM_ROWS * NUM_COLS]);
    end

    % for each image in gif: compare true foreground to test foreground
    pct_correct = zeros([num_frames, 3]);
    total_pixels = NUM_ROWS * NUM_COLS;
    for i = 1:num_frames
        foreground_ct = sum(true_foreground(i,:));
        foreground_match = (estimated_foreground(i,:) == true_foreground(i,:)) & ...
            (true_foreground(i,:) == 1) & ...
            (estimated_foreground(i,:) == 1);
        fore_match_ct = sum(foreground_match);
        
        background_ct = total_pixels - foreground_ct;
        background_match = (estimated_foreground(i,:) == true_foreground(i,:)) & ...
            (true_foreground(i,:) == 0) & ...
            (estimated_foreground(i,:) == 0);
        back_match_ct = sum(background_match);
        
        total_matches = sum(estimated_foreground(i,:) == true_foreground(i,:));
        pct_correct(i, :) = [(fore_match_ct / foreground_ct) ...
            (back_match_ct / background_ct) ...
            (total_matches / total_pixels)];
    end
    avg = mean(pct_correct);
    mean_pct_correct(g-1, :) = avg;
    disp(sprintf('Foreground accuracy=%1.3f', avg(1)));
    disp(sprintf('Background accuracy=%1.3f', avg(2)));
    disp(sprintf('Pixel accuracy=%1.3f\n', avg(3)));
end

csvwrite('Beach_Background_Accuracy.csv', mean_pct_correct);
% csvwrite('Forest_Background_Accuracy.csv', mean_pct_correct);
% csvwrite('Real_Background_Accuracy.csv', mean_pct_correct);





