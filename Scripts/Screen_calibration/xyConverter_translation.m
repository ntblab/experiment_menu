%% Shift the X or Y values of the unwarping

%Inputs:
% x_org: Original x position
% y_org: Original y position
% translation: Mat of x and y shift values

%Outputs:
% x_new: Distorted x position
% y_new: Dåistorted y position

function [x_new, y_new]=xyConverter_translation(x_org, y_org, translation)

%% Shift the X and Y values by the specified amount
x_new=x_org + translation(1);
y_new=y_org + translation(2);

% % If you want to see the distortion use this but it is harder to interpret
% scatter(x_new, max(y_new) - y_new)
% xlim([0, 1920]);
% ylim([0, 1080]);


