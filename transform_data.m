function data = transform_data(all_data, NUM_ROWS, NUM_COLS)
% 1. add speed and direction features to data
all_data.velocity = zeros([size(all_data, 1), 1]);
all_data.direction = zeros([size(all_data, 1), 1]);
for i = 2:size(all_data,1)
    if strcmp(all_data.agent(i), all_data.agent(i-1)) && strcmp(all_data.file(i), all_data.file(i-1))
        % previous information available
        x_dif = (all_data.x_pos(i) - all_data.x_pos(i-1)) * NUM_COLS;
        y_dif = (all_data.y_pos(i) - all_data.y_pos(i-1)) * NUM_ROWS;
        distance = sqrt(x_dif^2 + y_dif^2);
        all_data.velocity(i) = round(distance, 2);  % assume one time step
        direction = round(atand(y_dif / x_dif));
        if direction < 0
            direction = direction + 360;
        elseif direction > 360
            direction = direction - 360;
        elseif isnan(direction)
            direction = 0;
        end
        all_data.direction(i) = direction;
    end
end
        
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
data.evade = zeros(size(data, 1), 1);
data.evade(strcmp(data.status, 'evade') == 1) = 1;
data.cutoff = zeros(size(data, 1), 1);
data.cutoff(strcmp(data.status, 'cutoff') == 1) = 1;
data.status = [];

% 3. transform other agents positions into features
for i=1:num_other_agents
    % find difference in x distance
    newx_var_name = strcat('one_', others(i), '_x_dist');
    other_x_var_name = strcat('x_pos_', others(i));
    data{:, newx_var_name} = abs(data.x_pos - data{:, other_x_var_name}) * NUM_COLS;
    % distance in y
    newy_var_name = strcat('one_', others(i), '_y_dist');
    other_y_var_name = strcat('y_pos_', others(i));
    data{:, newy_var_name} = abs(data.y_pos - data{:, other_y_var_name}) * NUM_ROWS;
end
data.distance = sqrt(data.one_two_x_dist.^2 + data.one_two_y_dist.^2);

% finally transform data into meaningful order
data = sortrows(data, {'file', 'step'});
end