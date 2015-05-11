function [fward, prob_y] = hmm_forward(obs, A, B)

% initialize each term
T = size(obs, 2);
fward = zeros(size(A, 1), T);
prob_y = zeros(1, T);
prior = zeros(size(A,1), 1);
prior(2) = 1;

% loop through each obervation
for t=1:T
    if t == 1
        Z = prior .* B(:, obs(1));
        prob_y(1)= max(sum(Z), .01);
        fward(:, 1) = Z/prob_y(1);
    else
        Z = (fward(:, t-1)' * A)' .* B(:, obs(t));
        prob_y(t) = max(sum(Z), .01);
        fward(:, t) = Z / prob_y(t);
    end
end
% not sure why I'm still getting nans sometimes... just ignore
% prediction in this case
if any(any(isnan(fward)))
    fward = zeros(size(A, 1), T);
end
end
