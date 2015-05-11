function [x_seq, y_seq] = sliding_window(clusters, y, window_sz, num_steps)
% this is a function to split observations into multiple
% observations via a sliding window.
% automatically, slides the window 1 frame from window_sz
% to total number of frames in the image.
% will separate different videos into different observations (no
% overlapping).

num_videos = size(clusters,1) / num_steps;

% initialize output data
num_obs = num_steps - window_sz + 1; % per video
x_seq  = zeros(num_obs * num_videos, window_sz);
y_seq  = zeros(num_obs * num_videos, size(y,2));
for v = 1:num_videos
    for i = 1:num_obs
        start_ind = i + ((v-1) * num_steps) - ((v-1) * (window_sz - 1));
        end_ind = start_ind + window_sz - 1;
        x_seq(start_ind, :) = clusters(start_ind:end_ind)';
        y_seq(start_ind, :) = y(end_ind, :);
    end
end

end