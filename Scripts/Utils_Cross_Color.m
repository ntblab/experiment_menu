%% Generate a Cross of multiple colors. 

%Take in a size and a background color so as to generate a stimulus that
%can be rotated. Decide whether to shuffle the order of the colors for the
%cross

function Image=Utils_Cross_Color(Size, isShuffle, Background)

%Just in case
Size=round(Size); 

%Make it a RGB value
if length(Background)==1 
    Background=[Background, Background, Background];
end
    

ArmLength=round(Size/2); %How long is each arm
ArmWidth=round(Size/8); %Specify the width of the arms
InnerCircleRad=round(Size/12); %Specify the size of the circle in the centre
OuterCircleRad=round(Size/6); %Specify the size of the outer center circle

%Specify a list of RGB colors
ColorList=[91,192,235;... %Blue
    253,231,76;... %Yellow
    250,53,226;... %Purple
    155,197,61;... %Green
    229,89,52];    %Orange

%Reorder the list of colors if necessary
if isShuffle==1
    ColorList=ColorList(Shuffle(1:size(ColorList,1)),:);
end

%Default to background of the image
Image=ones(Size, Size, 3); 
Image(:,:,1)=Image(:,:,1).*Background(1); Image(:,:,2)=Image(:,:,2).*Background(2); Image(:,:,3)=Image(:,:,3)*Background(3);

ImageCent=[ceil(Size/2), ceil(Size/2)]; %What are the centre y x coordinates of the image

%Create the four arms. Start at top and go clockwise

for ArmCounter=1:4
    
    iColor=ColorList(ArmCounter,:); %What is the color for this arm?
    
    %Create the arm (vertical) of the specified colors
    iArm=ones(ArmLength, (2*round(ArmWidth/2)+1), 3);
    iArm(:,:,1)=iArm(:,:,1)*iColor(1); iArm(:,:,2)=iArm(:,:,2)*iColor(2); iArm(:,:,3)=iArm(:,:,3)*iColor(3);
    
    %If it is even then make the arm horizontal
    if mod(ArmCounter,2)==0
        
        iArm=rot90(iArm);
    end
    
    %Specify the coordinates of the arms
    if ArmCounter==1
        
        YRange=ImageCent(1)-(ArmLength-1):ImageCent(1);
        XRange=ImageCent(2)-round(ArmWidth/2):ImageCent(2)+round(ArmWidth/2);
        
    elseif ArmCounter==2
        
        YRange=ImageCent(1)-round(ArmWidth/2):ImageCent(1)+round(ArmWidth/2);
        XRange=ImageCent(1):ImageCent(1)+(ArmLength-1);
        
    elseif ArmCounter==3
        
        YRange=ImageCent(1):ImageCent(1)+(ArmLength-1);
        XRange=ImageCent(2)-round(ArmWidth/2):ImageCent(2)+round(ArmWidth/2);
        
    elseif ArmCounter==4
        
        YRange=ImageCent(1)-round(ArmWidth/2):ImageCent(1)+round(ArmWidth/2);
        XRange=ImageCent(1)-(ArmLength-1):ImageCent(1);
    end
    
    
    Image(YRange, XRange,:)=iArm; %Replace the given range by the arm being generated
    
end

%Add big circle

Image=insertShape(Image, 'FilledCircle', [ImageCent(2), ImageCent(1), OuterCircleRad], 'Opacity', 1, 'Color', ColorList(5,:));

%Add small circle

Image=insertShape(Image, 'FilledCircle', [ImageCent(2), ImageCent(1), InnerCircleRad], 'Opacity', 1, 'Color', [255, 255, 255]);


%Convert back to uint8
Image=uint8(Image);


