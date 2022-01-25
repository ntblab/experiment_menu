%% Visual paired comparison task.
% Show two stimuli bilaterally on the display and record eye movements
% during this presentation time.
%
% The inputs for the Conditons variable are two stimulus paths (can be
% images or movies) and a timing variable to define how long stimuli are
% present for. Also takes in whether eye tracking is occurring
%
% This is not sourced by the Menu script, meaning that it is
% only run via other scripts. This could be changed with a few additions
%
% First edit: C Ellis 1/12/16 2/14/16 C Ellis added extensive edits to
% include recording for fMRI

function Data = Utils_VPC(Window, Conditions)

%Which stimu are you presenting?
LeftStim=Conditions.Stimuli.L_Stim;
RightStim=Conditions.Stimuli.R_Stim;

%What is the fliptime here?
flipTime = Screen('GetFlipInterval',Window.onScreen);
KbQueueFlush(Window.KeyboardNum); %Flush Key presses

%Define the left and right rect

Separation=Conditions.Stimuli.Disparity*Window.ppd; %What is the separation between the two videos
StimSize=Conditions.Parameters.ImageSize; %How large should the Stim be
LeftRect=[Window.centerX-StimSize-(Separation/2), Window.centerY-(StimSize/2), Window.centerX-(Separation/2), Window.centerY+(StimSize/2)];
RightRect=[Window.centerX+(Separation/2), Window.centerY-(StimSize/2), Window.centerX+(Separation/2)+StimSize, Window.centerY+(StimSize/2)];

%Decide if you are playing a video or showing an image

ImageTypes={'jpg', 'peg', 'png', 'bmp'}; %What are the names of accepted image types. If more than 3 letters only print the last 3
isImage=0; %Default to zero
for Counter=1:length(ImageTypes)
    if ~isempty(strcmpi(ImageTypes{Counter}, LeftStim(end-2:end)))
        isImage=1;
        
    end
end

isEyetracking=Window.isEyeTracking; %Is eye tracking being used?

Data.Quit = 0;

if isfield(Conditions.Parameters, 'Responses')
    correct_response=Conditions.Stimuli.correct_response;
    Data.correct_response=Conditions.Stimuli.correct_response;
    Data.RT = 0;
    Data.response=0;
end

%% Onset the images

ImageOns=GetSecs+flipTime;

Screen(Window.onScreen,'FillRect',Window.bcolor);

