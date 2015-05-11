function ssd = sum_squared_distance(data, cluster)
% assumes data will be normalized in order to give equal weight
% to each of the predictors in the dataset.

N = size(data,1);
rep_clusters = repmat(cluster,N,1);

% how far is each point from the cluster center
% use sum of squared distance
ssd = sum((data - rep_clusters) .* (data - rep_clusters), 2);