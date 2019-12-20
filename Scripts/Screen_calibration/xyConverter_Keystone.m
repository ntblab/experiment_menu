%% Digitally keystone the image
%
% Stretch or shrink the top and bottom points according to the keystoning
%
%Inputs: 
% x_org: Original x position
% y_org: Original y position
% UnstretchingFactor: By what ratio do you shrink the screen? 
%
%Outputs:
% x_new: Distorted x position
% y_new: distorted y position

function [x_new, y_new]=xyConverter_Keystone(x_org, y_org, Keystone_val)

%What is the mid point of the y coords
MidY=mean(y_org);
MidX=mean(x_org);

%% Iterate through each dot position and transform it

y_new = y_org; %Preset var size
x_new = zeros(length(x_org),1); %Set to the same

for XYCounter=1:length(y_org)
    
    % What are the coordinates?
    iX=x_org(XYCounter);
    iY=y_org(XYCounter);
    
    %How much does the x value move? If negative it means getting closer
    x_change = (abs(iY - MidY) * ((Keystone_val - 1) * sign(iY-MidY))) * abs(iX - MidX) / MidX; %How far is the unstretched position from the midline
    
    x_hemifield = sign(iX - MidX);  % Is the x value above or below the midline
    x_new(XYCounter) = round(iX + (x_change * x_hemifield)); %Find the new value by shifting it along the midline. The 60 is subtracted due to a shift that results from the display. This is adhoc.
    
end
%scatter(x_new, max(y_new) - y_new)


