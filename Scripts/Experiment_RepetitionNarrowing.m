%% Run a block of the repetition narrowing experiment.
%
% Looming images are presented. The images change when at the smallest
% size. Different images are presented depending on the conditions fed in.
% At the end of the presentation block a VPC presents a present new versus old stimuli side by side. 
%
% First draft 10/1/15 C Ellis
%
% added fixation stimulus
% 02/14/2019 T Yates

function Data=Experiment_RepetitionNarrowing(varargin)

%Set variables
ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};
    
KbQueueFlush(Window.KeyboardNum); 

%Condition variables

%Extract the appropriate folder name for this analysis
StimulusFolder=[Conditions.Parameters.StimulusDirectory, Conditions.Parameters.StimulusLevelNames{Conditions.Stimuli.StimulusTypeSequence(ChosenBlock)}];

%Extract the sequence of stimuli given the above folder
StimulusSequence=Conditions.Stimuli.StimulusTokenSequence(:,ChosenBlock);

fprintf('\n\nRepetition Narrowing. %s, %0.0f repetitions\n\n', Conditions.Parameters.StimulusLevelNames{Conditions.Stimuli.StimulusTypeSequence(ChosenBlock)}, length(Conditions.Stimuli.StimulusTokenSequence(:,ChosenBlock))/length(unique(Conditions.Stimuli.StimulusTokenSequence(:,ChosenBlock))));

fprintf('\n\n-----------------------Start of Block--------------------------\n\n'); 

%% Set the parameter conditions

%Set stimulus size
InitialImageSize=0; %How wide in visual degrees do you want the image to be before transformation?
EndImageSize=20; %How wide in visual degrees do you want the image to end up?

%Set timing
SmallImageTime=0.25; 
LoomingTime=0.5; %How many seconds for the image to enlarge
LargeImageTime=0.75; 
FixationTime=6; %how many seconds are we using for the attention grabber?
ITITime=[0.25 0.75]; %Only relevant if the stimuli are not looming synchronously

%Set how the looming works
LoomingType='Exponential'; %How do you want looming to work? Can be 'linear', 'exponential' or 'quadratic'
Monotonic=0; %Is it just looming or does it also contract?

% platform-independent responses
KbName('UnifyKeyNames');
flipTime = Screen('GetFlipInterval',Window.onScreen);

%Specify some screen attributes
screenX = Window.screenX;
screenY = Window.screenY;
centerX = Window.centerX;
centerY = Window.centerY;


%If the size is input as 0 then make it a 1 pixel sized image
if InitialImageSize<=0
    InitialImage_ppd=1;
else
    InitialImage_ppd=InitialImageSize*Window.ppd;
end

EndImage_ppd=EndImageSize*Window.ppd/2;

NumofLoomingFrames=round(LoomingTime/flipTime)-1; %Subtract one because you need a spare frame at the end 

%What are the size increases
if strcmp(LoomingType, 'Linear')
    
    %Make linear increments
    SizeIncrements=InitialImage_ppd:((EndImage_ppd-InitialImage_ppd)/NumofLoomingFrames): EndImage_ppd;

elseif strcmp(LoomingType, 'Exponential')
    
    %Find the exponents that are the start and the end
    StartingExp=log(InitialImage_ppd)/log(2);
    EndingExp=log(EndImage_ppd)/log(2);
    
    SizeIncrements=2.^(StartingExp:((EndingExp-StartingExp)/NumofLoomingFrames):EndingExp);
    
elseif strcmp(LoomingType, 'Quadratic')
    
    %Get the necessary features of the sigmoid plot
    Sequence=(0:NumofLoomingFrames)-(NumofLoomingFrames/2); %find the list of values
    Max=EndImage_ppd; %What is the ending value
    Min=InitialImage_ppd; %What is the starting value
    Slope=0.5; %Lower numbers mean steeper. Negative values flip it. This value was choosen so that there is some lead in where no change happens but will vary depending on the looming time
    
    %Make the sigmoid representing the value changes
    SizeIncrements=((Max-Min)./(1+exp(-1*Slope*Sequence))) + Min;
    
    
end

SizeIncrements=SizeIncrements(1:end); %Erase the start point (the end point is likely to be a little short due to rounding)

Reversed_SizeIncrements=fliplr(SizeIncrements); %Flip the sequence of the items

%Translate the timing of the experiment into appropriate amounts for the
%flipTime.

