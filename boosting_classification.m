clear;
close;

% which datasets to use?
user_name = strtrim(char(java.lang.System.getProperty('user.name')));
if strcmp(user_name, 'robert')
    cd('/Users/robert/documents/UMN/5561_CV/project/code');
    data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
else
    cd('/Users/robert/documents/MATLAB/...');
    data_dir = '/Users/Tom/documents/.../data/';
end
file_names = dir(strcat(data_dir, 'beach*.csv'));
NUM_ROWS = 480;
NUM_COLS = 480;

%% Import and clean data
all_data = read_csvs(data_dir, file_names);
% transform data, extract features
data = transform_data(all_data, NUM_ROWS, NUM_COLS);

% split into test and training data
pred_vars={'velocity','direction','velocity_two','direction_two','distance'};
x = data{:, pred_vars};
y = data.cutoff;
[x_train, y_train, x_test, y_test] = split_data(x, y, .3);

% fit model on training data
boost = fitensemble(x_train, y_train, 'AdaBoostM1', 250, 'Tree');

% plot the model error vs. complexity
figure;
plot(loss(boost, x_train, y_train, 'mode', 'cumulative'), 'b');
hold on;
plot(loss(boost, x_test, y_test, 'mode', 'cumulative'), 'r');
hold off;
legend('Train','Test','Location','NE');
xlabel('Number of Trees');
ylabel('Classification Error');
title('AdaBoost Behavior Classification Error');


%% Create demo of classification accurary
% import some data 
demo_file = 'beach3_cutoff.csv';
demo_data = data(strcmp(data.file, demo_file), :);
demo_data.pred = predict(boost, demo_data{:, pred_vars});


% load a single gif to train background subtraction on
train_file = dir(strcat(data_dir, 'beach2_cutoff.gif'));
train_file_name = strcat(data_dir, train_file.name);
train_array = create_img_array(train_file_name);
train_mat = array_to_matrix(train_array);
% use train_mat to build background model
back_vec = background_model(train_mat, 'mean', 6);

demo_file_name = strcat(data_dir, demo_file(1:(end-3)), 'gif');
demo_array = create_img_array(demo_file_name);
demo_mat = array_to_matrix(demo_array);

% subtract background model from each image in test_mat
est_fore_mask = foreground_mask(back_vec, demo_mat, .2);
% reduce noise of foreground:
% label connected regions, keep only regions 25% as large as largest region
est_fore_array = matrix_to_array(est_fore_mask, NUM_ROWS, NUM_COLS);
foreground = label_regions(est_fore_array, 4, .33);

num_frames = 50;
figure;
for i = 1:num_frames
    pause(0.05);
    fore_frame = foreground(:,:,:, i);
    x_test = demo_data(demo_data.step == i, :);
    if x_test.pred
        % being followed, turn red!
        fore_frame(:,:,1) = fore_frame(:,:,1) * 255;
    else
        fore_frame = fore_frame * 255;
    end
    imshow(uint8(fore_frame));
    drawnow;
end


