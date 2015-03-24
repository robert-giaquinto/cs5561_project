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
    % result is:
    % r11 r21 ... r1n r2n ... b11 b21 ... b1n b2n ... g11 g21 ... g1n g2n..
    % example on one frame of 2x2 image collapsed:
    %   test = zeros([2 2 3])
    %   test(:,:,1) = [[1 2]; [3 4]]
    %   test(:,:,2) = [[5 6]; [7 8]]
    %   test(:,:,3) = [[9 10]; [11 12]]
    %   test2 = reshape(test, [1 2*2*3]) = 1 3 2 4 5 7 6 8 9 11 10 12
    %   reshape(test2, [2 2 3]) gives original
    rval(f,:) = img_vec;
end
end