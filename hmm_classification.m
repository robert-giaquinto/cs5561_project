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

% import data
all_data = read_csvs(data_dir, file_names);
% transform data, extract features
data = transform_data(all_data, NUM_ROWS, NUM_COLS);

% split into test and training data
pred_vars = {'velocity','direction','velocity_two','direction_two','distance'};
tar_var = {'cutoff'};
x = data{:, pred_vars};
y = data.cutoff;
[x_train, y_train, x_test, y_test] = split_data(data, pred_vars, tar_var, .3);


% convert the continuous observations into discrete observertions
% first normalize the data so that distance comparisons are fair
x_mean = mean(x_train, 1);
x_stdev = std(x_train, 1);
x_norm = bsxfun(@rdivide, bsxfun(@minus, x_train, x_mean), x_stdev);
% call the K-means clustering function
num_clusters = 10;
[cluster_centers, train_clusters] = Kmeans_cluster(x_norm, num_clusters);

% un-normalize cluster centers to see how they look
% cluster_centers = bsxfun(@plus, bsxfun(@times, cluster_centers, x_stdev), x_mean);


% transform data into a sliding window format to capture sequences of
% observations
window_sz = 10;
[obs_train, state_train] = sliding_window(train_clusters, y_train, window_sz);


% estimate the HMM paragmeters
num_states = 2;
% TODO
[A, B] = hmm_fit(obs_train, num_states);


%% Apply model to test data
% first, assign a cluster label to each row in test data
% use same mean and stdev found in training set for normalization
x_norm = bsxfun(@rdivide, bsxfun(@minus, x_test, x_mean), x_stdev);
% TODO
test_clusters = assign_cluster(cluster_centers, x_norm);

% put test data into sliding window
[obs_test, state_test] = sliding_window(test_clusters, y_test, window_sz);

% Use hmm parameters estimate the class on x_test
% TODO
prob = hmm_forward(obs_test, num_states, A, B);




