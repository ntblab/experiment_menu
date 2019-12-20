%% Run a block of a Posner cuing experiment
%
% Present a looming fixation stimulus that is supposed to grab their
% attention. Press space bar to advance. A cue then appears, either a
% peripheral triangle or a face with moving eyes. The target then appears:
% a spinning multi colored wheel.
%
% Can use images for cuing, such as those from Hood et al., 1998, stored in
% the Stimuli/Cuing_Stimuli/ folder.
%
%First draft 10/1/15 C Ellis
%Added sound 08/07/17 C Ellis

function Data=Experiment_PosnerCuing(varargin)

%Set variables
ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};
    
KbQueueFlush(Window.KeyboardNum);

fprintf('Posner Cuing. %s\n\n', Conditions.Parameters.BlockNames{ChosenBlock});

fprintf('\n\n-----------------------Start of Block--------------------------\n\n');

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));

%% Set the parameters

isScramble=1; %Do you want to scramble the fixation wheel on every block?
CueType=ChosenBlock; %Is the cue a peripheral triangle (1) or a set of turned eyes (2)
DrawingCue=0; %Is this a cartoon or photo realistic endogenuous cue?
sound_cue=0; % Do you want a sound to play during the fixation?

%Set timing
FixationTime=inf; %Present the fixation cross for this time or until fixation
PostFixationTime=0.2; %How many seconds after fixation before the cue appears
% Cue information is pulled from the Generatetrials
TargetTime=2; %Present the Target for this time or until fixation
ITITime=[0.25 0.75];

%Stimulus  conditions
Fixation_Size=5*Window.ppd; %How many fixual degrees does the image take up
Fixation_OscillationPeriod=1; %What is the period of a rotation
Fixation_ScalingRange= [.5, 1.5]; %What proportion of the image is the min and max?
Fixation_Shape='Square'; %Do you want the fixation stimulus to be a square or a circle

Target_Size=round(10*Window.ppd); %How big is the target?

%If it is is an even number then change it just slightly so that the stim
%doesn't wobble.
if mod(Target_Size,2)==0
    Target_Size=Target_Size+1;
end

Target_Eccentricity=Conditions.Parameters.StimEccentricity*Window.ppd; %What is the target eccentricity
Target_RotationPeriod=1; %What is the period of a rotation

if CueType==1 %Different depending on cue type
    Cue_Size=3*Window.ppd; %How many visual degrees does the cue take up (on a certain axis, depending on the shape)
    Cue_Shape='Triangle'; %What shape should the peripheral cue be?
    Cue_Color=uint8([0,255,0]); %What color will the cue be?
    
    Cue_Eccentricity=Target_Size; %What is the cue eccentricity
    Cue_Height=Cue_Size/2;
    
else
    %Give the parameters for either the drawn eyes or the face
    if DrawingCue==0
        
        Cue_Size=5*Window.ppd; %How many visual degrees does the cue take up (on a certain axis, depending on the shape)
        
        Cue_Eccentricity=Cue_Size;
        Cue_Height=Cue_Size/4;
        Cue_SaccadeSpeed=1;
    else
        
        Cue_Size=10*Window.ppd; %How many visual degrees does the cue take up (on a certain axis, depending on the shape)
    end
end

flipTime = Window.frameTime;

%Specify some screen attributes
screenX = Window.screenX;
screenY = Window.screenY;
centerX = Window.centerX;
centerY = Window.centerY;

%Specify the rects of the elements in the experiment
Cue_Rect_Left = [centerX-Cue_Eccentricity-(Cue_Size/2),centerY-Cue_Height,centerX-Cue_Eccentricity+(Cue_Size/2),centerY+Cue_Height];
Cue_Rect_Right= [centerX+Cue_Eccentricity-(Cue_Size/2),centerY-Cue_Height,centerX+Cue_Eccentricity+(Cue_Size/2),centerY+Cue_Height];

Target_Rect_Left =  [centerX-Target_Eccentricity-(Target_Size/2),centerY-(Target_Size/2),centerX-Target_Eccentricity+(Target_Size/2),centerY+(Target_Size/2)];
Target_Rect_Right = [centerX+Target_Eccentricity-(Target_Size/2),centerY-(Target_Size/2),centerX+Target_Eccentricity+(Target_Size/2),centerY+(Target_Size/2)];