Data.Timing.SmallImageTime=round(SmallImageTime/flipTime)*flipTime;
Data.Timing.LoomingTime=round(LoomingTime/flipTime)*flipTime;
Data.Timing.LargeImageTime=round(LargeImageTime/flipTime)*flipTime;
Data.Timing.FixationTime=round(FixationTime/flipTime)*flipTime; % added for fixation cross
Data.Timing.ITITime=round(ITITime/flipTime)*flipTime;

%Iterate through all the stimuli and pregenerate them, then store the
%textures

for StimulusCounter=1:length(StimulusSequence)
    
    iStimulus=StimulusSequence(StimulusCounter); %What texture to call
    
    FileList = Conditions.Stimuli.Filename.(Conditions.Parameters.StimulusLevelNames{Conditions.Stimuli.StimulusTypeSequence(ChosenBlock)}); % Pull out the filenames
    
    %Get the path for the given file
    iImageName=[StimulusFolder, '/' FileList{iStimulus}];
    
    %Set up the image
    [iImage, ~, Alphachannel]=imread(iImageName);
    if ~isempty(Alphachannel)
        iImage(:,:,4)=Alphachannel;
    end
    
    %If it is gray scale then you need to do this
    if length(size(iImage))==2
        iImage(:,:,2)=iImage(:,:,1);
        iImage(:,:,3)=iImage(:,:,1);
    end
    
    %Determine the appropriate size of the images
    ScalingFactor(StimulusCounter)=size(iImage,1)/size(iImage,2); %How much bigger is the Y than the x of the image?
    
    ImageTex(StimulusCounter)=Screen('MakeTexture', Window.onScreen, iImage);
end

%% Wait for the scanner

% If the scanner is running it will wait 1 TR to begin, if it is not
% running but could be then it will hang until a burn has completed. If
% there is no scanner connected then 

[Data.Timing.TR, Quit]=Setup_WaitingForScanner(Window);

% Start the eye tracker
Utils_EyeTracker_TrialStart(Window.EyeTracking);
Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));

%Calculate when is the next TR expected
if ~isempty(Data.Timing.TR)
    NextTR=Data.Timing.TR(end)+Window.TR;
else
    NextTR=Window.NextTR;
end

%% Begin experiments

