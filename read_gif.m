
data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
file_names = dir(strcat(data_dir, '*.gif'));
for file = file_names'
    % load all the gif images
    file_name = strcat(data_dir, file.name);
    img_array = create_img_array(file_name);
end

img = img_array(:,:,:,10);
imshow(uint8(img*255));
