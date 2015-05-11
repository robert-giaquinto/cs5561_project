clear;
close;

%%
%% 1. Import all of the csv files --------------------------------------
%%

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




%%
%% 2. PREPARE DATA FOR MODELING -------------------------------
%%

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
num_clusters = 10;
[cluster_centers, train_clusters] = Kmeans_cluster(x_norm, num_clusters);

% un-normalize cluster centers to see how they look
% bsxfun(@plus, bsxfun(@times, cluster_centers, x_stdev), x_mean)





%%
%% 3. SLIDING WINDOW APPROACH TO MODELING ----------------------------
%%

% transform data into a sliding window format to capture sequences of
% observations
window_sz = 30;
[obs_train, state_train] = sliding_window(train_clusters, y_train, window_sz, num_steps);
y1 = obs_train(state_train(:,1) == 1,:);
y2 = obs_train(state_train(:,2) == 1,:);
y3 = obs_train(state_train(:,3) == 1,:);
obs = {y1, y2, y3};
x1 = state_train(state_train(:,1) == 1,:);
x2 = state_train(state_train(:,2) == 1,:);
x3 = state_train(state_train(:,3) == 1,:);
states = {x1, x2, x3};


% estimate the HMM paragmeters
num_states = 3;
num_classes = 3;
A = zeros(num_states, num_states, num_classes);
B = zeros(num_states, num_clusters, num_classes);
for c = 1:num_classes
    y = obs{c};
    n = size(y, 1);
    for i = 1:n
        [A_i, B_i] = hmm_fit(y(i,:), num_states, num_clusters);
        A(:,:,c) = A(:,:,c) + A_i;
        B(:,:,c) = B(:,:,c) + B_i;
    end
    A(:,:,c) = A(:,:,c) / n;
    B(:,:,c) = B(:,:,c) / n;
end
A
B

% evaluate training accuracy
predict_correct = zeros(n, 1);
preds = zeros(n, num_classes);
n = size(obs_train, 1);
for i = 1:n
    [estimate1, ~] = hmm_forward(obs_train(i,:), A(:,:,1), B(:,:,1));
    [estimate2, ~] = hmm_forward(obs_train(i,:), A(:,:,2), B(:,:,2));
    [estimate3, ~] = hmm_forward(obs_train(i,:), A(:,:,3), B(:,:,3));
    prob = estimate1(:, window_sz) + estimate2(:, window_sz) + estimate3(:, window_sz);
    preds(i,:) = prob == max(prob);
    predict_correct(i) = all(preds(i,:) == state_train(i,:));
end
mean(predict_correct)
mean(preds)




%%
%% 4. TRADITIONAL APPROACH (LARGE SEQUENCE) ------------------------
%%
num_states = 3;
num_classes = 3;
A = zeros(num_states, num_states, num_classes);
B = zeros(num_states, num_clusters, num_classes);
for c = 1:num_classes
    [A_i, B_i] = hmm_fit(train_clusters', num_states, num_clusters);
    A(:,:,c) = A_i;
    B(:,:,c) = B_i;
end
A
B

% evaluate training accuracy
% evaluate training accuracy
predict_correct = zeros(n, 1);
preds = zeros(n, num_classes);
n = size(obs_train, 1);
for i = 1:n
    [estimate1, ~] = hmm_forward(obs_train(i,:), A(:,:,1), B(:,:,1));
    [estimate2, ~] = hmm_forward(obs_train(i,:), A(:,:,2), B(:,:,2));
    [estimate3, ~] = hmm_forward(obs_train(i,:), A(:,:,3), B(:,:,3));
    prob = estimate1(:, window_sz) + estimate2(:, window_sz) + estimate3(:, window_sz);
    preds(i,:) = (prob == max(prob))';
    predict_correct(i) = all(preds(i,:) == state_train(i,:));
end
mean(predict_correct)
mean(preds)








%%
%% Apply model to test data -------------------------------------
%%

% first, assign a cluster label to each row in test data
% use same mean and stdev found in training set for normalization
x_norm = bsxfun(@rdivide, bsxfun(@minus, x_test, x_mean), x_stdev);
test_clusters = assign_cluster(cluster_centers, x_norm);

% put test data into sliding window
[obs_test, state_test] = sliding_window(test_clusters, y_test, window_sz, num_steps);

% Use hmm parameters estimate the class on x_test
prob = hmm_forward(obs_test, num_states, A, B);




