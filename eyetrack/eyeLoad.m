function [data,fields,markers,header] = eyeLoad(filename)
%
% [data,fields,markers,header] = eyeLoad(filename)
% 
% Loads raw eye tracking from an Arrington Research format file.
% 
% 2013.12.12 Bob Dougherty <bobd@standford.edu>

% The calibration points were shown for this many seconds:
calDuration = 1.2;

data = [];
fields = {};
header = {};
markers = {};
fid = fopen(filename, 'r');
aLine = fgetl(fid);
while(~isnumeric(aLine))
    %disp(aLine);
    [rowLabel,remainder] = strtok(aLine);
    if(~isnumeric(rowLabel))
        rowLabel = str2num(rowLabel);
    end
    if(rowLabel==5)
        % Read the column headings (in the row that begins with '5').
        while(~isempty(remainder))
            [fields{end+1},remainder] = strtok(remainder);
        end
    elseif(rowLabel==10)
        % data rows begin with a 10.
        tmp = sscanf(remainder,'%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%d\t');
        data(end+1,:) = tmp;
        markers{end+1} = sscanf(remainder,'%*s\t%*s\t%*s\t%*s\t%*s\t%*s\t%*s\t%*s\t%*s\t%*s\t%s%s%s%s%s');
        if(markers{end}(1)=='"'&&markers{end}(end)=='"')
            markers{end} = markers{end}(2:end-1);
        end
    else
        header{end+1} = remainder;
    end
    aLine = fgetl(fid);
end
fclose(fid);

return;
