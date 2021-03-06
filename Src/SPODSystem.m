%% Final Project: Smart phone Obstacle Detection System
%
% Shaun S. Mataire (Box 4119)
%
% Jason Liu (Box 4053)
%

%% Setup
warning off;
close all;

vreader = VideoReader('beevid.m4v');
frames = 1:vreader.NumberOfFrames;

%% SYSTEM SCRIPT

% loop through frames
frameNumber = 0;
clusterInforMatrix = [];
for f = 1:vreader.NumberOfFrames-1
    frameNumber = frameNumber + 1;
    img1 = im2double(rgb2gray(vreader.read(f)));
    img2 = im2double(rgb2gray(vreader.read(f+1)));
    imgFrame1 = im2double(vreader.read(f));
    
    % get feture points
    img1points = kpdet(img1);
    img2points = kpdet(img2);
    
    [feat1rows, feat1cols] = find(img1points);
    [feat2rows, feat2cols] = find(img2points);
    
    %% Implementation
    % Since the Lucas-Kanade Method assumes constant flow in small pixel
    % neighborhoods, we assume that each 3X3 pixel neighborhood has the same
    % optical flow vector. To obtain the the optical flow between the two
    % frames, we first calculate the partial derivatives at each point in the
    % image with respect to x, y and t (where t is the 'frame dimension'). As
    % already stated above, the optical flow in small neighborhoods is assumed
    % to be the same for every pixel in that neighborhood. So for each of the
    % pixels in the same neighborhood, their optical flow equations have the
    % same X component and Y component of the flow vector. To get the flow
    % vectors for each of the neighborhoods, we create a system of the optical
    % flow equations for the neighborhoods and solve for for the X- and Y-
    % components of the neighborhood's flow vector.
    %
    % The the three images below shows the flow vectors for each of the 3X3
    % neighborhoods, the optical flow in the first image (at time = t) and the
    % the optical flow in second image (at time = t + 1).
    
    %get the partial derivatives at each point
    Fx = conv2([1 1]', [-1 1],img1,'same') + conv2([1 1]', [-1 1],img2,'same');
    Fy = conv2([1 -1]', [-1 -1],img1,'same') + conv2([1 -1]', [-1 -1],img2,'same');
    Ft = conv2([1 1]', [1 1],img1,'same') + conv2([-1 -1]', [1 1],img2,'same');
    
    imageLen = size(img1, 2);
    imageWid = size(img1, 1);
    
    numNeighbourhoods = (imageLen )/2 * (imageWid )/2;
    
    X = zeros(190, 256);
    Y = zeros(190, 256);
    
    xCord = zeros(190, 256);
    yCord = zeros(190, 256);
    
    %create matrix that has the signifinat vector location
    vectMatrix = zeros(size(img1));
    
    
    %% EXp
    pointIndex = 1;
    numOfFeat = size(feat1cols);
    for point = 1:numOfFeat
        neighbourhoohFX = Fx(feat1rows(point)-1 : feat1rows(point) + 1,feat1cols(point)-1 : feat1cols(point)+1);
        neighbourhoodFY = Fy(feat1rows(point)-1 : feat1rows(point) + 1,feat1cols(point)-1 : feat1cols(point)+1);
        neighbourhoodFT = Ft(feat1rows(point)-1 : feat1rows(point) + 1,feat1cols(point)-1 : feat1cols(point) +1);
        
        A = horzcat(reshape(neighbourhoohFX, [9 1]), reshape(neighbourhoodFY, [9 1]));
        FT = reshape(neighbourhoodFT, [9 1]);
        FT = -FT;
        
        %now find the v = [Vx Vy]', the optical flow vector of the
        %neighbourhood using the sudo inverse of A
        Vxy = pinv(A' * A)* A' * FT;
        xCord(feat1rows(point), feat1cols(point)) = Vxy(1);
        X(feat1rows(point), feat1cols(point)) = feat1cols(point);
        yCord(feat1rows(point), feat1cols(point)) = Vxy(2);
        Y(feat1rows(point), feat1cols(point)) = feat1rows(point);
        
        vectMatrix(feat1rows(point), feat1cols(point)) = sqrt(Vxy(1)^2 +Vxy(2)^2);
        orientMatrix(feat1rows(point), feat1cols(point)) = atan(Vxy(2)/Vxy(1));
    end
    
    % thrshold the magbitudes of the vectors at each point
    threshold = 2.6;
    vectMatrix(vectMatrix < threshold) = 0;
    %%vectMatrix(vectMatrix >= threshold) = 1;
    
    figure;
    subplot(1,3,1);
    
    imshow(img2);
    hold on;
    quiver(X, Y, xCord, yCord, 12);
    title('(1) Flow obtained from two frames');
    hold off;
    
    
    subplot(1,3,2);
    [y, x] = find(vectMatrix);
    imshow(img1);
    hold on;
    plot(x, y, 'r+'), title('(2) Locations of significant movments');
    hold off;
    v = orientMatrix(y(:), x(:));
    % calculate the k clustes
    interestPoints = [x, y, v];
    k = round(sqrt(sqrt(length(x)/2)));
    IDX = kmeans(interestPoints,k);
    
    %mean flow movement for obstable relevance
    
  
    for l = 1:k
        xcores = x(IDX(:)==l);
        ycores = y(IDX(:)==l);
        valss = vectMatrix(ycores(:),xcores(:));
        valss = valss(:);
        valss(valss ==0) = [];
        meanVect = sum(valss)/ length(valss);

        new_row = [frameNumber l meanVect];
        clusterInforMatrix = [clusterInforMatrix ; new_row];
    end
   
    subplot(1,3,3);
    imshow(imgFrame1);
    hold on;
    gscatter(x,y,IDX), title('(4) Flow clusters in initial frame');
    hold off;
end
clusterInforMatrix
%{
figure;
imshow(img2);
hold on;
quiver(X, Y, xCord, yCord, 12);
title('(1) Flow obtained from two frames');
hold off;

figure;
[y, x] = find(vectMatrix);
imshow(img1);
hold on;
plot(x, y, 'r+'), title('(2) Locations of significant movments');
hold off;

figure;
imshow(imgFrame1);
hold on;
gscatter(x,y,IDX), title('(4) Flow clusters in initial frame');
hold off;

 %}

%% Acknowledgments
% [1] Tapu, R., Mocanu, B., Bursuc, A., & Zaharia, T. (n.d.). A
%  Smartphone-Based Obstacle Detection and Classification System for
% Assisting Visually Impaired People.
% 
% [2] Barron, J. L., Fleet, D. J., & Beauchemin, S. S. (1994). Performance
% of  Optical Flow Techniques. International Journal of Computer
% Vision.  doi:10.1007/BF01420984
% 
% [3] Lucas, B. D., & Kanade, T. (1981). An Iterative Image Registration
% Technique with an Application to Stereo Vision.
% 
% [4] MacKay, David (2003). "Chapter 20. An Example Inference Task:
% Clustering" (PDF). Information Theory, Inference and Learning Algorithms.
% Cambridge University Press. pp. 284–292. ISBN 0-521-64298-1. MR 2012999
% 
% [5] Insect on a Flower Free Stock Footage [Video file]. (n.d.). Retrieved
% from
% http://www.videezy.com/nature/2323-insect-on-a-flower-free-stock-footage
% 
% [6] "rule of thumb, n. and adj.". OED Online. December 2012. Oxford
% University Press. Retrieved 7 February 2013
