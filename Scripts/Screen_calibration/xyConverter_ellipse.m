%% Convert a set of x and y values to be distorted based on a radius

%Inputs:
% x_org: Original x position
% y_org: Original y position
% arcHeight: How many pixels above or below the horizontal is the maximum
% of the curve (infers the radius based on the max of x_org and y_org which
% gives the chord).
% Radius_Width how wide is the circle at its widest

%Outputs:
% x_new: Distorted x position
% y_new: distorted y position

function [x_new, y_new]=xyConverter_ellipse(x_org, y_org, Radius_Height, Radius_Width)

%If you aren't changing the arc height then skip this
if Radius_Height==0
    x_new=x_org;
    y_new=y_org;
else
    
    %Is this a positive or negative radius,
    Orientation=sign(Radius_Height);
    
    %Ignore the sign now
    Radius_Height=abs(Radius_Height);
    
    Chord=max(x_org); %How wide is the chord?
    
    OrgX=Chord/2; %The X origin is on the midline
    
    
    %% Iterate through each dot position and transform it
    
    y_new=zeros(length(y_org),1); %Preset var size
    x_new=zeros(length(x_org),1);
    for XYCounter=1:length(y_org)
        
        %Set the positions for this trial
        iX=x_org(XYCounter);
        iY=y_org(XYCounter);
        
        %You need to work out the origin of the circle in order to get this to
        %work. To do this you use a fixed location with a chord: min(x) and
        %iY is the left side of the chord.
        
        %Given that the equation of an elipse is: 
        % (x-OrgX/Rad_X)^2  + (y-OrgY/Rad_y)^2 = 1
        % We know X, Y (above); we are varying Rad_X and Rad_Y
        % parametrically and we know OrgX = Chord/2. Hence we can rearrange
        % to solve for X
        
        %First, put Y on one side as best you can
        %Rad_Y^2 * (1-((X-OrgX)^2/Rad_X^2) = Y^2- 2*Y*OrgY + OrgY^2
        %0 = OrgY^2 - 2*Y*OrgY + Y^2 - Rad_Y^2 * (1-((X-OrgX)^2/Rad_X^2)
        
        %Since 1=(1-((X-OrgX)^2/Rad_X^2))
        %0 = OrgY^2 - 2*Y*OrgY + Y^2 - Rad_Y^2 
        
        %Roots in turn can solve this
        
        A_Coefficient= 1;
        B_Coefficient= -2 * iY;
        C_Coefficient= iY^2 - Radius_Height^2; 
        
        Temp=roots([A_Coefficient, B_Coefficient, C_Coefficient]);
        OrgY=min(Temp); %The Y origin is the one below zero
        
        %To solve for Y you now invert it and swap OrgY in for iY
        
        A_Coefficient= 1;
        B_Coefficient= -2 * OrgY;
        C_Coefficient= OrgY^2 - Radius_Height^2 * (1-((iX-OrgX)^2/Radius_Width^2));
        
        Temp=roots([A_Coefficient, B_Coefficient, C_Coefficient]);
        y_new(XYCounter)=max(Temp); %Y is the positive value
        
        %Flip the y values
        if Orientation==-1
            Difference=iY-max(Temp);
            y_new(XYCounter)=Difference+iY;
        end
        
        x_new(XYCounter)= iX;
        
    end
    
end



