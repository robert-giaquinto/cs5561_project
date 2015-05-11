function rval = array_to_matrix(img_array)
% assume that array is 4 dimensions (i.e. including color dimension)
% goal: collapse to a 2 dimensional matrix
%   - each row is a frame
%   - each column is a pixel (one for each of rgb)
array_sz = size(img_array);
num_frames = array_sz(4);
rval = zeros(num_frames, (array_sz(1) * array_sz(2) * 3));
for f=1:num_frames
    % flatten each color channel
    img_vec = reshape(img_array(:,:,:,f), [1 array_sz(1)*array_sz(2)*3]);
    rval(f,:) = img_vec;
end
end