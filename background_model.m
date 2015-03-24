function back_vec = background_model(x_train, method)

% find coefficients for principal component
princ_comp = pca(x_train, 'NumComponents',5);
% map input data to subspace
train_pca = x_train * princ_comp;

if method == 'median'
    back_pca = median(train_pca);
else
    % assume method == 'mean'
    back_pca = mean(train_pca);
end

% transform to full sized matrix
back_vec = inv(princ_comp) * back_pca;
return back_vec


end