%When does the test begin
Data.Timing.TestStart=GetSecs;
StimulusCounter=1;
while StimulusCounter <= length(StimulusSequence) && Quit==0
    
    % get trial info
    
    ITI = Data.Timing.ITITime(1)+(rand()*(Data.Timing.ITITime(2)-Data.Timing.ITITime(1))); %Select a random number from this interval
    
    InitialRect= [centerX-InitialImage_ppd,centerY-(InitialImage_ppd*ScalingFactor(StimulusCounter)),centerX+InitialImage_ppd,centerY+(InitialImage_ppd*ScalingFactor(StimulusCounter))];
    EndRect = [centerX-EndImage_ppd,centerY-(EndImage_ppd*ScalingFactor(StimulusCounter)),centerX+EndImage_ppd,centerY+(EndImage_ppd*ScalingFactor(StimulusCounter))];

    % Present the initial image
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    Screen('DrawTexture', Window.onScreen, ImageTex(StimulusCounter), [], InitialRect); %Draw the image in the specified rect
    
    InitialImageOns_actual = Screen('Flip',Window.onScreen);
    
    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOns_of_Trial_%d_Time:_%0.3f', StimulusCounter, InitialImageOns_actual));        
   
    %Wait until the stimulus is ready to loom
    
    Screen('DrawTexture', Window.onScreen, ImageTex(StimulusCounter), [], InitialRect); %Draw the image in the specified rect
    
    while InitialImageOns_actual+Data.Timing.SmallImageTime-flipTime>GetSecs
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
        
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
            NextTR=max(TRRecording)+Window.TR;
        end
        
    end
    LoomingOns_actual = Screen('Flip',Window.onScreen); 
    
    Counter=1;
    while GetSecs<LoomingOns_actual+Data.Timing.LoomingTime -(flipTime)
        
        LoomingRect=[centerX-SizeIncrements(Counter),centerY-(SizeIncrements(Counter)*ScalingFactor(StimulusCounter)),centerX+SizeIncrements(Counter),centerY+ (SizeIncrements(Counter) * ScalingFactor(StimulusCounter))];
        
        %Clear screen
        
        Screen('DrawTexture', Window.onScreen, ImageTex(StimulusCounter), [], LoomingRect); %Draw the image in the specified rect
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
         
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
            NextTR=max(TRRecording)+Window.TR;
        end
        
        LoomingOffs_actual=Screen('Flip',Window.onScreen); %Don't bother storing it
        
        Counter=Counter+1;
    end
    
    LoomingFlips=Counter-1; %How many flips were performed for the looming section. If it is not constant then you have an issue
    
    % Present the stable image
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    Screen('DrawTexture', Window.onScreen, ImageTex(StimulusCounter), [], EndRect); %Draw the image in the specified rect
    LargeImageOns_actual = Screen('Flip',Window.onScreen);
    
    %If it is appropriate then go down the scale
    if Monotonic==0
        
        Screen('DrawTexture', Window.onScreen, ImageTex(StimulusCounter), [], EndRect); %Draw the image in the specified rect
         
        while GetSecs<LargeImageOns_actual+Data.Timing.LargeImageTime-flipTime && Quit==0
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            %If they have pressed q then quit
            if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
                Quit=1;
            end
            
            %Check for trigger
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
            end
            
        end
        
        ShrinkingOns_actual = Screen('Flip',Window.onScreen);
        
        Counter=1;
        while GetSecs<ShrinkingOns_actual+Data.Timing.LoomingTime-flipTime %Even though there is ITI you need this time
            
            LoomingRect=[centerX-Reversed_SizeIncrements(Counter),centerY-(Reversed_SizeIncrements(Counter)*ScalingFactor(StimulusCounter)),centerX+Reversed_SizeIncrements(Counter), centerY+ (Reversed_SizeIncrements(Counter) * ScalingFactor(StimulusCounter))];
            
            %Clear screen
            Screen('DrawTexture', Window.onScreen, ImageTex(StimulusCounter), [], LoomingRect); %Draw the image in the specified rect
            
            %Check for trigger
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
            end
            
            ShrinkingOffs_actual=Screen('Flip',Window.onScreen); %By saving it you will only keep the last one
            Counter=Counter+1;
        end
        
        ShrinkingFlips=Counter-1; %How many flips were performed for the looming section. If it is not constant then you have an issue
        
        %Don't clear the screen if it is non-monotonic
        
    else
        
        %Wait until the image has been present long enough and then start the ITI
        Screen(Window.onScreen,'FillRect',Window.bcolor);
        ITIOns_actual = Screen('Flip',Window.onScreen);
    end
    
    if Quit==0
        
        % save stuff
        Data.Timing.SmallImageOns(StimulusCounter,:)=InitialImageOns_actual;
        Data.Timing.LoomingOns(StimulusCounter,:)=LoomingOns_actual;
        Data.Timing.LoomingFlips(StimulusCounter)=LoomingFlips;
        Data.Timing.LoomingOffs(StimulusCounter,:)=LoomingOffs_actual;
        Data.Timing.LargeImageOns(StimulusCounter,:)=LargeImageOns_actual;
        
        if Monotonic==0
            Data.Timing.ShrinkingOns(StimulusCounter,:)=ShrinkingOns_actual;
            Data.Timing.ShrinkingFlips(StimulusCounter)=ShrinkingFlips;
            Data.Timing.ShrinkingOffs(StimulusCounter,:)=ShrinkingOffs_actual;
        else
            Data.Timing.ITIOns(StimulusCounter,:)=ITIOns_actual;
        end
        
        %Store what stimuli were presented
        Data.Stimuli.Index(StimulusCounter,:)=StimulusSequence(StimulusCounter);
        Data.Stimuli.Name{StimulusCounter}=FileList{StimulusSequence(StimulusCounter)};
        
        %Output the trial information
        fprintf('\n Trial: %d; Stimulus %d\n%s\n', StimulusCounter, StimulusSequence(StimulusCounter), FileList{StimulusSequence(StimulusCounter)});
        
    end
    
    %Clear up the screens so that you don't store the irrelevant textures.
    
    Screen('Close', ImageTex(StimulusCounter))
    
    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOffs_of_Trial_%d_Time:_%0.3f', StimulusCounter, GetSecs));

    %Initiate ITI if monotonic
    if Monotonic==1
        
        %Wait for a certain amount of time after the onset 
        while (ITIOns_actual+ITI)>GetSecs
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
            end
        end
        
    end
    
    StimulusCounter=StimulusCounter+1;
end

Utils_EyeTracker_TrialEnd(Window.EyeTracking); %trial end (for stimuli)



