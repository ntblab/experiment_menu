%% Show an image of a specific size in order to help with calibration 
%
% Specify the size of an image
%
%First draft 6/25/18 C Ellis

function Data=Experiment_ImDisplay_Pilot(varargin)

%Set variables
ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};
    
KbQueueFlush(Window.KeyboardNum);

fprintf('\n\nImage size.\n\n');

fprintf('\n\n-----------------------Start of Block--------------------------\n\n'); 

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));
    
%% Set the parameter conditions

%Set the parameters for the checkerboard
BlockSize = Window.ppd; % How many pixels in size is the image
fix_rad = 10; % How big is the fixation dot
vis_angle = 10;

BlocksAcross= ceil((Window.Rect(3) + BlockSize)/(BlockSize*2));
BlocksHigh= ceil((Window.Rect(4) + BlockSize)/(BlockSize*2));

%Generate the checkerboard
Temp=checkerboard(round(BlockSize), BlocksHigh, BlocksAcross);
Image=[];
Image(:,:,1)=Temp; Image(:,:,2)=Temp; Image(:,:,3)=Temp; %Make a 3d mat

Image=uint8(Image*255);

Quit=0;
Screen('TextSize',Window.onScreen, 24);
while Quit == 0
    
    % How big is the image
    Rect_size = vis_angle * Window.ppd;  % What is the size of the fixation stimulus

    %Generate a texture
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    ImageTex = Screen('MakeTexture', Window.onScreen, Image);
    
    %Draw the texture
    Screen('DrawTexture', Window.onScreen, ImageTex, [Window.centerX-(Rect_size/2), Window.centerY-(Rect_size/2), Window.centerX+(Rect_size/2), Window.centerY+(Rect_size/2)]);
    Screen('FillOval', Window.onScreen, uint8([255, 0, 0]), [Window.centerX-fix_rad, Window.centerY-fix_rad, Window.centerX+fix_rad, Window.centerY+fix_rad]);
    DrawFormattedText(Window.onScreen, sprintf('Visual angle: %0.2f', vis_angle));
    
    %Flip the display
    Screen('Flip',Window.onScreen);
    
    % Did they press a key?
    [~, keyCode] = KbWait(Window.KeyboardNum);
    
    %If they have pressed q then quit
    if strcmp(KbName(keyCode>0), 'q')
        Quit=1;
        % Increase the visual angle
    elseif strcmp(KbName(keyCode>0), 'UpArrow')
        vis_angle = vis_angle + 1;
        % Decrease the visual angle
    elseif strcmp(KbName(keyCode>0), 'DownArrow')
        vis_angle = vis_angle - 1;
    end
    
    % Bottom out this number
    if vis_angle < 1
        vis_angle = 1;
    end
    
end

%Record whether this was quit preemptively
Screen('TextSize',Window.onScreen, 12);
Data.Quit=Quit;
Data.Timing.TestEnd=GetSecs;
Data.Timing.TR = [];

%Record the time at which the next experiment can start
Data.Timing.DecayLapse=Data.Timing.TestEnd+Conditions.Parameters.DecayTime;

%% pack up, go home...

Screen(Window.onScreen,'FillRect',Window.bcolor);
Screen('Flip',Window.onScreen);

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Block_Time:_%0.3f', GetSecs));

fprintf('\n\n -----------------------End of Block-------------------------- \n\n'); 
end

