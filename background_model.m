function back_vec = background_model(x_train, method, num_components)
% use data from x_train to create a model/image of the background
%
% x_train: a matrix with 1 row per image frame, each column represents a pixel
%     PCA is trained on this data
% return: a vector that represents the background image
    
% set some default arguments
switch nargin
    case 1
        method = 'median';
        num_components = 5;
    case 3
        num_components = 5;
end


% 1. find coefficients for principal component
% standardize the training data set
x_mean = mean(x_train, 1);
x_standard = bsxfun(@minus, x_train, x_mean);
% apply SVD decomposition on standardized data
[U, S, pc] = svds(x_standard, num_components);
clear U; clear S;

% use principal components to reduce dimensionality of data
x_pca = x_standard * pc;

% aggregate the frames in the low dimensional space
if strcmp(method, 'median')
    back_pca = median(x_pca, 1);
else
    % default to taking the mean of each frame
    back_pca = mean(x_pca, 1);
end

% reverse transform the aggregated frames into the higher dimension
back_vec = back_pca * pinv(pc);
% add back in the the standardization term
back_vec = bsxfun(@plus, back_vec, x_mean);
end