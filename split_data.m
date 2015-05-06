function [x_train, y_train, x_test, y_test] = split_data(data, pred_vars, tar_var, pct_test)

uniq_files = unique(data.file);
num_files = size(uniq_files, 1);
train_ind = randperm(num_files, round((1 - pct_test) * num_files));
train_files = uniq_files(train_ind);
test_files = uniq_files(ismember(1:num_files, train_ind) == 0);

x_train = data{ismember(data.file, train_files), pred_vars};
y_train = data{ismember(data.file, train_files), tar_var};
x_test = data{ismember(data.file, test_files), pred_vars};
y_test = data{ismember(data.file, train_files), tar_var};
end