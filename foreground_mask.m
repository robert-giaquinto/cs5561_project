function fore_mask = foreground_mask(back_vec, x, thres_val)
% Use a vector represent the background (see background_model function)
% to subtract the background from images.
%
% back_vec: a vector representing background model, each entry corresponds
%     to a pixel in the background image
% x_test: a matrix with 1 row per image frame, each column represents a pixel
%     method is applied to this data and background is subtracted
% thres_val: thresholding parameter. 1 => keep all pixels in image that are
%     different than background model. 0.0001 => only keep pixel that's most
%     different from background.
% return: fore_mask a binary matrix, each row corresponds to the image from the same row
%     in x_test. columns are yes or no saying whether the pixel is in foreground or not

% set some default arguments
switch nargin
    case 2
        % Using default of theshold value of .15
        thres_val = .15;
end

% subtract background from the query images
fore_mask = abs(bsxfun(@minus, x, back_vec));

% thresholding: keep only differences that are 'significant' in each color
cols_per_color = size(fore_mask, 2) / 3;

red_mask = fore_mask(:, 1:cols_per_color);
red_thes = thres_val * max(max(red_mask));
blu_mask = fore_mask(:, (cols_per_color+1):(2*cols_per_color));
blue_thes = thres_val * max(max(blu_mask));
gre_mask = fore_mask(:, (2*cols_per_color+1):(3*cols_per_color));
gre_thes = thres_val * max(max(gre_mask));

red_mask2 = red_mask;
red_mask2(red_mask < red_thes & blu_mask < blue_thes & gre_mask < gre_thes) = 0;
blu_mask2 = blu_mask;
blu_mask2(red_mask < red_thes & blu_mask < blue_thes & gre_mask < gre_thes) = 0;
gre_mask2 = gre_mask;
gre_mask2(red_mask < red_thes & blu_mask < blue_thes & gre_mask < gre_thes) = 0;

red_mask2(red_mask2 > 0) = 1;
blu_mask2(blu_mask2 > 0) = 1;
gre_mask2(gre_mask2 > 0) = 1;

% recombine
fore_mask = cat(2, red_mask2, blu_mask2, gre_mask2);
end