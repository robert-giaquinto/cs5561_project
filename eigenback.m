function fore_mat = eigenback(x_train, x_test, thres_val, method, num_components, return_mask, NUM_ROWS, NUM_COLS)
% This is the full eigenbackground algorithm
% this implements the functions that are defined in:
% background_model. and foreground_mask.m
%
% x_train:
% x_test:
% thres_val:
% method:
% num_components:
% return_mask: should output be binary image mask (1), or foreground in color (0)?

% set some default arguments
switch nargin
    case 2
        thres_val = .15;
        method = 'mean';
        num_components = 5;
        return_mask = 0;
    case 3
        method = 'mean';
        num_components = 5;
        return_mask = 0;
    case 4
        num_components = 5;
        return_mask = 0;
    case 5
        return_mask = 0;
end

% create the background image model
back_vec = background_model(x_train, method, num_components);

% use background image to create a foreground mask
fore_mask = foreground_mask(back_vec, x_test, thres_val);

% reduce noise of foreground:
% label connected regions, keep only regions 25% as large as largest region
fore_array = matrix_to_array(fore_mask, NUM_ROWS, NUM_COLS);
fore_array_labeled = label_regions(fore_array, 4, .25);


if return_mask
    % return the binary image matrix
    fore_mat = array_to_matrix(fore_array_labeled);
else
    % apply foreground mask to each image in the entire video sequence
    fore_mask2 = array_to_matrix(fore_array_labeled);
    fore_mat = fore_mask2 .* x_test;
end
end