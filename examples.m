% April 7th: I changed the input of matrix_to_array(img_mat, NUM_ROWS, NUM_COLS)
    % to matrix_to_array(img_mat, NUM_COLS, NUM_ROWS).  It fixed the
    % problem, and I don't know why.

% IMPORT VIDEO
frameSizeFactor = 4; % Makes frames smaller, faster to compute.
nthFrame = 10; % Take every nth frame from the video.
frameStart = 2860;
frameStop = 2900;
vid = VideoReader('GOPR0298.mp4');
vidWidth = vid.Width;
vidHeight = vid.Height;
nFrames = floor(vid.NumberOfFrame/nthFrame); %%// xyloObj.NumberOfFrames;
%mov = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);
%mov(1:nFrames) = struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),'colormap',[]);
mov = zeros(vidHeight/frameSizeFactor,vidWidth/frameSizeFactor,3,nFrames);
for k = 1 : frameStop - frameStart
    IMG = read(vid, (k-1)*nthFrame+frameStart);
    %// IMG = some_operation(IMG);
    %mov(k).cdata = imresize(IMG,[vidHeight/frameSizeFactor vidWidth/frameSizeFactor]);
    mov(:,:,:,k) = im2double(imresize(IMG,[vidHeight/frameSizeFactor vidWidth/frameSizeFactor]));
end

% GOBAL PARAMETERS;
NUM_ROWS = 480;
NUM_COLS = 480;
% NUM_ROWS = vidHeight/frameSizeFactor; % For .mp4
% NUM_COLS = vidWidth/frameSizeFactor; % For .mp4

% where are files located?
user_name = strtrim(char(java.lang.System.getProperty('user.name')));
if strcmp(user_name, 'robert')
    cd('/Users/robert/documents/UMN/5561_CV/project/code');
    data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
else
    cd('/Users/tomringstrom/Documents/MATLAB/TrackingProject/cs5561_project/');
    data_dir = ('/Users/tomringstrom/Documents/MATLAB/TrackingProject/cs5561_project/data/');
end
file_names = dir(strcat(data_dir, '*.gif'));



% READ IN GIF, PUT IN IMAGE ARRAY
file = file_names(1);
file_name = strcat(data_dir, file.name);
img_array = create_img_array(file_name);
% img_array = mov; % For using the video sequence.
% display 10th image
img = img_array(:,:,:,10);
imshow(uint8(img*255)); title('Image from GIF, stored in 4D array');


% CONVERT 4D array to matrix for analysis
img_mat = array_to_matrix(img_array);
size(img_mat)

% CONVERT image matrix back to a viewable 4D array
img_array2 = matrix_to_array(img_mat, NUM_ROWS, NUM_COLS);
img = img_array2(:,:,:,1)*255;
% does it look the same as original? yes.
figure('Name','Original Preserved','NumberTitle','off');
imshow(uint8(img)); title('Transformation Back to Original');


% CREATE BACKGROUND MODEL
% need to put images into a matrix form!!!!
% split image array into a training and test set
training_sz = 40;
x_train = img_mat(1:training_sz, :);
num_components = 5;
back_vec = background_model(x_train, 'median', num_components);
back_img = matrix_to_array(back_vec, NUM_ROWS, NUM_COLS);
imshow(uint8(back_img*255)); title('Background Image');


% CREATE FOREGROUND MASK
threshold = .15;
fore_mask = foreground_mask(back_vec, img_mat, threshold);
fore_array = matrix_to_array(fore_mask, NUM_ROWS, NUM_COLS);
figure('Name','Foreground Mask','NumberTitle','off');
for i = 1:9
    frame = fore_array(:,:,:, i);
    subplot(3, 3, i);
    plot_title = sprintf('Frame %d', i);
    imshow(uint8(frame*255)); title(plot_title);
end

% reduce noise of foreground:
% label connected regions, keep only regions 25% as large as largest region
fore_mask_img = label_regions(fore_array, 4, .25);
figure('Name','Foreground Mask','NumberTitle','off');
for i = 1:9
    frame = fore_mask_img(:,:,:, i);
    subplot(3, 3, i);
    plot_title = sprintf('Frame %d', i);
    imshow(uint8(frame*255)); title(plot_title);
end



% Put kalman filter here.  % Work with fore_mask_img
imshow(fore_mask_img(:,:,:,1)*255);
pFrame = fore_mask_img(:,:,:,1);

feature1 = load('feat.mat');
feature1 = feature1.feat;
feature1 = rgb2gray(feature1);
feature2 = feature1;

featCoorMap = zeros(2,2,size(fore_mask_img,4)); % feature # X leftRight

