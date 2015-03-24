function rval = matrix_to_array(img_mat, n_rows, n_cols)
% this function takes the frame matrix (which is easy to analyze)
% and converts it back into an array (which is easy to view)
% img_mat = image matrix 2D
% n_rows = number of rows (vertical pixels) in original images
% n_cols = number of columns (horizontal pixels) in original images
% return: an image array of size [n_rows n_cols 3 num_frames]
mat_sz = size(img_mat);
num_frames = mat_sz(1);
rval = zeros([n_rows n_cols 3 num_frames]);

% loop through each image vector and convert to a 3d array
% representing an RGB image
for f = 1:num_frames
    img_vec = img_mat(f, :);
    rgb_img = reshape(img_vec, [n_rows n_cols 3]);
    rval(:,:,:,f) = rgb_img;
end
end
