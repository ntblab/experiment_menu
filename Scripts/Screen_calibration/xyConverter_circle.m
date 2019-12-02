%% Convert a set of x and y values to be distorted based on a radius

%Inputs:
% x_org: Original x position
% y_org: Original y position
% arcHeight: How many pixels above or below the horizontal is the maximum
% of the curve (infers the radius based on the max of x_org and y_org which
% gives the chord).

%Outputs:
% x_new: Distorted x position
% y_new: distorted y position

function [x_new, y_new]=xyConverter_circle(x_org, y_org, arcHeight)

%If you aren't changing the arc height then skip this
if arcHeight==0
    x_new=x_org;
    y_new=y_org;
else
    
    %% Find the centre of the circle given the appropriate coordinates
    Concavity=sign(arcHeight); %Is it positive or negative
    
    arcHeight=abs(arcHeight); %Remove the sign from arcHeight
    
    Chord=max(x_org); %How wide is the chord?
    
    %Use pythagoras and substitution:
    %arcHeight + triangleHeight =Radius; 
    %Radius^2-(Chord/2)^2= triangleHeight^2; %Pythagoras
    %(arcHeight + triangleHeight)^2 - (Chord/2)^2= triangleHeight^2; %Substitute
    %(arcHeight^2 + triangleHeight^2 +(triangleHeight*arcHeight*2))-(Chord/2)^2= triangleHeight^2; %Expand
    %(arcHeight^2 + triangleHeight^2+(triangleHeight*arcHeight*2))-triangleHeight^2=(Chord/2)^2; %Rearrange
    %arcHeight^2+(triangleHeight*arcHeight*2)=(Chord/2)^2; %Simplify
    %(triangleHeight*arcHeight*2)=(Chord/2)^2-arcHeight^2; %Rearrange
    %triangleHeight=((Chord/2)^2-arcHeight^2)/(arcHeight*2); %Rearrange
    
    triangleHeight=((Chord/2)^2-arcHeight^2)/(arcHeight*2); %Find the triangleHeight
    
    Radius=triangleHeight+arcHeight; %Find the radius of the circle
    
    %Where is the center of the circle
    cx=Chord/2;
    cy= -triangleHeight; %Should be the appropriate distance away
    
    
    %% Iterate through each dot position and transform it
    
    y_new=zeros(length(y_org),1); %Preset var size
    x_new=zeros(length(x_org),1);
    for XYCounter=1:length(y_org)
        
        %Set the positions for this trial
        iX=x_org(XYCounter);
        iY=y_org(XYCounter);
        
        %Rearrange the equation to find the angle corresponding to a
        %given x position
        Angle=acos((iX - cx)/Radius);
        
        Position = cy + (Radius * sin(Angle)); %This can be positive or negative
        
        %This will happen at the top of the arc
        if isnan(Position)
            Position=0;
        end
        
        %Store the new coordinates
        y_new(XYCounter)= round(iY + (Position*Concavity));
        x_new(XYCounter)= iX;
        
    end
    
end