%% Fixation before the VPC
      
%Display the fixation stimulus which will rotate on every flip and expand
%on every flip

FixationOns = Screen('Flip',Window.onScreen); %flip the screen
Fixation_OscillationPeriod=0.70; %What is the period of a rotation
FramesPerOscillation=round(Fixation_OscillationPeriod/flipTime); %how many frames per oscillation?
Fixation_ScalingRange= [.025, .075]; %how big will it get?
FrameCounter=0; %preset

angleStart = 0; %starting angle for bigger star
angleStart_small = 0; %starting angle for smaller, inner star 
anglePerFrame = 360 * flipTime / 3; %speed of change

Data.Timing.FixationStart=GetSecs; %save timing of the fixation stimulus

% Send the message
Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOns_Fixation_Time:_%0.3f', GetSecs));
        
Utils_EyeTracker_TrialStart(Window.EyeTracking);

while FixationOns+Data.Timing.FixationTime>GetSecs && Quit ==0 
   
    Screen(Window.onScreen,'FillRect',Window.bcolor);
   
    %Outer star%
    %oscillation radius
    Radius=round(sin((FrameCounter/FramesPerOscillation)*(2*pi))*(range(Fixation_ScalingRange*5*Window.ppd/4))+mean(Fixation_ScalingRange*5*Window.ppd/2));
    FixationRadOuter=Window.ppd/2; %How many fixual degrees does the image take up
    FixationRadInner=Window.ppd/4; %what is the size of the inner circle defining the inner points
    FixationColor=uint8([253,231,76]); %yellow 
    
    %points
    outerPointsX = centerX + Radius*FixationRadOuter*cosd(angleStart:72:1800); %outer points of star x-coords
    outerPointsX = outerPointsX(1:5); %only want the first 5 points -> this lets the star keep rotating for the entire duration 
    outerPointsY = centerY + Radius*FixationRadOuter*sind(angleStart:72:1800); %outer points of star y-coords
    outerPointsY = outerPointsY(1:5);
    innerPointsX = centerX + Radius*FixationRadInner*cosd((angleStart+36):72:1800); %inner points of star x-coords
    innerPointsX = innerPointsX(1:5);
    innerPointsY = centerY + Radius*FixationRadInner*sind((angleStart+36):72:1800); %inner points of star y-coords
    innerPointsY = innerPointsY(1:5);
    tempPos = vertcat(Interleave(outerPointsX,innerPointsX),Interleave(outerPointsY,innerPointsY));
    VertexPos = transpose(tempPos);
    
    %Inner star%
     %oscillation radius
    Radius_small=round(sin((FrameCounter/FramesPerOscillation)*(2*pi))*(range(Fixation_ScalingRange*3*Window.ppd/4))+mean(Fixation_ScalingRange*3*Window.ppd/2));
    FixationRadOuter_small=Window.ppd/2; %How many fixual degrees does the image take up
    FixationRadInner_small=Window.ppd/4; %what is the size of the inner circle defining the inner points
    FixationColor_small=uint8([91,192,235]); %blue
    
    %small points
    outerPointsX_small = centerX + Radius_small*FixationRadOuter_small*cosd(angleStart_small:72:1800); %outer points of star x-coords
    outerPointsX_small = outerPointsX_small(1:5);
    outerPointsY_small = centerY + Radius_small*FixationRadOuter_small*sind(angleStart_small:72:1800); %outer points of star y-coords
    outerPointsY_small = outerPointsY_small(1:5);
    innerPointsX_small = centerX + Radius_small*FixationRadInner_small*cosd((angleStart_small+36):72:1800); %inner points of star x-coords
    innerPointsX_small = innerPointsX_small(1:5);
    innerPointsY_small = centerY + Radius_small*FixationRadInner_small*sind((angleStart_small+36):72:1800); %inner points of star y-coords
    innerPointsY_small = innerPointsY_small(1:5);
    tempPos_small=vertcat(Interleave(outerPointsX_small,innerPointsX_small),Interleave(outerPointsY_small,innerPointsY_small));
    VertexPos_small=transpose(tempPos_small);


    Screen('FillPoly', Window.onScreen, FixationColor, VertexPos) %big yellow outer star
    Screen('FillPoly', Window.onScreen, FixationColor_small, VertexPos_small) %small blue inner star  
        
    TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
    
    %If there is a recording then update the next TR time and store
    %this pulse
    if any(TRRecording>0)
        Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
        NextTR=max(TRRecording)+Window.TR;
    end
    
    %If they have pressed q then quit
    [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
    if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
        Quit=1;
        break;
    end
    
    Screen('Flip',Window.onScreen); %flip the screen
    
    % Increment all things
    angleStart = angleStart + anglePerFrame; %rotate the big one clockwise
    angleStart_small = angleStart_small - anglePerFrame; %rotate the small one counter-clockwise
    FrameCounter=FrameCounter+1; %increment the oscillatino
    
end

Screen(Window.onScreen,'FillRect',Window.bcolor);

Data.Timing.FixationEnd=GetSecs; %save fixation timing
Utils_EyeTracker_TrialEnd(Window.EyeTracking); %end the eye tracking
Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOffs_Fixation_Time:_%0.3f', GetSecs));


%% Run the VPC if appropriate
if Conditions.Parameters.VPC_Trials>0 && Quit ==0 %Are you running any trials?
    
    VPC_Conditions.Parameters.Timing = Conditions.Parameters.VPC_Timing; %How long is viewing time?

    VPC_Conditions.Parameters.ImageSize=EndImage_ppd * 2; %How big are the images   
    
    %Iterate through the appropriate number of VPC trials
    
    for VPCTrialCounter=1:Conditions.Parameters.VPC_Trials
        
        %What are the test stimuli indexes on this trial? (New image is the
        %second element)
        TestStimuli=Conditions.Stimuli.TestTokens(:,ChosenBlock);
        
        %Which side of the screen should the new stimulus be on (1 or 2?)
        NewIdx=Conditions.Stimuli.New_Position(VPCTrialCounter,ChosenBlock);
        
        %Whare the test stimuli here
        VPC_Conditions.Stimuli.Disparity=Conditions.Stimuli.Disparity;
        VPC_Conditions.Stimuli.L_Stim=[StimulusFolder, '/' FileList{TestStimuli(3-NewIdx)}];
        VPC_Conditions.Stimuli.R_Stim=[StimulusFolder, '/' FileList{TestStimuli(NewIdx)}];
        
        %What stim are being displayed
        PositionNames={'Left', 'Right'};
        fprintf('\n\nDisplaying %d and %d\n\n%s is new\n', TestStimuli(3-NewIdx), TestStimuli(NewIdx), PositionNames{NewIdx});
        
        % Send the message
        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOns_of_VPC_%d_Time:_%0.3f', VPCTrialCounter, InitialImageOns_actual));
        
        % show the VPC 
        Utils_EyeTracker_TrialStart(Window.EyeTracking);
        Data.VPC(VPCTrialCounter) = Utils_VPC(Window, VPC_Conditions);
        
        %did you quit
        [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
        if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
            Quit=1;
        end
        
        Utils_EyeTracker_TrialEnd(Window.EyeTracking);
        
        % Add the TRs, if there are any, to the list from VPC
        if isfield(Data.VPC(VPCTrialCounter).Timing, 'TR')
            TRRecording=Data.VPC(VPCTrialCounter).Timing.TR;
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
        end
        
        % Send the message
        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOffs_of_VPC_%d_Time:_%0.3f', VPCTrialCounter, GetSecs));
        
        %Wait between VPC trials if there are multiple
        
        if Conditions.Parameters.VPC_Trials>1
            Temp=Screen('Flip',Window.onScreen);
            
            %Wait for a certain amount of time after the onset
            while (Temp+Conditions.Parameters.VPC_ITI)>GetSecs
                
                TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
                
                %If there is a recording then update the next TR time and store
                %this pulse
                if any(TRRecording>0)
                    Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                    NextTR=max(TRRecording)+Window.TR;
                end
                
            end
            
        end
        
    end

end

%Issue an error message
if Quit==1
    fprintf('\nBlock Terminated on Stimulus %d\n\n', StimulusCounter-1);
end


%Record whether this was quit preemptively
Data.Quit=Quit;

Data.Timing.TestEnd=GetSecs;

%Record the time at which the next experiment can start

Data.Timing.DecayLapse=Data.Timing.TestEnd+Conditions.Parameters.DecayTime;

%% pack up, go home...

Screen(Window.onScreen,'FillRect',Window.bcolor);
Screen('Flip',Window.onScreen);

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Block_Time:_%0.3f', GetSecs));

fprintf('\n\n -----------------------End of Block-------------------------- \n\n'); 
end

