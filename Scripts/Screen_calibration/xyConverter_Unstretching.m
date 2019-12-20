%% Convert a set of x and y values to be shrunk by a given factor

%Inputs:
% x_org: Original x position
% y_org: Original y position
% UnstretchingFactor: By what ratio do you shrink the screen?

%Outputs:
% x_new: Distorted x position
% y_new: distorted y position

function [x_new, y_new]=xyConverter_Unstretching(x_org, y_org, UnstretchingFactor)

%What is the mid point of the y coords
MidX=mean(x_org);
MidY=mean(y_org);

%% Iterate through each dot position and transform it
x_new=x_org; %Set to the same
y_new=y_org; %Set to the same

for XYCounter=1:length(y_org)
    
    % Pull coordinates
    iX=x_org(XYCounter);
    iY=y_org(XYCounter);
    
%     if UnstretchingFactor > 1
        %Store the new coordinates
        Mid_Dist=abs(iY - MidY) * UnstretchingFactor; %How far is the unstretched position from the midline
        
        y_new(XYCounter) = round(MidY + (Mid_Dist * sign(iY - MidY))); %Find the new value by shifting it along the midline. This may require an adhoc additional subtraction.
%     else
%         %Store the new coordinates
%         Mid_Dist=abs(iX - MidX) / UnstretchingFactor; %How far is the unstretched position from the midline
%         
%         x_new(XYCounter) = round(MidX + (Mid_Dist * sign(iX - MidX))); %Find the new value by shifting it along the midline. This may require an adhoc additional subtraction.
%     end
end

% % If you want to see the distortion use this but it is harder to interpret
% scatter(x_new, max(y_new) - y_new)
% xlim([0, 1920]);
% ylim([0, 1080]);


