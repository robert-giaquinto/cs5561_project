function [x_train, y_train, x_test, y_test] = split_data(data, pred_vars, tar_var, pct_test)
% select pct_test percent of the training files for testing on
uniq_files = unique(data.file);
num_files = size(uniq_files, 1);
train_ind = randperm(num_files, round((1 - pct_test) * num_files));
train_files = uniq_files(train_ind);
test_files = uniq_files(ismember(1:num_files, train_ind) == 0);
% split the data based on which file the row corresponds to
x_train = data{ismember(data.file, train_files), pred_vars};
x_test = data{ismember(data.file, test_files), pred_vars};

if strcmp(tar_var{1}, 'target')
    y_train = cellstr(data{ismember(data.file, train_files), tar_var});
    y_test = cellstr(data{ismember(data.file, test_files), tar_var});
else
    y_train = data{ismember(data.file, train_files), tar_var};
    y_test = data{ismember(data.file, test_files), tar_var};
end

end