clear;

% Implement a classification of object behavior
% In final system, will rely on Tom's work for locations
% in the meantime use the data that creates the GIFs

% 1. Import all of the csv files
user_name = strtrim(char(java.lang.System.getProperty('user.name')));
if strcmp(user_name, 'robert')
    cd('/Users/robert/documents/UMN/5561_CV/project/code');
    data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
else
    cd('/Users/robert/documents/MATLAB/...');
    data_dir = '/Users/Tom/documents/.../data/';
end
file_names = dir(strcat(data_dir, '*_beach*.csv'));
all_data = read_csvs(data_dir, file_names);


% 2. put positions of each agent as separate variables
% identify other agents
agent_names = unique(all_data.agent);
others = agent_names(strcmp(agent_names, 'one') == 0);
num_other_agents = size(others, 1);
% initialize new wider table
data = all_data(strcmp(all_data.agent, 'one'),:);
var_names = all_data.Properties.VariableNames;
num_vars = size(var_names, 2);
% loop through other agents table and add it to the data table
for i=1:num_other_agents
    other_name = others(i);
    data_other = all_data(strcmp(all_data.agent, other_name),:);
    % drop action since we cannot know this, and agent name
    data_other.status = [];
    data_other.agent = [];
    % modify variable names to distinguish them from agent one
    for v=1:num_vars-2
        data_other.Properties.VariableNames(v) = strcat(...
            data_other.Properties.VariableNames(v), ...
            '_', other_name);
    end
    data = innerjoin(data, data_other, 'LeftKeys', [1, 6], 'RightKeys', [1, 4]); 
end
data.agent = [];
% change action variable to binary
data.target = zeros(size(data, 1), 1);
data.target(strcmp(data.status, 'evading!') == 1) = 1;
data.status = [];

% 3. transform other agents positions into features
var_names = data.Properties.VariableNames;
num_vars = size(var_names, 2);
for i=1:num_other_agents
    % find difference in x distance
    newx_var_name = strcat('one_', others(i), '_x_dist');
    other_x_var_name = strcat('x_pos_', others(i));
    data{:, newx_var_name} = abs(data.x_pos - data{:, other_x_var_name});
    % distance in y
    newy_var_name = strcat('one_', others(i), '_y_dist');
    other_y_var_name = strcat('y_pos_', others(i));
    data{:, newy_var_name} = abs(data.y_pos - data{:, other_y_var_name});
end

% split into test and training data
% TBD
pred_vars = {'x_pos', 'y_pos', 'x_pos_two', 'y_pos_two', 'one_two_x_dist', 'one_two_y_dist'};
x = data{:, pred_vars};
y = data.target;
cvpart = cvpartition(data.target, 'holdout', 0.3);
x_train = x(training(cvpart), :);
y_train = y(training(cvpart), :);
x_test = x(test(cvpart), :);
y_test = y(test(cvpart), :);

% fit model on training data
boost = fitensemble(x_train, y_train, 'AdaBoostM1', 250, 'Tree');
% pred = predict(boost, x_test);

figure;
plot(loss(boost, x_train, y_train, 'mode', 'cumulative'), 'b');
hold on;
plot(loss(boost, x_test, y_test, 'mode', 'cumulative'), 'r');
hold off;
legend('Train','Test','Location','NE');
xlabel('Number of Trees');
ylabel('Classification Error');
title('AdaBoost Behavior Classification Error');



