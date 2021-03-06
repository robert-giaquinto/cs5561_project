clear;
close;
matlabmail('rings034@gmail.com','hi','currently running kalman','trdummy4@gmail.com','matlabpw?);
% IMPORT DATA
% where are data files located?
user_name = strtrim(char(java.lang.System.getProperty('user.name')));
if strcmp(user_name, 'robert')
    cd('/Users/robert/documents/UMN/5561_CV/project/code');
    data_dir = '/Users/robert/documents/UMN/5561_CV/project/data/';
else
    cd('/Users/tomringstrom/Documents/MATLAB/TrackingProject/cs5561_project/');
    data_dir = ('/Users/tomringstrom/Documents/MATLAB/TrackingProject/cs5561_project/data/');
end
% FOR PROFESSOR OR TA:
data_dir = '';

source_data = 'synthetic';
if strcmp(source_data, 'real')
    nthFrame = 5; % Take every nth frame from the video.
%     frameStart = 2900;
%     frameStop = 3350;
    frameStart = 1500;
    frameStop = 3400;
     %gopro0302 starts at 1770, ends at 2330. There is more after though
    %gopro0303 1650-2150. 2420-2650. 2900-3350
    vid = VideoReader(strcat(data_dir, 'GOPR0303.mp4'));
    vidWidth = vid.Width;
    vidHeight = vid.Height;
    nFrames = ((frameStop-frameStart)/nthFrame);

    % Make frames smaller, faster to compute.
    frameSizeFactor = 4; 
    img_array = zeros(vidHeight/frameSizeFactor,vidWidth/frameSizeFactor,3, nFrames);
    vidIndexList = frameStart:nthFrame:frameStop; % holds all of the indicies of the frames to be used.
    for k = 1:length(vidIndexList)
        IMG = read(vid, vidIndexList(k));
        img_array(:,:,:,k) = im2double(imresize(IMG,[vidHeight/frameSizeFactor vidWidth/frameSizeFactor]));
    end
    NUM_ROWS = vidHeight/frameSizeFactor; % For .mp4
    NUM_COLS = vidWidth/frameSizeFactor; % For .mp4
else
    % import the synthetic data
    file_names = dir(strcat(data_dir, '*.gif'));
    file = file_names(1); %31 for single dot
    file_name = strcat(data_dir, file.name);
    img_array = create_img_array(file_name);
    NUM_ROWS = 480;
    NUM_COLS = 480;
    nFrames = 50;
end

% display first image from video
img = img_array(:,:,:,1);
imshow(uint8(img*255)); title('Image from GIF, stored in 4D array');

% CONVERT 4D array to matrix for analysis
img_mat = array_to_matrix(img_array);

% CONVERT image matrix back to a viewable 4D array
% img_array2 = matrix_to_array(img_mat, NUM_ROWS, NUM_COLS);
% img = img_array2(:,:,:,1)*255;
% % does it look the same as original? yes.
% figure('Name','Original Preserved','NumberTitle','off');
% imshow(uint8(img)); title('Transformation Back to Original');


% CREATE BACKGROUND MODEL
% split image array into a training and test set
training_sz = nFrames*.5;
x_train = img_mat(1:training_sz, :);
num_components = 5;
% use Oliver's eigenbackground approach, taking mean in low D space
back_vec = background_model(x_train, 'mean', num_components);
back_img = matrix_to_array(back_vec, NUM_ROWS, NUM_COLS);
imshow(uint8(back_img*255)); title('Background Image');


% CREATE FOREGROUND MASK
threshold = .075;
fore_mask = foreground_mask(back_vec, img_mat, threshold); % threshold should be 0.05 for video
fore_array = matrix_to_array(fore_mask, NUM_ROWS, NUM_COLS);
figure('Name','Foreground Mask','NumberTitle','off');
for i = 1:9
    frame = fore_array(:,:,:, i);
    subplot(3, 3, i);
    plot_title = sprintf('Frame %d', i);
    imshow(uint8(frame*255)); title(plot_title);
end

% reduce noise of foreground:
% label connected regions, keep only regions 33% as large as largest region
fore_mask_img = label_regions(fore_array, 4, .33);
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
feature1 = load('featureP.mat');
feature1 = feature1.featureP;
featCoorMap = zeros(2,2,size(fore_mask_img,4)); % feature # X leftRight
numOfObjects = 2;
for f = 2:size(fore_mask_img,4)
    cFrame = fore_mask_img(:,:,:,f);
    cFrame = rgb2gray(cFrame);
    a = 1;
    % error occures at frame 23
    xcorrMat = normxcorr2(feature1, cFrame);
    for i = 1:numOfObjects
        
        [r,c] = find(xcorrMat == max(max(xcorrMat))); % why does this sometimes return vectors?
        r = r(1); c = c(1);
        
        ydist = (size(feature1,1)/2)+5;
        xdist = (size(feature1,2)/2)+2;
        ytodel = r-floor(ydist):ceil(r+ydist);
        xtodel = c-floor(xdist):ceil(c+xdist);
        xcorrMat(ytodel,xtodel) = 0;
        flag = false;
%         cFrame(max(r - size(feature1,1),1):min(r-1,size(cFrame,1)), ...
%             max(c - size(feature1,2),1):min(c-1,size(cFrame,1))) = 0;
        
        r = min(max(floor(r - (size(feature1,1)/2)),1),size(cFrame,1));
        c = min(max(floor(c - (size(feature1,2)/2)),1),size(cFrame,2));
        
        featCoorMap(i,1:2,f) = [r,c]; %1 = y, 2 = x
    end
    newFeature = cFrame(max(r - size(feature1,1),1):min(r-1,size(cFrame,1)), ...
        max(c - size(feature1,2),1):min(c-1,size(cFrame,1)));
    
    %     if isequal(size(newFeature),size(feature1))
    %         feature1 = newFeature;
    %     end
    %     newFeature = imresize(newFeature,size(feature1));

    pFrame = cFrame;
end


% EIGENBACKGROUND ALGORITHM: show only foreground
% applies some of the functions used above all in one step
fore_mat = eigenback(x_train, img_mat, threshold, 'mean', num_components, 1, NUM_ROWS, NUM_COLS);
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



% %% Kalman Filter Code
% fileStruct = load('doubleDot');
% featCoorMap = fileStruct.featCoorMap;
frames = fore_img;
% imgarr = load('doubleDotimgs');
% frames = imgarr.img_array;
frames = img_array;
t = 1; % change in time
sFrame = 1; % starting frame
eFrame = size(frames,4); % end frame;
aMag = 1; % acelleration magnitude
mNoiseX = 0.5; % measurement noise (x).  More measurement noise means don't trust measurement as much
mNoiseY = 0.5; % measurement noise (y)
E_z = [mNoiseX, 0; 0, mNoiseY];
E_x = [(t^4)/4, 0, (t^3)/2, 0
    0, (t^4)/4, 0, (t^3)/2
    (t^3)/2, 0, t^2, 0
    0, (t^3)/2, 0, t^2 ] ;
for f = 1:numOfObjects
    Q_est(f,:) = [featCoorMap(f,2,2),featCoorMap(f,1,2),0,0];  %x,y,vx,vy
    cov(1:4,1:4,f) = E_x;
end

% cov(1:2,:,:) = [E_x,E_x]; % initial variance of position.  Check this
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

p_est = cov;
p_state = []; % Running List of predicted states.
p_var = []; % Running List of predicted Covariance Matracies
rad = 8; % plotting circle radius
circleValues = 0:0.2:2*pi;
figure;
for f = 2:eFrame
    pause(0.3);
    frame = frames(:,:,:,f);
    %     frame = frame(:,:,:,1);
    
    % For each previous object estimation, j, use observation coordinates
    % that are closest to the prediction.
    indexList = 1:numOfObjects;
    for j = 1:numOfObjects
        
        curQ_est = Q_est(j,:);
        curCov = cov(:,:,j);
        bestEstScore = inf; % Lower is better, distance between 
        % For each coordinate featCoorMap, run the kalman filter
        for k = 1:length(indexList)
            ind = indexList(k);
            
            % This part needs to be rethought 
            Q_obs = [featCoorMap(ind,2,f), featCoorMap(ind,1,f)]; % x = 2, y = 1
            
            % KALMAN FILTER
            % Prediction of next location
            tempQ_est = (A * curQ_est') ;%+ (B * aMag)';  % why does it work better when B*aMag is commented out?
            
            % Predict Next CovMat
            tempcov = A * curCov * A' * E_x;
            
            
            % Calculate Gain constant
            K = tempcov*C'*inv(C*tempcov*C'+E_z);
%             K = zeros(size(K));
            
            % new estimate
            if ~isnan(Q_obs(1)) && ~isnan(Q_obs(2))
                tempQ_est = tempQ_est + K * (Q_obs' - C * tempQ_est);
            end
            
            % Here we now have an estimate, tempQ_est, and we need to store
            % this estimate and compare to the cartitian coordinates of the
            % observation.
            
            score = sqrt(sum((tempQ_est(1:2) - Q_obs(1:2)').^2));
            
            % Evaulate scores, assign Q_est and cov if best score
            if score < bestEstScore
                bestEstScore = score;
                Q_est(j,:) = tempQ_est';
                Ident = eye(4);
                cov(:,:,j) = (Ident - K * C) * curCov;
                indexUsed = ind;
            end
        end
        removeIndex = find(indexList == indexUsed);
        indexList = [indexList(1:removeIndex-1),indexList(removeIndex+1:end)];
%         p_var(end+1,:,:) = cov; % Bookkeeping
%         p_state(end+1) = Q_est(1); % Bookkeeping
        
        % actualPos holds the measured coordinates in the proper index, j,
        % which is consistant with Q_est, estPos, estVel.
        actualPos(j,1:2,f) = [featCoorMap(indexUsed,2,f), featCoorMap(indexUsed,1,f)]; % in x,y
        % Bookkeeping
        estPos(j,1:2,f) = Q_est(j,1:2);
        estVel(j,1:2,f) = Q_est(j,3:4);
    end
  
    hold on;
    sx = size(frame,2);
    sy = size(frame,1);
    imagesc(flipud(frame));
    axis image
    %     axis off
    colormap(gray);
    plot(rad*sin(circleValues)+actualPos(1,1,f),rad*cos(circleValues)+(sy-actualPos(1,2,f)),'.g'); % the actual tracking
    plot(rad*sin(circleValues)+estPos(1,1,f),rad*cos(circleValues)+(sy-estPos(1,2,f)),'.r'); % the kalman filtered tracking
    if numOfObjects == 2
        plot(rad*sin(circleValues)+actualPos(2,1,f),rad*cos(circleValues)+(sy-actualPos(2,2,f)),'.b'); % the actual tracking
        plot(rad*sin(circleValues)+estPos(2,1,f),rad*cos(circleValues)+(sy-estPos(2,2,f)),'.y'); % the kalman filtered tracking
    end
    
    hold off
    %     set(gca,'Ydir','Normal')
    %     set(gca,'Xdir','Normal')
    drawnow;
    disp(f)
    
end
matlabmail('rings034@gmail.com','hi','successfully ran kalman','trdummy4@gmail.com','matlabpw?);

