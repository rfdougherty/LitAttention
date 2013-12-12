function [cal, calPts, estCalPts] = eyeComputeCalibration(calData, calMarkers, numSkip)
%
% [cal, calPts, estCalPts] = eyeComputeCalibration(calData, calMarkers, numSkip)
% 
% Computes a bi-quadratic calibration matrix from some calibration data.
% Specifically, a biquadratic mapping function with a piece-wise correction
% factor, introduced by Sheena and Borah (1981). This implemetation is 
% based on the description in "D. Stampe (1993). Heuristic filtering
% and reliable calibration methods for video-based pupil-tracking systems. 
% B R M, I & C."
%
% See also eyeComputeGaze.
%
% 2013.12.12 Bob Dougherty <bobd@standford.edu>
%

calCoord = [];
for(ii=1:numel(calMarkers))
    [calCoord(ii,:),n] = sscanf(calMarkers{ii},'Cal(%f,%f)');
end

[calPts,I,J] = unique(calCoord,'rows');

for(ii=1:size(calPts,1))
    allEyePts = calData(J==ii,1:2);
    % take readings from the later part of the interval
    allEyePts = allEyePts(numSkip:end, :);
    mn = mean(allEyePts);
    sd = std(allEyePts);
    z = [(mn(1)-allEyePts(:,1))./sd(1) (mn(2)-allEyePts(:,2))./sd(2)];
    bad = any(abs(z)>2,2);
    fprintf('Rejecting %d out of %d points for coord (%d,%d).\n',sum(bad),numel(bad),calPts(ii,:));
    eyePts(ii,:) = mean(allEyePts(~bad,:));
end
corner = [1 3 7 9];
center = [2 4 5 6 8];
% Compute the bi-quadratic calibration matrix for all cal points except the four corners.
cal.mat = pinv([eyePts(center,:) eyePts(center,:).^2 ones(numel(center),1)])*[calPts(center,:) ones(numel(center),1)];
estCalPts = [eyePts(corner,:) eyePts(corner,:).^2 ones(numel(corner),1)]*cal.mat;
estCalPts = estCalPts(:,1:2);
% Use the four corners to compute the quadrant
cal.quadScale = (calPts(corner,:)-estCalPts) ./ repmat(estCalPts(:,1).*estCalPts(:,2),1,2);
cal.quadSign = sign(calPts(corner,:));
estCalPts = eyeComputeGaze(eyePts, cal);

return

