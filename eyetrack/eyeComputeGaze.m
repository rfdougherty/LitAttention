function gaze = eyeComputeGaze(rawCoords, cal)
%
% gaze = eyeComputeGaze(rawCoords, cal)
% 
% Computes calibrated gaze coordinates given raw data and a bi-quadratic 
% calibration matrix (cal).
%
% (See eyeComputeCalibration for details.)
%
% 2013.12.12 Bob Dougherty <bobd@standford.edu>
%

gaze = [rawCoords rawCoords.^2 ones(size(rawCoords,1),1)] * cal.mat;
gaze = gaze(:,1:2);
signGaze = sign(gaze);
signGaze(signGaze==0) = 1;
[junk,quad] = ismember(signGaze,cal.quadSign,'rows');
gaze = gaze + cal.quadScale(quad,:).*repmat(gaze(:,1).*gaze(:,2),1,2);

return;


