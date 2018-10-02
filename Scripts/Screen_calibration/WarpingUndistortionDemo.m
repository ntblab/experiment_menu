%% Create a warping demo to correct for the distortion caused in the bore
%
% First a calibration file is created based on one of the calibration
% methods and used as a baseline. This is fed into the settings of
% Psychtoolbox and a checkerboard with this undistortion is created. The
% user can then press buttons to change these settings.
%
% Regions that will not be useable by PTB are displayed in white. The new
% dimensions of the rectangle will be outputted 
% 
% Starting parameter values
% Radius_Height is the pixel displacement of the minima from the top (positive) or bottom (negative) of the display. -210 is appropriate for circular
% Radius_Width is the elipse width
% What is the image width (but actually the arc length)  (used to create the real image aspect ratio)
% What is the image height (used to create the real image aspect ratio)
% What is the keystone ratio? High numbers mean wider bottoms
% What is the bore radius, needed for the visual angle
%
% When you are finished, the scanner operator should press 'q'. This will
% save a file with the calib files parameters. It is recommended that you
% change this name to something more appropriate.
%
% Created by C Ellis, 10/8/15
% Added the ellipse 12/12/15
% Updated, 6/12/18

function DisplayRect = WarpingUndistortionDemo(Radius_Height, Radius_Width, Screen_width, Screen_height, keystone_val, Viewing_dist, Circle_Rad, UnstretchingFactor, translation)

