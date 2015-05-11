function [A, B] = hmm_fit(obs, num_states, num_obs)

% convergence parameters
max_iterations = 50;
epsilon = .001;

% convert observations into a binary matrix
n = size(obs, 2);
obs_mat = zeros(n, num_obs);
obs_mat(sub2ind([n, num_obs], 1:n, obs)) = 1;

% initialize transition and emission matrices
% rows must sum to one and not be uniform
A = rand(num_states, num_states);
A = A ./ (sum(A, 2) * ones(1, num_states));
B = rand(num_states, num_obs);
B = B ./ (sum(B, 2)*ones(1, num_obs));


iter = 0;
old_A = A;
old_B = B+epsilon+1;
while  iter < max_iterations
    iter = iter + 1;
    % save previous results
    old_A = A;
    old_B = B;
    
    % forward propagation
    [fward, prob_y] = hmm_forward(obs, old_A, old_B);
    % backward propagation
    bward = hmm_backward(obs, old_A, old_B, prob_y);
    % combine forward and backward results into posterior
    prob_mat = fward .* bward;

    % compute the new transition and emission matrices
    A = old_A .* (fward(:, 1:(end-1)) * ...
        (bward(:, 2:end) .* old_B(:, obs(2:end)) ./ ...
        (ones(num_states, 1) * prob_y(2:end)))');
    % normalize:
    A = A ./ (sum(A, 2) * ones(1, num_states));
    
    % expectation of the number of emissions
    B = prob_mat * obs_mat;
    % normalize:
    B = B ./ (sum(B, 2) * ones(1, num_obs));

    % have the parameter matrices converged?
    if norm(old_A(:) - A(:)) < epsilon && norm(old_B - B) < epsilon
        break;
    end
end

if any(any(isnan(A)))
    A = zeros(size(A));
end
if any(any(isnan(B)))
    B = zeros(size(B));
end

end