FramesPerOscillation=round(Fixation_OscillationPeriod/flipTime); %How many frames fit into an oscillation

%% Generate the cue stimuli
if CueType==1 %If it is eyes then it is better to do this with PTB calls
    
    % Generate a leftward cue (then flip it for rightward trials)
    
    if strcmp(Cue_Shape, 'Triangle')
        
        Template_Image=ones(ceil(Cue_Size), ceil(Cue_Size),3)* Window.bcolor; %Make a small square to put the triangle on
        
        %Specify the xy positions of all the points in the triangle
        Ydisplacement=sqrt(((Cue_Size^2)-((Cue_Size/2)^2)))/2;
        VertixPos=[round(Cue_Size/2)-(Cue_Size/2), round(Cue_Size/2)+Ydisplacement,... %XY of bottom left corner
            round(Cue_Size/2)+(Cue_Size/2), round(Cue_Size/2)+Ydisplacement,... %XY of bottom right corner
            round(Cue_Size/2), round(Cue_Size/2)-Ydisplacement]; %XY of middle top corner
        
        Cue_Image=insertShape(Template_Image, 'FilledPolygon', VertixPos, 'Opacity', 1, 'Color', Cue_Color);
        
    end
    
    
end
% Make the sound for the cue
if sound_cue==1
    % Set parameters
    fs=4000;
    
    % Make the attack
    t = 1:((Fixation_OscillationPeriod*4000)/2);
    T = linspace(24, 12, length(t)); % Pitch changes.
    attractor_attack = sin(2.*pi.*t./T);
    
    % Make the decay
    t = 1:((Fixation_OscillationPeriod*4000)/2);
    T = linspace(9, 16, length(t)); % Pitch changes.
    attractor_decay = sin(2.*pi.*t./T);
    
end


%% Determine the trial sequence

%Pull out the stimulus sequence
StimulusSequence=Conditions.Stimuli.StimulusSequence(:,:,ChosenBlock);

%Generate a random trial order
Sequence=Shuffle(1:length(StimulusSequence));

%What is the cue, target and ISI sequence?
CueSequence=StimulusSequence(Sequence,1);
TargetSequence=StimulusSequence(Sequence,2);
CueTimeSequence=StimulusSequence(Sequence,3);
CueTargetSequence=StimulusSequence(Sequence,4);

Data.StimulusSequence=StimulusSequence(Sequence,:); %Store it overall, redundant but good

isEyeTracking=Window.isEyeTracking;

%% Determine the stimulus timing

%Translate the timing of the experiment into appropriate amounts for the
%flipTime.

Data.Timing.FixationTime=round(FixationTime/flipTime)*flipTime;
Data.Timing.PostFixationTime=round(PostFixationTime/flipTime)*flipTime;
%Don't have a fixed time for cue target ISI
Data.Timing.TargetTime=round(TargetTime/flipTime)*flipTime;
Data.Timing.ITITime=round(ITITime/flipTime)*flipTime;

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

%Make empty files to be wrote into if you are doing fMRI
if Window.isfMRI==1
    for StimulusCounter=1:length(StimulusSequence)
        Data.Timing.TR_Trialwise.(sprintf('Trial_%d', StimulusCounter))=[];
    end
end

FlushEvents; %Clear the Kb

