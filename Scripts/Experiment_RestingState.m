%% Run a block of the resting state data.
%
% Use to collect resting state data. 
% Display a black screen while listening for TRs and q's
% Count the elapsed time in the experiment
%
% 7/28/16 C Ellis
% Add fixation stimulus if wanted 1/26/2022

function Data=Experiment_RestingState(varargin)

%Set variables
%ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};
    

fprintf('\n\nResting state.\n\n');

fprintf('\n\n-----------------------Start of Block--------------------------\n\n'); 

KbQueueFlush(Window.KeyboardNum);
Utils_EyeTracker_TrialStart(Window.EyeTracking);
Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));
    
%% Wait for the scanner

% If the scanner is running it will wait 1 TR to begin, if it is not
% running but could be then it will hang until a burn has completed. If
% there is no scanner connected then 
[Data.Timing.TR, Quit]=Setup_WaitingForScanner(Window);

%Calculate when is the next TR expected
if ~isempty(Data.Timing.TR)
    NextTR=Data.Timing.TR(end)+Window.TR;
else
    NextTR=Window.NextTR;
end

if Quit==0
    
    % did you want to have the fixation cross or no? 
    if Conditions.Parameters.fixation==0
        
        %Make the screen black
        Screen(Window.onScreen,'FillRect',0);
        Data.Timing.TestStart=Screen('Flip',Window.onScreen);
    else
        
        %Specify some screen attributes
        centerX = Window.centerX;
        centerY = Window.centerY;
        
        % fixation parameters 
        % (identical to Passive and Instrumental Conditioning tasks) 
        Fixation_Size = 2*Window.ppd;
        Fixation_Color = [255,255,255];
        Fixation_Rect_Center = [centerX-(Fixation_Size/2),centerY-(Fixation_Size/2),centerX+(Fixation_Size/2),centerY+(Fixation_Size/2)];
        
        % set up the texture
        Template_Image=ones(ceil(Fixation_Size), ceil(Fixation_Size),3)* Window.bcolor; %Make a small square to put the triangle on
        Fixation_Image=insertShape(Template_Image, 'Line', [0,ceil(Fixation_Size/2),Fixation_Size,ceil(Fixation_Size/2); ceil(Fixation_Size/2),0, ceil(Fixation_Size/2),Fixation_Size], 'Opacity', 1, 'Color', Fixation_Color, 'LineWidth',15);
        Fixation_Tex=Screen('MakeTexture', Window.onScreen, Fixation_Image);
        
        % show the texture 
        Screen(Window.onScreen,'FillRect',Window.bcolor);
        Screen('DrawTexture', Window.onScreen, Fixation_Tex, [], Fixation_Rect_Center,[],[],1);
        Data.Timing.TestStart=Screen('Flip',Window.onScreen);
    end
    
end

%Keep collecting TRs until you quit
NextPrint=1;
fprintf('Elapsed Time:     ');
Data.KeyPresses = {};
Data.KeyTimestamps = {};
Duration=0;
while Quit==0
    
    [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
    
    % Capture key presses, not just q
    if (keyIsDown) && sum(keyCode_onset>0)==1 
        %If they have pressed q then quit
        if strcmp(KbName(keyCode_onset>0), 'q')
            Quit=1;
        else
            
            % Store the key presses that are logged
            Data.KeyPresses{end + 1} = KbName(keyCode_onset>0);
            Data.KeyTimestamps{end + 1} = keyCode_onset(keyCode_onset>0);
            
        end
        
    end
    
    %Check for trigger
    
    TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
    
    %If there is a recording then update the next TR time and store
    %this pulse
    if any(TRRecording>0)
        Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
        NextTR=max(TRRecording)+Window.TR;
    end
    
    Duration=GetSecs - Data.Timing.TestStart;
    
    if Duration-round(Duration)>0.05 && NextPrint==1
        
        NumberofCharacters=length(num2str(round(Duration)));
        ZeroPlaceHolder=repmat('0',4-NumberofCharacters,1);

        fprintf('\b\b\b\b');
        
        fprintf('%s%d', ZeroPlaceHolder, round(Duration));
        NextPrint=0;
    elseif Duration-round(Duration)<0.05
        NextPrint=1;
    end
    
end

%How long was the experiment
Data.Timing.Duration=Duration;
    
%Make the screen return background color
Screen(Window.onScreen,'FillRect',Window.bcolor);
Data.Timing.TestEnd=Screen('Flip',Window.onScreen);


%Issue an error message
if Quit==1
    fprintf('\n\nTerminated after %0.2f seconds\n\n', round(Duration));
end


%Record whether this was quit preemptively
Data.Quit=Quit;

%No decay period
Data.Timing.DecayLapse=Data.Timing.TestEnd;

%% pack up, go home...

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Block_Time:_%0.3f', GetSecs));
Utils_EyeTracker_TrialEnd(Window.EyeTracking);

fprintf('\n\n -----------------------End of Block-------------------------- \n\n'); 
end