if nargin==0
    Radius_Height=-3000; %-1950;%; %This is the pixel displacement of the minima from the top (positive) or bottom (negative) of the display. -210 is appropriate for circular
    Radius_Width= 1500;%1500; %How wide is the elipse
    Screen_width=42; % What is the width of the screen (actually the arc length on a curved surface)
    Screen_height=50;  % What is the height of the projected image (not just where the screen is but
    keystone_val=0.9;  % What is the keystoning value
    Viewing_dist=20; % What is the viewing distance
    Circle_Rad= 30; % What is the bore radius
    UnstretchingFactor = 0.75; % What is the shrinking needed to make these stimuli perceptually square
    translation=[0, 0]; % How much do you need to shift (X and Y) the stimuli to put them in the center? Negative means left or up
    
    %Skyra bore arc length = 500, image height = 424, Circle_Rad=35
    %Mock bore arc length = 590, image height = 315
    %Prisma A, Radius_Height = -2937.5, Radius_Weight = 1512.5, Screen_width = 42, Screen_height = 49, Keystone_val=0.9, Viewing_dist=20, Circle_Rad=30, UnstretchingFactor=0.75, translation=[0, -100];
end

TestImageType='Checkerboard'; % What image will you choose to display. An alternative is 'Image'

%Is it an elliptical distortion (which is likely) or a circular distortion
%(which is weird)?
isCircleDistortion=0;

% What is the ratio of height to width, to give you 
%UnstretchingFactor=Screen_width/Screen_height;

% What is the size of the fixation
fix_rad = 10;

%How much are you changing the ellipse by each step
Radius_HeightIncrement=50;
Radius_WidthIncrement=50;

%Response keys
IncreaseHeightPress={'1', 'UpArrow'}; %Change the Radius_height value
DecreaseHeightPress={'2', 'DownArrow'};
IncreaseWidthPress={'3', 'RightArrow'}; %Change the Radius_Width value
DecreaseWidthPress={'4', 'LeftArrow'};
SatisfiedKeyPress='q';
StepSizeIncreasePress='d'; % Double the step size
StepSizeDecreasePress='h'; % Halve the step size

screens=Screen('Screens'); % how many screens attached to this computer?

window.screenid=max(screens); %What screen are you projecting the monitor to

%Decide what base calibration file to use (depends on the screen
%resolution)
if window.screenid==0
    Rect=get(0, 'ScreenSize');
else
    % Open the rect to get the size and then close it,
    [~,Rect]=Screen('OpenWindow',window.screenid);
    sca;
    
end

% What is the aspect ratio
aspect_ratio = Rect(3)/Rect(4);

CalibFileName=sprintf('Calibration_%d_%d.mat', Rect(3), Rect(4));

%If the file does not exist then make it, otherwise continue
if exist(CalibFileName)~=2
    
    % %Run the calibration demo
    DisplayUndistortionBVL(CalibFileName, window.screenid);
    
    %The output of this is a calibration file which is structured in a certain
    %way. scal is a structure with a number of different fields:
    %
    %             screenNumber: What screen are you choosing to display on
    %               stereoMode: Is this dual screen presentation
    %                windowPtr: What screen window
    %                     rect: What are the dimensions of the display (often called incorrectly)
    %                  NxdotsG: During the calibration how many dots are there in the X dimension
    %                  NydotsG: During the calibration how many dots are there in the y dimension
    %               XCALIBDOTS: ?
    %               YCALIBDOTS: ?
    %           XCALIBDOTS_ORG: ?
    %           YCALIBDOTS_ORG: ?
    %                  XVALUES: What arbitrary positions are assigned to the dots in the x dimension
    %                  YVALUES: What arbitrary positions are assigned to the dots in the y dimension
    %                    xStep: How far apart are the dots in x dim pixels?
    %                    yStep: How far apart are the dots in x dim pixels?
    %                    nDots: How many dots in total (width dots by height dots)
    %                      xcm: What is the spatial position of x dots
    %                      ycm: What is the spatial position of y dots
    %               FITDOTLIST: List all the dots?
    %         SELECTXCALIBDOTS: THIS IS WHERE THE X DOTS ARE CHANGED IN POSITION
    %         SELECTYCALIBDOTS: THIS IS WHERE THE Y DOTS ARE CHANGED IN POSITION
    %     SELECTXCALIBDOTS_ORG: This is the original position of the X dots
    %     SELECTYCALIBDOTS_ORG: This is the original position of the Y dots
    %               NOrderPoly: ?
    %               isDONTSTOP: ?
    %           FITDOTLIST_ORG: ?
    %                 xFitCoef: ?
    %                 yFitCoef: ?
    
    %Just in general the positions of the dots reads vertically from top to
    %bottom.
    
end

%Load Calibration file and then alter it according to a given
%transformation rule. Specifically take in x and y positions and then
%output x and y positions after a given curve has been applied

load(CalibFileName);

SatisfiedResponse=0;
while SatisfiedResponse==0
    
    %If this is a circle distortion then these things are equal
    if isCircleDistortion==1
        Radius_Width=Radius_Height;
    end
    
    %Run the position converter by taking the original and the the converted
    %points
    if Radius_Width ~= 0 && Radius_Height ~= 0
        [scal.SELECTXCALIBDOTS, scal.SELECTYCALIBDOTS]=xyConverter_ellipse(scal.SELECTXCALIBDOTS_ORG, scal.SELECTYCALIBDOTS_ORG, Radius_Height, Radius_Width);
    end
    
    %Given the set of points that you have, unstretch/compress them by a
    %certain amount. Specifically, what is the ratio of the projected
    %aspect ratio to the real aspect ratio.
    [scal.SELECTXCALIBDOTS, scal.SELECTYCALIBDOTS]=xyConverter_Unstretching(scal.SELECTXCALIBDOTS, scal.SELECTYCALIBDOTS, UnstretchingFactor/aspect_ratio);
    
    %Given the set of points that you have, digitally keystone the image
    [scal.SELECTXCALIBDOTS, scal.SELECTYCALIBDOTS]=xyConverter_Keystone(scal.SELECTXCALIBDOTS, scal.SELECTYCALIBDOTS, keystone_val);
    
    %Given the set of points that you have, digitally shift the image
    [scal.SELECTXCALIBDOTS, scal.SELECTYCALIBDOTS]=xyConverter_translation(scal.SELECTXCALIBDOTS, scal.SELECTYCALIBDOTS, translation);
    
    %Save the file
    save('TempCalibrationFile', 'scal', 'warptype');
    
    %Set up psychtoolbox to accept the calib file
    PsychImaging('PrepareConfiguration');
    
    %% Add the calibration file
    PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', 'TempCalibrationFile.mat');
    
    %Open the window. Unlike Screen('OpenWindow') this method messes with the
    %resolution of the display in weird ways on retina displays
    [window.onScreen, window.Rect] = PsychImaging('OpenWindow', window.screenid);
    
    %Calculate the region of useable display
    DisplayRect = DisplayRectCalculator(scal, window, Radius_Height);

    % Generate a checkerboard display
    % What Test image
    
    if strcmp(TestImageType, 'Checkerboard')
        
        %Set the parameters for the checkerboard
        BlockSize=50;
        
        % Ensure that there is more blocks than the minimum
        BlocksAcross= ceil((Rect(3) + 1)/(BlockSize*2));
        BlocksHigh= ceil((Rect(4) + 1)/(BlockSize*2));
        
        %Generate the checkerboard
        Temp=checkerboard(BlockSize, BlocksHigh, BlocksAcross); 
        
        Image(:,:,1)=Temp; Image(:,:,2)=Temp; Image(:,:,3)=Temp; %Make a 3d mat
        
        Image=uint8(Image*255);
        
        % Make the border red
        thickness=10;
        border_width= (size(Image, 1) - Rect(4)) / 2; % How much extra checkerboard is there?
        border_height= (size(Image, 2) - Rect(3)) / 2; % How much extra checkerboard is there?
        
        Image(:,border_height:border_height+thickness,[2,3])=0;
        Image(border_width:border_width+thickness,:,[2,3])=0;
        Image(:, size(Image, 2)-thickness-border_height:size(Image, 2)-border_height, [2,3])=0;
        Image(size(Image, 1)-thickness-border_width:size(Image, 1)-border_width, :, [2,3])=0;
        
    elseif strcmp(TestImageType, 'Image')
        Image=imread('TestImage.jpg');
        
    end
    
    %Generate a texture
    ImageTex = Screen('MakeTexture', window.onScreen, Image);
    
    %Draw the texture
    centerX = window.Rect(3)/2;
    centerY = window.Rect(4)/2;
    Screen('DrawTexture', window.onScreen, ImageTex);
    Screen('FillOval', window.onScreen, uint8([255, 0, 0]), [centerX-fix_rad, centerY-fix_rad, centerX+fix_rad, centerY+fix_rad]);
    
    %Flip the display
    Screen('Flip',window.onScreen);
    
    %Wait for a while while these stim are presented then press a button before
    %closing
    WaitSecs(1);
    
    %Report the statis
    fprintf('Radius Height: %d    Radius Width:  %d\n__________\n', Radius_Height, Radius_Width)
    
    %Loop until you have a match
    Continue=0;
    while Continue==0
        [~, char]=KbWait(-1); %Wait for key press
        
        %Interpret the responses
        if any(strcmp(KbName(char), IncreaseHeightPress))
            Radius_Height=Radius_Height+Radius_HeightIncrement; %Increase Radius_height amount
            Continue=1;
            
        elseif any(strcmp(KbName(char), DecreaseHeightPress))
            Radius_Height=Radius_Height-Radius_HeightIncrement; %Decrease Radius_height amount
            Continue=1;
            
        elseif any(strcmp(KbName(char), IncreaseWidthPress))
            Radius_Width=Radius_Width+Radius_WidthIncrement; %Increase Radius_Width amount
            Continue=1;
            
        elseif any(strcmp(KbName(char), DecreaseWidthPress))
            Radius_Width=Radius_Width-Radius_WidthIncrement; %Decrease Radius_Width amount
            Continue=1;
            
        elseif any(strcmp(KbName(char), SatisfiedKeyPress)) %Save the file
            SatisfiedResponse=1;
            save(sprintf('AlteredCalibFile_Rad_H_%d_Rad_W_%d', Radius_Height, Radius_Width), 'scal', 'warptype', 'Screen_width', 'Viewing_dist', 'Circle_Rad');
            Continue=1;
        
        elseif any(strcmp(KbName(char), StepSizeIncreasePress)) % Increase the step size change for the steps
            Radius_WidthIncrement = Radius_WidthIncrement * 2;
            Radius_HeightIncrement = Radius_HeightIncrement * 2;
            
            fprintf('Width step: %0.1f; Height step: %0.1f\n\n', Radius_WidthIncrement, Radius_HeightIncrement);
            WaitSecs(0.25); % Wait a bit to let it not change the values too quickly
            
        elseif any(strcmp(KbName(char), StepSizeDecreasePress)) % Increase the step size change for the steps
            Radius_WidthIncrement = Radius_WidthIncrement / 2;
            Radius_HeightIncrement = Radius_HeightIncrement / 2;
            
            fprintf('Width step: %0.1f; Height step: %0.1f\n\n', Radius_WidthIncrement, Radius_HeightIncrement);
            WaitSecs(0.25); % Wait a bit to let it not change the values too quickly
            
        end
        
    end
    
    % Close the screen
    sca
    
end






