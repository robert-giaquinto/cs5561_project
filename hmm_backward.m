function backward = hmm_backward(obs, A, B, prob_y)

% initialize output
T = size(obs, 2);
backward = zeros(size(A, 1), T);
backward(:, end) = 1;

% loop through each observation in reverse
for t=(T-1):-1:1
  backward(:, t) = A * (B(:, obs(t+1)) .* backward(:, t+1)) / prob_y(t+1);
end
