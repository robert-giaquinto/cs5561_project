clear;
close;



% Implement a classification of object behavior
% In final system, will rely on Tom's work for locations
% in the meantime use the data that creates the GIFs

% 1. Import all of the csv files
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
num_steps = 50;

% import data
all_data = read_csvs(data_dir, file_names);
% transform data, extract features
data = transform_data(all_data, NUM_ROWS, NUM_COLS);

% split into test and training data
pred_vars = {'x_pos', 'y_pos', 'velocity', 'direction', ...
    'x_pos_two', 'y_pos_two', 'velocity_two', 'direction_two', ...
    'velocity_dif', 'direction_dif', 'distance'};
num_features = length(pred_vars);
tar_var = {'random', 'pursue', 'cutoff'};
[x_train, y_train, x_test, y_test] = split_data(data, pred_vars, tar_var, .25);


% convert the continuous observations into discrete observertions
% first normalize the data so that distance comparisons are fair
x_mean = mean(x_train, 1);
x_stdev = std(x_train, 1);
x_norm = bsxfun(@rdivide, bsxfun(@minus, x_train, x_mean), x_stdev);
% call the K-means clustering function
num_clusters = 30;
[cluster_centers, train_clusters] = Kmeans_cluster(x_norm, num_clusters);

% un-normalize cluster centers to see how they look
% bsxfun(@plus, bsxfun(@times, cluster_centers, x_stdev), x_mean)


% transform data into a sliding window format to capture sequences of
% observations
window_sz = 40;
[obs_train, state_train] = sliding_window(train_clusters, y_train, window_sz, num_steps);

% estimate the HMM paragmeters
num_states = 2;
n = size(obs_train, 1);
A = zeros(num_states, num_states);
B = zeros(num_states, num_clusters);
for i = 1:n
    [A_i, B_i] = hmm_fit(obs_train(i,:), num_states, num_clusters);
    A = A + A_i;
    B = B + B_i;
end
A = A / n
B = B / n

% evaluate training accuracy
predict_correct = zeros(n, 1);
predict_positive = zeros(n, 1);
for i = 1:n
    [estimate, ~] = hmm_forward(obs_train(i,:), A, B);
    prob = estimate(:, window_sz);
    pred = (find(prob == max(prob)) - 1);
    if length(pred) > 1
        predict_positive(i) = 1;
    else
        predict_positive(i) = pred;
    end
    predict_correct(i) = (predict_positive(i) == state_train(i));
end
mean(predict_correct)
mean(predict_positive)


%% Apply model to test data
% first, assign a cluster label to each row in test data
% use same mean and stdev found in training set for normalization
x_norm = bsxfun(@rdivide, bsxfun(@minus, x_test, x_mean), x_stdev);
test_clusters = assign_cluster(cluster_centers, x_norm);

% put test data into sliding window
[obs_test, state_test] = sliding_window(test_clusters, y_test, window_sz, num_steps);

% Use hmm parameters estimate the class on x_test
% TODO
prob = hmm_forward(obs_test, num_states, A, B);




