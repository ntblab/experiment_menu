%Generate a distorted checkerboard.

%CheckerBoardSize = how many pixels wide is a single check in a
%checkerboard

%YCurveCoef = What is the coef that acts on the curve? This number will
%approximate the pixel displacement of the curve minima from the horizontal

%Dual = Is the light source from below?

%Function = if it is parabola then you use a parabola to fit the curve, if
%it is circle then you use a circle to fit a curve

function GenerateGridforProjectionTest(CheckerBoardSize, YCurveCoef, Dual, Function)

if nargin==2
    Function='Parabola';
end

OriginalImage=checkerboard(CheckerBoardSize);

%How much bigger is the background than the checkerboard?
ScaleFactor=1.5;

Border=length(OriginalImage)*(ScaleFactor-1)/2; %How much space should be on either side of the checkerboard?

%Create a larger grid on which to put your original

Background=rand(length(OriginalImage)*ScaleFactor);

NewImage=Background;
%Iterate through the rows
for YCounter=1:size(OriginalImage,1)
    
    
        %What is the amount of Y to be added
        if Dual==0 %Do you care about the absolute distance or the relative
            YContribution=YCurveCoef;
        else
            YContribution=YCurveCoef*((YCounter-size(OriginalImage,1)/2)/(size(OriginalImage,1)/2));
        end
    
    if strcmp(Function, 'Parabola')
        
        %What is the exponent on the quadratic equation at this point?
        Exponent=YContribution/((size(OriginalImage,2)-1)/2)^2;
        
        
    elseif strcmp(Function, 'Circle')
        
        %The trig is hard for this. Basically the following equation can be
        %deduced:
        
        Chord=size(OriginalImage,2)-1; %How wide is the chord
        arcHeight=YContribution; %How far is the arc above the horizontal
        
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

        
    end
    
    for XCounter=1:size(OriginalImage,2)
        
        
        if strcmp(Function, 'Parabola')
            
            %Create the equation based on the quadratic equation
            Position=Exponent*((XCounter-size(OriginalImage,2)) * (XCounter-1));
            
        elseif strcmp(Function, 'Circle')
            
            %Rearrange the equation to find the angle corresponding to a
            %given x position

            Angle=acos((XCounter - cx)/Radius);
            
            Position = cy + (Radius * sin(Angle));
            
        end
        
        %This will happen at the top of the arc
        if isnan(Position)
            Position=0;
        end
        
        NewYCounter= round(YCounter + Position);
        
        %Substitute  the new position value with the previous value
        NewImage(Border+NewYCounter, Border+XCounter)=OriginalImage(YCounter,XCounter);
    end
end

figure
imshow(NewImage)

