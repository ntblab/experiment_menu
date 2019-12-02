function Window=Setup_Display(Window, Window_str)
%% SETUP_DISPLAY Put up the screen for this experiment
%
% Takes as an input a calibration filename and sets up the screen based on
% this filename. This means the projector distortion is corrected for. If
% filename is an empty string then a normal screen will be created. If one
% monitor is found then you can either show it transparently (thus making
% output to the command window visible) or it can show the whole screen.
%
% To set the screen up, use the WarpingUndistortionDemo.m script in
% Screen_calibration/ to set up the distortion of the display, this can
% deal with stretching, curvature and keystoning
%
% Once the screen has been set up, a variety of parameters will be
% collected, such as the resolution and the rectangle size. The pixels per
% degree are also calculated which is different if the screen is curved or
% not.
%
% Description added: 3/9/16 C Ellis
% Changed script to search the calib directory for scripts with appropriate
% information

Screens=Screen('Screens');
KeyboardNum=Window.KeyboardNum;
calibration_path='Screen_calibration/';

%% Set up the screen with the appropriate parameters (viewing distance, distortions, etc)
%Set up for the specific screen that you have, including setting pixels per
%degree and distortion
% Since more than one screen was found find out whether it needs to be warped or not

% Detect the number of calibration files
Calibration_Files={};
if exist(calibration_path)==7
    temp=dir([calibration_path, '*.mat']);
    for file_counter = 1:length(temp)
        Calibration_Files{end+1}=temp(file_counter).name;
    end
end

% Print the file names
fprintf('%d screens have been detected.\nPress the number corresponding to the desired screen presentation setup:\n', length(Screens));
file_counter=0;
for file_counter=1:length(Calibration_Files)
    fprintf('\t%d. %s\n', file_counter, Calibration_Files{file_counter});
end
fprintf('\t%d. (or ''t'') transparent\n', file_counter+1);
fprintf('\t%d. (or ''p'') Pilot testing\n', file_counter+2);
fprintf('\t%d. (or ''s'') Same screen (with onscreen outputs)\n\n', file_counter+3);

%Wait until there is a valid response
Window.print_screen = 0;  % Default to not print to screen
while 1
    
    %Wait for a valid response or proceed if you have preregistered it
    if isempty(Window_str)
        [~, Response]=KbWait(KeyboardNum); %Wait for a response
        
        Str=KbName(Response); %What was the string entered?
    else
        Str=Window_str;
    end
    
    if ~iscell(Str) %Only take in single key presses
        if str2num(Str(1)) <= length(Calibration_Files)
            Calibration_File=Calibration_Files{str2num(Str(1))};
            load([calibration_path, Calibration_File]);
            break; % Finish waiting for a response
        elseif strcmp(Str(1), 't') || logical(~isempty(str2num(Str(1))) && str2num(Str(1)) == length(Calibration_Files) +2)
            PsychDebugWindowConfiguration(1); %Makes screen transparent
            Screen_width=40;
            Viewing_dist=30;
            break;
            
        elseif strcmp(Str(1), 's') || logical(~isempty(str2num(Str(1))) && str2num(Str(1)) == length(Calibration_Files) +2)
            
            Screen_width=40;
            Viewing_dist=30;
            Window.print_screen = 1;  % Make the text print to screen
            break; % Finish waiting for a response
            
        elseif strcmp(Str(1), 'p') || logical(~isempty(str2num(Str(1))) && str2num(Str(1)) == length(Calibration_Files) +2)
            
            Screen_width=40;
            Viewing_dist=30;
            Window.print_screen = 0;  % Make the text print to screen
            break; % Finish waiting for a response
        end
    end
end


% Store the reported screen properties
Window.Screen_width=Screen_width;
Window.Viewing_dist=Viewing_dist;

if exist('Circle_Rad')
    Window.Circle_Rad=Circle_Rad;
end

%Are you going to undistort the images
if exist('scal')==1
    Undistortion=1;
else
    Undistortion=0;
end

% display requirements (resolution and refresh rate)
Window.requiredRes  = []; % you can set a required resolution if you want, e.g., [1024 768]
Window.requiredRefreshrate = []; % you can set a required Refresh Rate, e.g., [60]

%basic drawing and screen variables
Window.gray        = 50;
Window.black       = 10;
Window.white       = 200;
Window.fontsize    = 32;
Window.bcolor      = Window.gray;

%open main screen, get basic information about the main screen
WhichScreen='max';

% Use this monitor unless otherwise stated
if strcmp(WhichScreen, 'min')
    Window.screenNumber=min(Screens);
else
    Window.screenNumber=max(Screens);
end

% Will this window be made from a subset of the screen  (assumes the display screen is arranged to the right of the experimenter screen)  
subwindow_rect=[];
if exist('make_subwindow')~=0 && make_subwindow==1
    % Get the rects of the monitors
    rects = get(0, 'MonitorPositions');
    
    % Check if there are two rows here
    if size(rects, 1) ~= 2
        fprintf('Second monitor was not detected. Aborting\n')
        return
    end
    
    % Remove 1 to make the bounds right
    rects(:, 1:2) = rects(:, 1:2) - 1;
    
    % Concatenate the lengths of the windows
    rects(2, 3) = rects(2, 3) + rects(1, 3);
    