%When does the test begin
Data.Timing.TestStart=GetSecs;
StimulusCounter=1;
while StimulusCounter <= length(StimulusSequence) && Quit==0
    Utils_EyeTracker_TrialStart(Window.EyeTracking);
    
    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Trial_%d_Time:_%0.3f', StimulusCounter, GetSecs));
    
    %Generate the image (either a new one on every trial or an old one).
    if isScramble==1 || StimulusCounter==1
        
        Target_Image=Utils_Cross_Color(Target_Size, isScramble, Window.bcolor);
        
    end
    
    % get trial info
    
    Cue_Location=CueSequence(StimulusCounter); %Where will the cue appear (1 means left, 2 means right)
    Target_Location=TargetSequence(StimulusCounter); %Where will the target appear (1 means left, 2 means right)
    isValid=Target_Location==Cue_Location; %Is this a valid trial/
    CueTime=round(CueTimeSequence(StimulusCounter)/flipTime)*flipTime; %Cue target ISI timing
    CueTargetTime=round(CueTargetSequence(StimulusCounter)/flipTime)*flipTime; %Cue target ISI timing
    
    
    %% Generate the fixation stimulus
    
    ColorList=[91,192,235;... %Blue
        253,231,76;... %Yellow
        250,53,226;... %Purple
        155,197,61;... %Green
        229,89,52];    %Orange
    
    %Select one of the above colors at random for the inner and outer
    %shapes
    
    OuterColorIdx=randi([1, size(ColorList,1)]); %What color is being called?
    InnerColorIdx=randi([1, size(ColorList,1)]);
    
    Fixation_OuterColor=uint8(ColorList(OuterColorIdx, :));
    
    Fixation_InnerColor=uint8(ColorList(InnerColorIdx, :));
    
    Template_Image=ones(ceil(Fixation_Size), ceil(Fixation_Size),3)* Window.bcolor; %Make a small square to put the fixation on
    
    if strcmp(Fixation_Shape, 'Circle')
        
        %Create the outside circle
        Fixation_Image=insertShape(Template_Image, 'FilledCircle', [round(Fixation_Size/2), round(Fixation_Size/2), round(Fixation_Size/2)], 'Opacity', 1, 'Color', Fixation_OuterColor);
        
        %Insert the middle circle
        Fixation_Image=insertShape(Fixation_Image, 'FilledCircle', [round(Fixation_Size/2), round(Fixation_Size/2), round(Fixation_Size/3)], 'Opacity', 1, 'Color', uint8([255, 255, 255]));
        
        %Insert the inner circle
        Fixation_Image=insertShape(Fixation_Image, 'FilledCircle', [round(Fixation_Size/2), round(Fixation_Size/2), round(Fixation_Size/4.5)], 'Opacity', 1, 'Color', Fixation_InnerColor);
        
        
    elseif strcmp(Fixation_Shape, 'Square')
        
        %Create the outside square
        Fixation_Image=insertShape(Template_Image, 'FilledRectangle', [0, 0, Fixation_Size, Fixation_Size], 'Opacity', 1, 'Color', Fixation_OuterColor);
        
        %Insert the middle square
        Fixation_Image=insertShape(Fixation_Image, 'FilledRectangle', [round(Fixation_Size*3/16), round(Fixation_Size*3/16), round(Fixation_Size*5/8), round(Fixation_Size*5/8)], 'Opacity', 1, 'Color', uint8([255, 255, 255]));
        
        %Insert the inner square
        Fixation_Image=insertShape(Fixation_Image, 'FilledRectangle', [round(Fixation_Size*3/8), round(Fixation_Size*3/8), round(Fixation_Size/4), round(Fixation_Size/4)], 'Opacity', 1, 'Color', Fixation_InnerColor);
        
        
    end
    
    %% Set up the textures for this trial
    
    Fixation_Tex=Screen('MakeTexture', Window.onScreen, Fixation_Image);
    if CueType==1
        Cue_Tex=Screen('MakeTexture', Window.onScreen, Cue_Image);
    else
        
        %Are you drawing the stimuli or using face stimuli
        if DrawingCue==1
            
            %Reset this every trial because you are going to change this
            Pupil_Rect_Left = [centerX-Cue_Eccentricity-(Cue_Size/8),centerY-(Cue_Size/8),centerX-Cue_Eccentricity+(Cue_Size/8),centerY+(Cue_Size/8)];
            Pupil_Rect_Right = [centerX+Cue_Eccentricity-(Cue_Size/8),centerY-(Cue_Size/8),centerX+Cue_Eccentricity+(Cue_Size/8),centerY+(Cue_Size/8)];
            
            PupilRects=[Pupil_Rect_Left; Pupil_Rect_Right];
            
        else
            
            
            %Initialize with the face being presented
            [Initial_Image, ~, Alpha]=imread('../Stimuli/Cuing_Stimuli/Open.png');
            Initial_Image(:,:,4)=Alpha; %Add the alpha channel
            
            %Which direction is the model looking towards
            if Cue_Location==1
                [Cue_Image, ~, Alpha]=imread('../Stimuli/Cuing_Stimuli/Left.png');
            elseif Cue_Location==2
                [Cue_Image, ~, Alpha]=imread('../Stimuli/Cuing_Stimuli/Right.png');
            elseif Cue_Location==0
                [Cue_Image, ~, Alpha]=imread('../Stimuli/Cuing_Stimuli/Closed.png');
            end
            Cue_Image(:,:,4)=Alpha; %Add the alpha channel
            
            %Make the textures
            Initial_Tex=Screen('MakeTexture', Window.onScreen, Initial_Image);
            Cue_Tex=Screen('MakeTexture', Window.onScreen, Cue_Image);
            
            %What are the dimensions of the face?
            
            ScalingFactor=size(Initial_Image,1)/size(Initial_Image,2);
            FaceRect=[centerX-(Cue_Size),centerY-(Cue_Size)*ScalingFactor,centerX+(Cue_Size),centerY+(Cue_Size)*ScalingFactor];
            
        end
        
    end
    Target_Tex=Screen('MakeTexture', Window.onScreen, Target_Image);
    
    % Loop the fixation, changing its size rhythmically
    
    Fixation_Response=0; %Has there been a trigger response for the eye fixation or a button press.
    Target_Response=0; %Has there been a trigger response for the eye fixation or a button press.
    
    %Preset all these variables, work as flags for knowing the stimulus
    %sequence
    
    Framecounter=0;
    WhyAreWeWaiting=0; %Are you waiting for a fixation (0), a TR (1), or the post TR period to lapse (2)
    CueOns=inf; %When will the flip come to start the cue
    CueOns_actual=0; %Set to zero, will be overwritten when the time comes
    trialstart_actual=inf;
    
    CueTargetOns_actual=0;
    TargetOns_actual=0; %Set to zero, will be overwritten when the time comes
    Angle=0; %What angle is the target presented at
    TargetDuration=inf; %How long was the target present?
    
    NextFrame=GetSecs+flipTime; %When is the next frame planned for
    
    %% Present fixation, wait for saccade
    
    while CueOns-flipTime>GetSecs
        
        %% Stimulus display
        %Display all the stimuli for the experiment
        
        %Display the fixation stimulus
        %Calculate the radius by using a sign wave of a given period
        %(oscillationperiod, standardized to radians) with an amplitude
        %corresponding to the size range
        
        Radius=round(sin((Framecounter/FramesPerOscillation)*(2*pi))*(range(Fixation_ScalingRange*Fixation_Size/4))+mean(Fixation_ScalingRange*Fixation_Size/2));
        
        Fixation_Rect= [centerX-Radius, centerY-Radius, centerX+Radius, centerY+Radius];
        
        %Draw the base fixation stimulus
        
        Screen(Window.onScreen,'FillRect',Window.bcolor);
        Screen('DrawTexture', Window.onScreen, Fixation_Tex, [], Fixation_Rect); %Draw the image in the specified rect
        
        % Play sound if it is the start of an oscillation
        if sound_cue==1 
            if mod(Framecounter, FramesPerOscillation)==0 && Framecounter>0
                sound(attractor_decay, fs)
            elseif mod(Framecounter, FramesPerOscillation)==round(FramesPerOscillation/2)
                sound(attractor_attack, fs)
            end
        end
        
        %% Response
        
        %Still wait until the NextFrame
        
        while (GetSecs< NextFrame-(flipTime/2))
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            %If they have pressed something then confirm this response
            if (keyIsDown) && sum(keyCode_onset>0) == 1
                FixationDuration = keyCode_onset(keyCode_onset>0)-trialstart_actual;
                Fixation_Response=1;
                
                %If the keypress was a q then quit
                if sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
                    Quit=1;
                end
            end
            
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR_Trialwise.(sprintf('Trial_%d', StimulusCounter))(end+1:end+length(TRRecording))=TRRecording;
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording; %Add to the TR pot
                NextTR=max(TRRecording)+Window.TR;
            end
            
            
        end
        
        
        
        %% What to do next
        
        %If this is the first successful trigger of this trial
        if Fixation_Response==1 && WhyAreWeWaiting==0
            
            %Wait for the TR before continuing
            if Window.isfMRI==1
                
                %Store the last TR that was recorded.
                if ~isempty(Data.Timing.TR)
                    LastTR=Data.Timing.TR(end);
                else %If no TRs have been recorded then assume that assume that nothing has been started yet. 
                    LastTR=Window.TR;
                end
                
            end
            
            %You are now waiting for a TR
            WhyAreWeWaiting=1;
            
            %When does the fixation period start
            FixationOns_actual = Screen('Flip',Window.onScreen);
            
            NextFrame=FixationOns_actual+flipTime;
            
        else
            %Do a normal flip
            Temp=Screen('Flip',Window.onScreen);
            
            if trialstart_actual==inf
                trialstart_actual=Temp;
            end
            
            
            NextFrame=Temp+flipTime; %When is the next frame planned for
            
        end
        
        % Has a TR been polled so you can move on?
        if Window.isfMRI==1 && WhyAreWeWaiting==1
            if ~isempty(Data.Timing.TR_Trialwise.(sprintf('Trial_%d', StimulusCounter))) && Data.Timing.TR_Trialwise.(sprintf('Trial_%d', StimulusCounter))(end)>LastTR
                WhyAreWeWaiting=2;
            end
            
            %Incase the scanner is turned off midway you need to be able to
            %get control back
            if (GetSecs-NextTR)>(Window.TR*3)
                WhyAreWeWaiting=2;
            end
            
            
        elseif WhyAreWeWaiting==1
            WhyAreWeWaiting=2;
        end
        
        %If there has been a TR since the fixation response began then time
        %lock the events to this.
        if WhyAreWeWaiting==2
            
            if Window.isfMRI==1 && ~isempty(Data.Timing.TR_Trialwise.(sprintf('Trial_%d', StimulusCounter)))
                LatestTime=Data.Timing.TR_Trialwise.(sprintf('Trial_%d', StimulusCounter))(end);
            else
                LatestTime=FixationOns_actual;
            end
                
            %Set up timing
            CueOns = LatestTime+Data.Timing.PostFixationTime;
            CueTargetOns=CueOns+CueTime; %When does the cue end and the target start
            TargetOns= CueTargetOns + CueTargetTime;
            TrialMax= TargetOns +Data.Timing.TargetTime;
            ITI = Data.Timing.ITITime(1)+(rand()*(Data.Timing.ITITime(2)-Data.Timing.ITITime(1))); %Select a random number from this interval
            
            %So that it is finished
            WhyAreWeWaiting=3;
        end
        
        
        %Increment
        Framecounter=Framecounter+1;
        
    end
    
    
    %% Display the cue
    
    %Wait until the target is ready
    while TargetOns-flipTime > GetSecs
        
        %% Decide what type of cue to present, exogenous or endogenous
        if CueType==1
            
            % Keep showing the fixation stimulus diromh tje cie pmset
            Radius=round(sin((Framecounter/FramesPerOscillation)*(2*pi))*(range(Fixation_ScalingRange*Fixation_Size/4))+mean(Fixation_ScalingRange*Fixation_Size/2));
            
            Fixation_Rect= [centerX-Radius, centerY-Radius, centerX+Radius, centerY+Radius];
            
            %Draw the base fixation stimulus
            
            Screen(Window.onScreen,'FillRect',Window.bcolor);
            Screen('DrawTexture', Window.onScreen, Fixation_Tex, [], Fixation_Rect); %Draw the image in the specified rect
            
            % Play sound if it is the start of an oscillation
            if sound_cue==1
                if mod(Framecounter, FramesPerOscillation)==0 && Framecounter>0
                    sound(attractor_decay, fs)
                elseif mod(Framecounter, FramesPerOscillation)==round(FramesPerOscillation/2)
                    sound(attractor_attack, fs)
                end
            end
            
            %Has the CueTarget interval began?
            if CueTargetOns_actual==0
                if Cue_Location==1
                    Screen('DrawTexture', Window.onScreen, Cue_Tex, [], Cue_Rect_Left); %Draw the image in the specified rect
                elseif Cue_Location==2
                    Screen('DrawTexture', Window.onScreen, Cue_Tex, [], Cue_Rect_Right); %Draw the image in the specified rect
                elseif Cue_Location==0
                    Screen('DrawTexture', Window.onScreen, Cue_Tex, [], Cue_Rect_Left); %Draw two cues
                    Screen('DrawTexture', Window.onScreen, Cue_Tex, [], Cue_Rect_Right);
                end
            end
            
            
        else
            
            
            
            if DrawingCue==1 %Create an oval with the specified dimensions
                
                EyeRects=[Cue_Rect_Left; Cue_Rect_Right];
                
                
                %The rects are organized with both the left and the right
                %frame rects supplied
                Screen('FillOval', Window.onScreen, uint8([255,255,255]), EyeRects'); %Show a white oval
                Screen('FrameOval', Window.onScreen, uint8([0,0,0]), EyeRects', 5); %Show a black frame
                
                %Move the eyes if the time is appropriate
                if CueTargetOns<GetSecs
                    
                    %Are the pupils moving to the left or the right?
                    if Cue_Location==1
                        
                        %Displace the pupil rects by a small amount
                        Temp=PupilRects(:,[1,3])-Cue_SaccadeSpeed;
                        
                        %If the saccade has gone too far then stop it
                        if PupilRects(1,1)<(EyeRects(1,1)+(Cue_Size/16))
                            Temp=PupilRects(:,[1,3]);
                        end
                        
                        %Update pupil rects if appropriate
                        PupilRects(:,[1,3])=Temp;
                    elseif Cue_Location==2
                        
                        %Displace the pupil rects by a small amount
                        Temp=PupilRects(:,[1,3])+Cue_SaccadeSpeed;
                        
                        %If the saccade has gone too far then stop it
                        if PupilRects(1,3)>(EyeRects(1,3)-(Cue_Size/16))
                            Temp=PupilRects(:,[1,3]);
                        end
                        
                        %Update pupil rects if appropriate
                        PupilRects(:,[1,3])=Temp;
                        
                    end
                end
                
                Screen('FillOval', Window.onScreen, uint8([0,0,0]), PupilRects'); %Show a black circle
                
            else %Present a face
                
                %Move the eyes if the time is appropriate
                if CueTargetOns<GetSecs
                    
                    Screen('DrawTexture', Window.onScreen, Cue_Tex, [], FaceRect);
                    
                else %If it is not time yet then draw the initial face
                    
                    Screen('DrawTexture', Window.onScreen, Initial_Tex, [], FaceRect)
                    
                end
                
            end
            
        end
        
        %Listen for Triggers and flip
        
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
        
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            Data.Timing.TR_Trialwise.(sprintf('Trial_%d', StimulusCounter))(end+1:end+length(TRRecording))=TRRecording;
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording; %Add to the TR pot
            NextTR=max(TRRecording)+Window.TR;
        end
       
        %Do a normal flip
        Temp=Screen('Flip',Window.onScreen);
        
        %If the cue has appeared but the actual cue onset time hasn't
        %been updated then update the time
        if CueOns_actual==0
            CueOns_actual=Temp;
            
            Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Cue_Start_Time:_%0.3f', CueOns_actual));
        end
        
        %Has the cue target time begun
        if CueTargetOns_actual==0 && CueTargetOns<GetSecs
            CueTargetOns_actual=Temp;
        end
        
        %Increment
        Framecounter=Framecounter+1;
        
    end
    
    %Set to start immediately
    NextFrame=Temp;
    
    %% Target onset
    
    while Target_Response==0 && GetSecs<TrialMax
        
        %% Display stimulus
        
        Angle=Angle+(360/(Target_RotationPeriod/flipTime)); %Increase the angle by what
        Angle(Angle>360)=Angle-360; %Make sure it is below 360 degrees
        
        % Display the stimuli
        
        Screen(Window.onScreen,'FillRect',Window.bcolor);
        
        if Target_Location==1
            Screen('DrawTexture', Window.onScreen, Target_Tex, [], Target_Rect_Left, Angle); %Draw the image in the specified rect
        elseif Target_Location==2
            Screen('DrawTexture', Window.onScreen, Target_Tex, [], Target_Rect_Right, Angle); %Draw the image in the specified rect
        end
        
        %% Response
        
        
        %If you aren't eye tracking then when there is any key press
        %you should terminate.
        KbQueueFlush(Window.KeyboardNum);
        while (GetSecs< NextFrame) && Target_Response==0
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            %If they have pressed q then confirm this response and quit
            if keyIsDown && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
                TargetDuration = keyCode_onset(keyCode_onset>0)-TargetOns_actual;
                Target_Response=1;
                
                Quit=1;
                
            end
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR_Trialwise.(sprintf('Trial_%d', StimulusCounter))(end+1:end+length(TRRecording))=TRRecording;
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording; %Add to the TR pot
                NextTR=max(TRRecording)+Window.TR;
            end
        end
        
        
        
        
        %Present the display. In theory you can get nonsensical values if
        %the response comes before the first flip but this is unlikely
        
        Temp=Screen('Flip',Window.onScreen);
        
        %If this is the first flip then save this time
        if TargetOns_actual==0
            TargetOns_actual=Temp;
            
            Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Target_Start_Time:_%0.3f', TargetOns_actual));

        end
        
        NextFrame=Temp+flipTime;
    end
    
    %Issue message
    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Trial_end_Time:_%0.3f', GetSecs));
    
    % Remove stimuli
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    ITIOns_actual=Screen('Flip',Window.onScreen);
    
    %% Record data before the next trial
    
    if Quit==0
        Data.Response.FixationDuration(StimulusCounter)=FixationDuration;
        Data.Response.TargetDuration(StimulusCounter)=TargetDuration;
        Data.Response.isValid(StimulusCounter)=isValid;
        Data.Response.Cue_Location(StimulusCounter)=Cue_Location;
        Data.Response.Target_Location(StimulusCounter)=Target_Location;
        Data.Response.CueTargetTime(StimulusCounter)=CueTargetTime;
        Data.Response.ColorIdxs(StimulusCounter,:)=[OuterColorIdx, InnerColorIdx];
        
        % the giblets
        Data.Timing.trialstart(StimulusCounter,:)=trialstart_actual;
        Data.Timing.PostFixationOns(StimulusCounter,:)=FixationOns_actual;
        Data.Timing.CueOns(StimulusCounter,:)=[CueOns, CueOns_actual];
        Data.Timing.CueTargetOns(StimulusCounter,:)=[CueTargetOns, CueTargetOns_actual];
        Data.Timing.TargetOns(StimulusCounter,:)=[TargetOns, TargetOns_actual];
        Data.Timing.ITIOns(StimulusCounter,:)=[ITI, ITIOns_actual];
        
        
        fprintf('\nTrial %d\n Cue location %d\n Target location %d\n Reaction Time %0.3f\n', StimulusCounter, Cue_Location, Target_Location, TargetDuration);
    end
    
    %Clear up the screens so that you don't store textures.
    
    Screen('Close')
    
    
    %Initiate ITI
    while (ITIOns_actual+ITI)>GetSecs
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
        
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            Data.Timing.TR_Trialwise.(sprintf('Trial_%d', StimulusCounter))(end+1:end+length(TRRecording))=TRRecording;
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording; %Add to the TR pot
            NextTR=max(TRRecording)+Window.TR;
        end
    end
    
    % End the trial
    Utils_EyeTracker_TrialEnd(Window.EyeTracking);
    
    %Increment counter
    StimulusCounter=StimulusCounter+1;
    
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

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Block_Time:_%0.3f', GetSecs));

fprintf('\n\n-----------------------End of Block--------------------------\n\n');


%% pack up, go home...

Screen(Window.onScreen,'FillRect',Window.bcolor);
Screen('Flip',Window.onScreen);


end

