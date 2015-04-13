function labeled_array = label_regions(fore_array, num_neighbors, threshold)

num_images = size(fore_array, 4);
% first, collapse each image to a 2D array (i.e. remove color channels
bw_fore = sum(fore_array, 3);
bw_fore(bw_fore ~= 0) = 1;

% loop through each image and label the connected regions
labeled_array = zeros(size(fore_array));
for i = 1:num_images
    labeled = bwlabeln(bw_fore(:,:,1,i), num_neighbors);
    label_size = tabulate(labeled(:));
    % drop the zero region
    label_size = label_size(2:end,:);
    % keep only regions that are larger than threshold * max region size
    largest_region = max(label_size(:,2));
    keep_regions = find(label_size(:,2) >= (largest_region * threshold));
    mask = ismember(labeled, keep_regions);
    % apply the mask across each color channel
    for c = 1:3
        labeled_array(:,:,c,i) = mask .* fore_array(:,:,c,i);
    end
end

end