function detectionImg = kpdet( img )
% KPDET Returns a logical matrix the same size as the image containing the
% locations of image features. Locations are found using the ratio of the
% trace to the determinant of the matrix A: [[Ix^2; IxIy]; [IxIy; Iy^2]]
%
% detectionImg = kpdet(img) where img is an image for feature detection and
% detectionImg is a logical matrix of the same size as the image where
% local maxima beyond a threshold (ie well localized features) are
% indicated by non-zero entries.
%
%
% Lab:
%  Feature Detection

% create Gaussian and Gaussian derivative as separable filters to create
% partial derivatives
gauss = gkern(1);
gaussder = gkern(1, 1);
gaussblur = gkern(1.5^2);  % Gaussian with larger variance for blurring
% create partial derivs along rows and columns
rowderiv = conv2(gauss, gaussder, img, 'same');
colderiv = conv2(gaussder, gauss, img, 'same');
rowsquare = rowderiv.^2 ;  % find sqaure of partials Ix^2, Iy^2
colsquare = colderiv.^2;
rowblur = conv2(gaussblur, gaussblur, rowsquare, 'same'); % blur again
colblur =  conv2(gaussblur, gaussblur, colsquare, 'same');


derivProduct = rowderiv .* colderiv;  % IxIy
%blur product
productblur = conv2(gaussblur, gaussblur, derivProduct, 'same');
% determinant ab-bc 
pixeldet = rowblur .* colblur - productblur .^ 2; 
pixeltrace = rowblur + colblur; % trace Ix^2 + Iy^2
pixelratio = pixeldet ./ pixeltrace;  

maxImg = maxima(pixelratio); % consider maxima in image
thresholded = pixelratio > .0001; % discard values under threshold
% find points that are maxima above the threshold
detectionImg = maxImg .* thresholded; 
end

