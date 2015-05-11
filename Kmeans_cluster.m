function [clusters, labels] = Kmeans_cluster(data, num_clusters)
max_iters = 150;
num_points = size(data,1);
num_features = size(data, 2);

% initialize output arrays
clusters = zeros(num_clusters, num_features);
labels = zeros(num_points, 1);

% intialize clusters/means with random values
% for each cluster
for c = 1:num_clusters
    % loop through each feature and select a random point
    random_point = zeros(1, num_features);
    for f = 1:num_features
        random_point(f) = randsample(data(:,f), 1);
    end
    clusters(c, :) = random_point;
end

% threshold to stop early if algorithm converges
thresh = .00001;
delta = inf;
iter = 0;
tic
while iter < max_iters && delta > thresh
    iter = iter + 1;
    % find distance between data and current means for each K
    best_ssd = ones(num_points, 1) * inf;
    for k = 1:num_clusters
    	ssd = sum_squared_distance(data, clusters(k, :));
        for n = 1:num_points
            if ssd(n) < best_ssd(n)
                labels(n) = k;
                best_ssd(n) = ssd(n);
            end
        end
    end
    % update the cluster means
    old_clusters = clusters;
    for k = 1:num_clusters
        data_k = data(labels == k,:);
        clusters(k, :) = mean(data_k);      
    end
    % how far did the means move
    delta = sum(sum(abs(clusters - old_clusters)));
end
toc
disp(sprintf('Converged after %d iterations', iter));

end