function ssd = sum_squared_distance(data, cluster)

N = size(data,1);
rep_clusters = repmat(cluster,N,1);

% how far is each point from the cluster center
% use sum of squared distance
ssd = sum((data - rep_clusters) .* (data - rep_clusters), 2);