%     % Add any vertical displacement
%     rects(2, 4) = rects(2, 4) + abs(rects(2, 2));
%     
    % Ignore negative values
    rects(rects<0)=0;
    
    % Set the rect to this
    subwindow_rect = rects(2,:);
    subwindow_rect(2)=subwindow_rect(2) + 1;
    
end

%% Open up the window with the proposed parameters
if Undistortion==1
    %Set up psychtoolbox to accept the calib file
    PsychImaging('PrepareConfiguration');
    
    % Add the calibration file
    PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', [calibration_path, Calibration_File]);
    
    [Window.onScreen, Window.Rect] = PsychImaging('OpenWindow', Window.screenNumber);
    
else
    %If it is empty then assume it is flat and run it as normal
    [Window.onScreen, Window.Rect]=Screen('OpenWindow',Window.screenNumber, 0, subwindow_rect, 32, 2);
    
end

%Set up some screen size values
[Window.screenX, Window.screenY]=Screen('WindowSize', Window.onScreen); % check resolution
Window.screenDiag = sqrt(Window.screenX^2 + Window.screenY^2); % diagonal size
Window.screenRect  =[0 0 Window.screenX Window.screenY]; % screen rect
Window.centerX = Window.screenRect(3)*.5; % center of screen in X direction
Window.centerY = Window.screenRect(4)*.5; % center of screen in Y direction

% set some screen preferences
Screen('BlendFunction', Window.onScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


% get screen rate
[Window.frameTime, ~, ~] =Screen('GetFlipInterval', Window.onScreen);
Window.monitorRefreshRate=1/Window.frameTime;

%% Pixels per degree calculation

if Undistortion==1
    
    %If you assume you're eyes are in the centre of the circle (aka Bore)
    %then calculating the viewing angle is easy; however, this is not the
    %case so you need to account for it.
    
    %What you do is find the visual angle subtended by the screen. You then
    %find the chord of that display (could be empirical). Now the one half
    %of the chord and the origin make a triangle. You can find the angle of
    %this triangle and then find the pixel width per this visual angle
    
    Screen_proportion=Window.Screen_width/(2*pi*Window.Circle_Rad); % What proportion of the bore (all the way around) does the screen take up
    
    DegreesofMajorCircle=360*Screen_proportion; %How many degrees of the bore does the screen occupy
    
    Chord=(sind(DegreesofMajorCircle/2).*Window.Circle_Rad)*2; %What is the chord length between the side edges of the screen
    
    MajorHeightToChord=sqrt(Window.Circle_Rad^2 - (Chord/2)^2);  %What is the distance from the origin of the bore to the chord?
    
    MinorHeightToChord=MajorHeightToChord-(Window.Circle_Rad-Window.Viewing_dist); %What is the distance from the eyes to the chord?
    
    Visual_Angle=atand((Chord/2) / MinorHeightToChord)*2; %What is the visual angle of the display from the viewed point within the circle?
    
    Window.ppd=Window.screenX/Visual_Angle; %Find the Viewing angle of whole screen and then divide the resolution by that
    
    % To solve this using the law of cosines (equivalent) you can do the following:
    %Visual_Angle = 2 * asind((Window.Circle_Rad * sind(DegreesofMajorCircle/2)) / sqrt((Window.Circle_Rad-Window.Viewing_dist)^2 + Window.Circle_Rad^2 - (2 * (Window.Circle_Rad-Window.Viewing_dist) * Window.Circle_Rad * cosd(DegreesofMajorCircle/2))));
    
    %Produce a distorted image based on this calibration. Useful for making a
    %screen saver or for testing
    %
    %     Image='../Stimuli/Sesame.jpg'; % Input
    %     Image_Distorted='../Stimuli/Sesame_Distorted.jpg'; % Output
    %
    %     iImage=imread(Image);
    %     Screen(Window.onScreen,'FillRect',Window.bcolor);
    %     ImageTex=Screen('MakeTexture', Window.onScreen, iImage);
    %     Screen('DrawTexture', Window.onScreen, ImageTex); %Draw the image in the specified rect
    %     LargeImageOns_actual = Screen('Flip',Window.onScreen);
    %     Im=Screen('GetImage', Window.onScreen);
    %     imwrite(Im, Image_Distorted);
    %
    
else
    
    %What are the pixels per degree for a flat surface? 
    %This is found here by making a triangle out of one half of the display
    %and finding the angle subtended by that half. Then finding the pixels
    %in that half
    
    Window.ppd=(Window.screenX/2) / atand((Window.Screen_width/2)/Window.Viewing_dist);
    
end

%Make screen a specified color
Screen(Window.onScreen,'FillRect',Window.bcolor);
Screen('Flip',Window.onScreen);