%Present stimulus
Data.Timing.TR=[];
if isImage==1
    
    % Read in images
    for image_counter = 1:2
        
        % Consider either the left or right image
        if image_counter==1
            image=LeftStim;
        else
            image=RightStim;
        end
        
        
        % Load in the image
        [raw_Im, ~, Alphachannel]=imread(image);
        
        % If the image ought to be grey scale then interpret that here
        if isfield(Conditions.Parameters, 'greyscale') && Conditions.Parameters.greyscale == 1
            Im{image_counter}=rgb2gray(raw_Im);
        else
            
            % Store image as a cell
            Im{image_counter} = raw_Im;
            
            % If there is an alpha channel then interpret it
            if ~isempty(Alphachannel)
                Im{image_counter}(:,:,4)=Alphachannel;
            end
        end
    end 
    
    %Make the textures
    LeftImageTex=Screen('MakeTexture', Window.onScreen, Im{1}(:,:,:));
    RightImageTex=Screen('MakeTexture', Window.onScreen, Im{2}(:,:,:));
    
    %Present textures
    
    Screen('DrawTexture', Window.onScreen, LeftImageTex, [], LeftRect); %Draw the image in the specified rect
    Screen('DrawTexture', Window.onScreen, RightImageTex, [], RightRect); %Draw the image in the specified rect
    
    % Do you want a response?
    if isfield(Conditions.Parameters, 'Responses') && Conditions.Parameters.ShowResponses==1
        Screen('TextSize',Window.onScreen, 24);
        DrawFormattedText(Window.onScreen, Conditions.Parameters.Responses{1}, Window.centerX-(StimSize/2)-(Separation/2), Window.centerY+(StimSize/2)+50, uint8([255,255,255]));% The left response
        DrawFormattedText(Window.onScreen, Conditions.Parameters.Responses{2}, Window.centerX+(StimSize/2)+(Separation/2), Window.centerY+(StimSize/2)+50, uint8([255,255,255]));% The right response
    end
    
    
    %When did these appear
    ImageOns_actual = Screen('Flip',Window.onScreen);
    
    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOns_Time:_%0.3f', ImageOns_actual));
        
    %% Offset the images
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    
    ImageOffs=ImageOns_actual+Conditions.Parameters.Timing; %The offset should be at the time specified.
    
    %Wait for a key press or the time to lapse
    Response=0;
    while (GetSecs< ImageOffs-flipTime) && Response==0 && Data.Quit==0
        [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
        
        %If they have pressed something then confirm this response
        if keyIsDown && sum(keyCode_onset>0)==1
            
            keyCode=keyCode_onset>0;
            % Process their respo se
            if strcmp(KbName(keyCode),'q')
                Data.Quit=1;
            elseif isfield(Conditions.Parameters, 'Responses')
                if strcmp(KbName(keyCode), Conditions.Parameters.Responses{1}) || strcmp(KbName(keyCode), Conditions.Parameters.Responses{2})
                    
                    % If they pressed an appropriate key store it here
                    % What type of response did they make?
                    if strcmp(KbName(keyCode), Conditions.Parameters.Responses{1})
                        Data.response=1;
                    else
                        Data.response=2;
                    end
                    
                    % Store the reaction time
                    Data.RT=keyCode_onset(keyCode)-ImageOns_actual;
                    
                    % Store the response
                    if correct_response==Data.response
                        fprintf('\nCorrect response');
                    else
                        fprintf('\nIncorrect response');
                    end
                    
                    % End the response interval
                    Response=1;
                end
            end            
        end
        
        
        TRRecording=Utils_checkTrigger(Window.NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
        
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
            Window.NextTR=Window.TR+max(TRRecording);
        end
        
    end
    
    ImageOffs_actual = Screen('Flip',Window.onScreen);
    
    %Collect the timing information
    
    Data.Timing.ImageOns=[ImageOns, ImageOns_actual];
    Data.Timing.ImageOffs=[ImageOffs, ImageOffs_actual];
    
    
    
else
    
    %Play a movie to both the left and right
    VideoStruct.VideoNames={LeftStim, RightStim};
    VideoStruct.MovieRect= [LeftRect; RightRect];
    
    %Store the video struct information
    VideoStruct.window=Window;
    
    %Set no timing constraints
    TimingStruct.Preload=0;
    TimingStruct.PlannedOnset=0;
    
    %Set the input constraints
    InputStruct.isEyeTracking=isEyetracking; %Is eye tracking being used?
    InputStruct.isAnticipationError=Conditions.Parameters.isAnticipationError; %Will a sound be played if there is a key press?
    InputStruct.isResponseTermination=0; %Responses do not terminate the movie
    
    
    [Data.MovieTiming, ~, Data.GazeData]=Utils_PlayAV(VideoStruct, [], TimingStruct, InputStruct); %Plays the movie
    
end

% Check to see if the key is down, if it is, wait a bit before you display
% a message to take it down (otherwise it appears after every response
keyIsDown = KbCheck(Window.KeyboardNum);
if keyIsDown
    WaitSecs(0.2);
end
keyIsDown  = KbCheck(Window.KeyboardNum);

while keyIsDown
    keyIsDown = KbCheck(Window.KeyboardNum);
    
    % If the key is still down then post a message 
    Screen(Window.onScreen,'FillRect',Window.bcolor);     
    if keyIsDown == 1
        DrawFormattedText(Window.onScreen, 'Release Key to continue', 'center', 'center', uint8([255,255,255]));% Tell the participant to continue
    end
    Screen('Flip',Window.onScreen); 
end


%Store the stimulus information
Data.Stimuli.Left=LeftStim;
Data.Stimuli.Right=RightStim;
