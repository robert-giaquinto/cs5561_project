function [x_seq, y_seq] = sliding_window(cluster_labels, y, window_sz)

% initialize output data
num_obs = size(cluster_labels, 1) - window_sz + 1;
x_seq  = zeros(num_obs, window_sz);
for i = 1:num_obs
    i_end = i+window_sz-1;
    x_seq(i, :) = cluster_labels(i:i_end)';
end

% target variable corresponding to each observation
% is just a row in y lagged by window_sz
y_seq = y(window_sz:end);
end