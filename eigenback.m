function fore_mat = eigenback(x_train, x_test, thres_val, method, num_components)
% This is the full eigenbackground algorithm
% this implements the functions that are defined in:
% background_model. and foreground_mask.m
%
% x_train:
% x_test:
% thres_val:
% method:
% num_components:
% return:

% set some default arguments
switch nargin
    case 2
        thres_val = .15;
        method = 'median';
        num_components = 5;
    case 3
        method = 'median';
        num_components = 5;
    case 4
        num_components = 5;
end

% create the background image model
back_vec = background_model(x_train, method, num_components);

% use background image to create a foreground mask
fore_mask = foreground_mask(back_vec, x_test, thres_val);

% apply foreground mask to each image in the entire video sequence
fore_mat = fore_mask .* x_test;
end