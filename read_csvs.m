function data = read_csvs(data_dir, file_names)
% data_dir: char, path to csv files
% file_names an object created by dir function
num_files = size(file_names, 1);
if num_files == 1
    file_name = strcat(data_dir, file_names(1).name);
    data = readtable(file_name);
elseif num_files > 1
    for f = 1:num_files
        file_name = strcat(data_dir, file_names(f).name);
        % read in data as a table
        temp = readtable(file_name);
        temp.file = repmat({file_names(f).name}, size(temp,1), 1);
        if f == 1
            % initialize data table as cell array
            data = cell(size(temp,1) * num_files, size(temp,2));
        end
        % save the data in preallocated cell array
        row_start = ((f-1) * size(temp,1)) + 1;
        row_end = f * size(temp,1);
        data(row_start:row_end, :) = table2cell(temp);
    end
    data = cell2table(data);
    data.Properties.VariableNames = temp.Properties.VariableNames;
else
    disp('zero files found');
    data = table();
    data.file = ones(size(data,1), 1);
end
end