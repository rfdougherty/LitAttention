% Compute calibrated gaze coordinates

infile = '/scratch/fMRI/phillips/s04/behavior/lit1_20120612_120139.csv';

[data,fields,markers,header] = eyeLoad(infile);

[p,f,e] = fileparts(infile);
outbase = fullfile(p,[f '_calibrated']);

% This *should* be 16.7ms (60Hz video)
deltaTime = median(data(:,2))/1000;

curMarkers = markers;
blockStartEnd = [];
for block = 1:3
    % Find 'start0/end7' markers and use them to chop the data into blocks.
    curCal = strmatch('Cal', curMarkers);
    curStart = curCal(1) + strmatch('start0', curMarkers(curCal(1):end));
    curEnd = curStart(1) + strmatch('end7', curMarkers(curStart(1):end));

    blockStartEnd(block,:) = [curCal(1), curStart(1), curEnd(1)];
    for ii=blockStartEnd(block,1):blockStartEnd(block,3)
        curMarkers{ii} = 'None';
    end
end

numCalPts = floor(11.0/deltaTime);
for block = 1:3
    % Estimate the calibration parameters
    calInds = [blockStartEnd(block,1):blockStartEnd(block,1)+numCalPts];
    [cal, calPts, estCalPts] = eyeComputeCalibration(data(calInds,3:4), markers(calInds), round(0.5/deltaTime));
    [calPts, estCalPts]
    
    % compute and save gaze coordinates
    gazeInds = blockStartEnd(block,2):blockStartEnd(block,3);
    fid = fopen(sprintf('%s_block%d.csv',outbase,block), 'w');
    fprintf(fid, 'time, gaze_x, gaze_y, marker\n');
    gaze = eyeComputeGaze(data(gazeInds,3:4), cal);
    for ii=1:size(gazeCoords,1)
        fprintf(fid, '%0.4f, %0.4f, %0.4f, %s\n', (ii-1)*deltaTime, gaze(ii,1), gaze(ii,2), markers{gazeInds(ii)});
    end
    fclose(fid);
    
    %figure(1);axis([-1,1,-1,1]); hold on;
    %for(ii=1:size(gaze,1)), c='r'; plot(gaze(ii,1),gaze(ii,2),[c '.']); title(markers{gazeInds(ii)}); pause(0.05); end
end




% data(strcmpi('NONE',markers),:) = []; markers(strcmpi('NONE',markers)) = [];
% gaze = eyeComputeGaze(data(:,3:4), cal);
% gaze(gaze>0.8)=NaN; gaze(gaze<-0.8)=NaN;
% figure(1);axis([-1,1,-1,1]); hold on;
% for(ii=1:size(gaze,1)), c='r'; plot(gaze(ii,1),gaze(ii,2),[c '.']); title(markers{ii}); pause(0.05); end
%
% [data,fields,markers] = eyeLoad('/scratch/fMRI/phillips/s4/eye/litAttn_20111212_123024.csv');
% gaze = eyeComputeGaze(data(strcmpi('start0',markers),3:4), cal);
% gaze(abs(gaze(:,1))>0.8|abs(gaze(:,2))>0.8|isnan(gaze(:,1))|isnan(gaze(:,2)),:)=NaN;
% figure(2);axis([-1,1,-1,1]); plot(gaze(500:1000,1),gaze(500:1000,2),'r-');