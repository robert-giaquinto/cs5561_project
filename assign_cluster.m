function labels = assign_cluster(cluster_centers, x)
% This is a function to assign a known cluster centroid
% (cluster_centers) to a new set of observations (x)

num_points = size(x, 1);
num_clusters = size(cluster_centers, 1);
labels = zeros([num_points, 1]);

% loop through each cluster, keep note of closest cluster
best_ssd = ones(num_points, 1) * inf;
for k = 1:num_clusters
    ssd = sum_squared_distance(x, cluster_centers(k, :));
    for n = 1:num_points
        if ssd(n) < best_ssd(n)
            labels(n) = k;
            best_ssd(n) = ssd(n);
        end
    end
end

end