for f = 2:size(fore_mask_img,4)
    cFrame = fore_mask_img(:,:,:,f);
    cFrame = rgb2gray(cFrame);
    
    % error occures at frame 23
    xcorrMat = normxcorr2(feature1, cFrame);
    [r,c] = find(xcorrMat == max(max(xcorrMat))); % why does this sometimes return vectors?
    r = r(1); c = c(1);
    flag = false;
    
    
    newFeature = cFrame(max(r - size(feature1,1),1):min(r-1,size(cFrame,1)), ...
        max(c - size(feature1,2),1):min(c-1,size(cFrame,1)));
    
%     if isequal(size(newFeature),size(feature1))
%         feature1 = newFeature; 
%     end
%     newFeature = imresize(newFeature,size(feature1));
    r = min(max(floor(r - (size(feature1,1)/2)),1),size(cFrame,1));
    c = min(max(floor(c - (size(feature1,2)/2)),1),size(cFrame,2));
    
    
    featCoorMap(1,1:2,f) = [r,c];
    
    pFrame = cFrame;
end


% EIGENBACKGROUND ALGORITHM: show only foreground
% applies some of the functions used above all in one step
fore_mat = eigenback(x_train, img_mat, threshold, 'median', num_components);
fore_img = matrix_to_array(fore_mat, NUM_ROWS, NUM_COLS);
figure('Name','Foreground Images','NumberTitle','off');
f = load('featText.mat');
f = f.fe;
f = im2bw(f,0.9);
for i = 2:18
    if mod(i, 2) == 0
        frame = fore_img(:,:,:, i) * 255;
        subplot(3, 3, i/2);
        plot_title = sprintf('Frame %d', i);
        imshow(uint8(frame)); title(plot_title);
    end
end

%% Kalman Filter Code

frames = fore_img;
t = 1; % change in time
sFrame = 1; % starting frame
eFrame = 50; % end frame;
aMag = 1; % acelleration magnitude
mNoiseX = 1; % measurement noise (x)
mNoiseY = 1; % measurement noise (y)
E_z = [mNoiseX, 0; 0, mNoiseY];
E_x = [(t^4)/4, 0, (t^3)/2, 0 
        0, (t^4)/4, 0, (t^3)/2 
        (t^3)/2, 0, t^2, 0 
        0, (t^3)/2, 0, t^2 ] ;
Q_est = [featCoorMap(1,2,2),featCoorMap(1,1,2),0,0];  
Cov = E_x; % initial variance of position
A = [1, 0, t, 0
    0, 1, 0, t
    0, 0, 1, 0
    0, 0, 0, 1];

B = [(t^2)/2, (t^2)/2, t, t];

C = [1, 0, 0, 0; 0, 1, 0, 0];

estPos = []; % position estimated by filter.
estVel = []; % velocity estimated by filter.
truePos = []; % true position.
trueVel = []; % true velocity.

p_est = Cov; 
p_state = []; % Running List of predicted states.
p_var = []; % Running List of predicted Covariance Matracies
rad = 8; % plotting circle radius
circleValues = 0:0.2:2*pi;
figure;
for i = 2:eFrame
    frame = frames(:,:,:,i);
    frame = frame(:,:,1);
    Q_obs(:,i) = [featCoorMap(1,2,i), featCoorMap(1,1,i)]; % x = 2, y = 1
    
    
    % KALMAN FILTER
    % Prediction of next location
    Q_est = (A * Q_est') + (B * aMag)';
    p_state(end+1) = Q_est(1); % Bookkeeping
    % Predict Next CovMat
    Cov = A * Cov * A' * E_x;
    p_var(end+1,:,:) = Cov; % Bookkeeping
    
    % Calculate Gain constant
    K = Cov*C'*inv(C*Cov*C'+E_z);
    
    % new estimate
    if ~isnan(Q_obs(1,i)) && ~isnan(Q_obs(2,i))
        Q_est = Q_est + K * (Q_obs(:,i) - C * Q_est);
    end
    Q_est = Q_est';  
    Cov = (eye(4) - K * C) * Cov;
    
    % Bookkeeping
    estPos(end+1,:) = Q_est(1:2);
    estVel(end+1,:) = Q_est(3:4);
    
    imagesc(img);
    axis off
    colormap(gray);
    hold on;
    plot(rad*sin(circleValues)+Q_obs(2,i),rad*cos(circleValues)+Q_obs(1,i),'.b'); % the actual tracking
    plot(rad*sin(circleValues)+Q_est(2),rad*cos(circleValues)+Q_est(1),'.r'); % the kalman filtered tracking
    hold off
    drawnow;
    pause(0.1);
    
end

