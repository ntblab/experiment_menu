%% What part of the display is usable
%
%Find out the largest rectangle that can be shown completely on the
%display.
%
%Takes in the scal with the appropriate changes made and the window so it
%knows how big it can go.
%

function DisplayRect=DisplayRectCalculator(scal, window, arcHeight)

YPosition=scal.SELECTYCALIBDOTS; %Find all the Y coordinates. If these values are below zero or above the screen res then they will not be included. 

%
if any(YPosition<0)
    Maxima=1;
else
    Maxima=0;
end
    
%If it has a maxima out of bounds (Although its value will be more negative
MaximaIdx=1;
if Maxima==1
    
    %What is the Y coord of the maxima
    [~, sorted_idxs]=sort(YPosition);
    
    %Increment until you get above zero
    while YPosition(sorted_idxs(MaximaIdx))<0
        MaximaIdx=MaximaIdx+1;
    end
    
    %What is the minimum y value to be included in the display
    MinimumY=scal.SELECTYCALIBDOTS_ORG(MaximaIdx);
    
    DisplayRect=[window.Rect(1), MinimumY, window.Rect(3), window.Rect(4)];
    
elseif sign(arcHeight)==1
    
    %What is the Y coord of the maxima
    [~, MinimaIdx]=min(YPosition);
    
    %Increment until you get above zero
    while YPosition(MinimaIdx)>window.Rect(4)
        MinimaIdx=MinimaIdx-1;
    end
    
    %What is the maximum Y value to be included in the display
    MaximumY=scal.SELECTYCALIBDOTS_ORG(MinimaIdx);
    
    DisplayRect=[window.Rect(1), window.Rect(2), window.Rect(3), MaximumY];
    
else %If Zero then just make original rect
    
    DisplayRect=window.Rect;
    
end
