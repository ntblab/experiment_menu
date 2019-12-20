%% Run a calibration sequence 
%
%Animate the sudden onset of stimuli to attract attention in order to calibration. Different blocks specify
%different stimuli types. For instance the fireworks can be lines
%extending from a centre or they can be dots flashing (and then
%dissolving) or they can be concentric circles. In the case of the latter
%these stimuli will be cycling on the screen until 'space' is pressed .
%Press 'x' to flash the stimulus on the screen
%
%First draft 3/5/16 C Ellis
%Increased brightness, changed the distance (~16/26->20) 9/1/16 C Ellis
%Set up to deal with concentric circle stimuli 10/28/16 C Ellis

function Data=Experiment_EyeTrackerCalib(varargin)

%Set variables
ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};
    
KbQueueFlush(Window.KeyboardNum);

fprintf('\n\nEyeTrackerCalib.\n\n');

fprintf('\n\n-----------------------Start of Block--------------------------\n\n'); 

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));
    
%% Set the parameter conditions

%Set the type of fireworks
FireworkType=Conditions.Parameters.BlockNames{ChosenBlock}; %Fireworks can be lines or dots.

%Set stimulus size

FlareRange=[10, 15]; %What is the range of flares that could be produced
MaxFlareRad=3; %What is the max the flares can grow?
FlareWidth=2; %How many pixels wide are the flares
ColorChangeAmount=10; %How much can the colors increase by
MaxHeadTailLength=1; %How many visual degrees long can they grow
GrowthRate=0.1; %How many visual degrees are the lines growing per flip

%How long does an expansion take
ExpansionTime=(MaxFlareRad + MaxHeadTailLength)/GrowthRate*Window.frameTime;


Sparkle=1; %Do you want to make the colors sparkle

Origins=Conditions.Stimuli.Origins; %What the origins of the fireworks to be generated?


Data.Timing.ITITime=[0.25, 0.5]; %How long between each stim

% platform-independent responses
KbName('UnifyKeyNames');
flipTime = Screen('GetFlipInterval',Window.onScreen);


%Specify some screen attributes
screenX = Window.screenX;
screenY = Window.screenY;
centerX = Window.centerX;
centerY = Window.centerY;

%Convert the above measures to ppd

MaxHeadTailLength=MaxHeadTailLength*Window.ppd;
MaxFlareRad=MaxFlareRad*Window.ppd;
GrowthRate=GrowthRate*Window.ppd;

%Convert Origins into pixel positions (preset to be at origin)

Origins(:,1)=Origins(:,1)*Window.ppd + centerX;
Origins(:,2)=Origins(:,2)*Window.ppd +centerY;

%Shuffle Origins so that they occur in a random order

Origins=Origins(Shuffle(1:size(Origins,1)),:);

%If this is not being run on the scanner then never try record a TR pulse
NextTR=Window.NextTR;

%When does the test begin
Data.Timing.TestStart=GetSecs;
Quit=0; %Will return the block to the menu if pressed
Data.Timing.TR=[];
StimulusCounter=1;

% If responses are necessary for continuing then say so
if isfield(Conditions.Parameters, 'RespondtoAdvance') && Conditions.Parameters.RespondtoAdvance==1 && strcmp(FireworkType, 'Circles')
    fprintf('Waiting for response.\nPress ''space'' to continue\nPress ''x'' to flash briefly\n'); 
end
    
    
while StimulusCounter <= length(Origins) && Quit==0
   
    % get trial info
    ITIOns_actual = 0; % Preset
    ITI = Data.Timing.ITITime(1)+(rand()*(Data.Timing.ITITime(2)-Data.Timing.ITITime(1))); %Select a random number from this interval
    
    XY=Origins(StimulusCounter,:); %Where are the lines originating from
    
    
    %Do this on every trial in the line condition
    if strcmp(FireworkType, 'Lines')
        
        FlareNumber=randi(FlareRange); %How many lines on this trial
    
        FlareOrientations=rand(FlareNumber,1)*2*pi; %Produce the angles of the lines
        
        %What are the RGB values of the lines to be produced
        Temp=uint8(rand(3, FlareNumber)*255); %Make a temp file
        
        FlareColors=[]; %Reset
        FlareColors(:,2:2:size(Temp,2)*2)=Temp; %Interleave these
        FlareColors(:,1:2:(size(Temp,2)*2-1))=Temp;
    
    elseif strcmp(FireworkType, 'Circles')
       
        Colorbands=5;%How many bands of color are there?
        FlareOrientations=fliplr(0.001:MaxFlareRad/Colorbands:MaxFlareRad); %What are the sizes of each band? Go from big to small
        
        %Preset the colors, alternate between dark and light
        FlareColors = uint8((rand(3,Colorbands))*255); 
        
    end
    
    %Reset values every trial
    HeadRad=0;
    TailRad=0;
    
    HeadXY=[];
    TailXY=[];
    DotsXY=[];
    DotsColor=[];
    
    % Present the initial image
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    
    TrialOns_actual = Screen('Flip',Window.onScreen);
    
    %Issue message
    
    Window.EyeTracking = Utils_EyeTracker_TrialStart(Window.EyeTracking);
    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Position:_X=%0.0f_Y=%0.0f_Time:_%0.3f', XY(1), XY(2), TrialOns_actual));
    
    %% Initiate the firework and record any triggers heard
    
    FrameCounter=1;
    while Quit==0 % Run until told to break
            
        %Increase the length of the line
        HeadRad=HeadRad+GrowthRate;
        TailRad=TailRad+GrowthRate;
        
        %If it is the circles block then delay the time at which the 
        if strcmp(FireworkType, 'Circles') 
            
            
            %Has the normal amount of time for an expansion elapsed?
            if GetSecs<TrialOns_actual+ExpansionTime
                
                XY=[Window.centerX, Window.centerY];
                HeadRad=HeadRad-GrowthRate;
                TailRad=TailRad-GrowthRate;
            else
                %Set the origins to what they were
                XY=Origins(StimulusCounter,:); %Where are the lines originating from
            end
        end

        
        %Alter the values depending on whether they have maxed out or the
        %tail shouldnt be growing yet
        HeadRad(HeadRad>MaxFlareRad)=MaxFlareRad;
        TailRad(HeadRad<MaxHeadTailLength)=0;
        
        %If the tail is now over the max then you need to finish this trial
        if TailRad>MaxFlareRad
            
            %Will it adcance automatically or will it only advance when
            %there is a response?
            if isfield(Conditions.Parameters, 'RespondtoAdvance') && Conditions.Parameters.RespondtoAdvance==1 && strcmp(FireworkType, 'Circles')
                
                %Have they pressed space yet?
                if strcmp(KbName(keyCode_onset>0), 'space')
                    Screen(Window.onScreen,'FillRect',Window.bcolor);
                    ITIOns_actual=Screen('Flip',Window.onScreen);
                    break
                    
                elseif strcmp(KbName(keyCode_onset>0), 'x')
                    
                    %Flash on and off the circle
                    Screen(Window.onScreen,'FillRect',Window.bcolor);
                    Screen('Flip',Window.onScreen);
                    pause(0.1);
                    Screen('FillOval', Window.onScreen, FlareColors, CircleRect);
                    Screen('Flip',Window.onScreen);
                    
                end
                
            else
                
                %Flip
                Screen(Window.onScreen,'FillRect',Window.bcolor);
                ITIOns_actual=Screen('Flip',Window.onScreen);
                break
                
                
            end
        end
        
        if strcmp(FireworkType, 'Lines')
            
            
            %Store the coordinates
            HeadXY(:,1)=HeadRad .* cos(FlareOrientations)+XY(1); %Finds the x coordinate for the head of the line
            HeadXY(:,2)=HeadRad .* sin(FlareOrientations)+XY(2); %Finds the y coordinate for the head of the line
            
            
            TailXY(:,1)=TailRad .* cos(FlareOrientations)+XY(1); %Finds the x coordinate for the head of the line
            TailXY(:,2)=TailRad .* sin(FlareOrientations)+XY(2); %Finds the y coordinate for the head of the line
            
            %Make the structure necessary
            LineMatrix=[];
            for Counter=1:size(HeadXY,1)
                LineMatrix(1, ((Counter-1)*2+1): (Counter*2))= [HeadXY(Counter,1), TailXY(Counter,1)];
                LineMatrix(2, ((Counter-1)*2+1): (Counter*2))= [HeadXY(Counter,2), TailXY(Counter,2)];
            end
            
            
            %Make the colors sparkle
            if Sparkle==1
                
                if mod(FrameCounter,2)==0
                    FlareColors=FlareColors+ColorChangeAmount;
                else
                    FlareColors=FlareColors-ColorChangeAmount;
                end
                
                %Make sure the values don't max out
                FlareColors(FlareColors<0)=0;
                FlareColors(FlareColors>255)=255;
            end
            
            Screen('Drawlines', Window.onScreen, LineMatrix, FlareWidth, FlareColors);  %Draws critical stimulus
            
        elseif strcmp(FireworkType, 'Dots')
            
            %Do these randomizing steps on every frame for this 
            FlareNumber=randi(FlareRange); %How many lines on this trial
            
            FlareOrientations=rand(FlareNumber,1)*2*pi; %Produce the angles of the lines
            
            %What are the RGB values of the lines to be produced
            FlareColors=uint8((rand(3, FlareNumber)*127)+128); %Make a temp file
            
            %Make the XY positions of dots on this frame if it is growing
            if HeadRad<MaxFlareRad
                
                TempXY=[HeadRad .* cos(FlareOrientations)+XY(1), HeadRad .* sin(FlareOrientations)+XY(2)];
                
                %Store these new position
                DotsXY(end+1:end+length(TempXY),:)=TempXY;
                DotsColor(:,end+1:end+length(TempXY))=FlareColors;
            end
            
            
            %Treat the tail as the fadeout period
            if TailRad>0
                
                 %What colors will you select to decrement
                Idxs=Shuffle(1:length(DotsColor)); %Shuffle them
                Idxs=Idxs(1:round(length(DotsColor)*.8)); %Select a subset of these colors to reduce
                
                DotsColor(:,Idxs)=DotsColor(:,Idxs)-ColorChangeAmount; %Decrement the selected colors
                
                DotsColor(DotsColor<Window.bcolor)=Window.bcolor;
          
            end
            
            Screen('DrawDots', Window.onScreen, DotsXY', FlareWidth, DotsColor);  %Draws critical stimulus
            
        elseif strcmp(FireworkType, 'Circles') %Make concentric circles appear on the screen
            
            
            %What is the new circle size

            FlareOrientations = FlareOrientations - GrowthRate/2; %Although this isn't about orientation, it instead records the size of the circles
            
            %If the flare size is bigger then max, set it to almost zero
            %and bump it up. At the same time, change the color
            if FlareOrientations(Colorbands)<0
                
                %Remove the highest value from the list
                FlareOrientations=[MaxFlareRad, FlareOrientations(1:Colorbands-1)]; 
                
                %Alternate what colors are presented, if the one after the
                %one to be added is a certain color then change this color
                if FlareColors(1,Colorbands)<128
                    NewColor=uint8((rand(3, 1)*127)+128);
                else
                    NewColor=uint8((rand(3, 1)*127));
                end
                
                %Store the colors
                FlareColors = [NewColor, FlareColors(:,1:Colorbands-1)];
            end
            
            CircleRect= [XY(1) - FlareOrientations; XY(2) - FlareOrientations; XY(1) + FlareOrientations; XY(2) + FlareOrientations]; %What is the circle size, go from smallest to biggest, reading left to right
            
            Screen('FillOval', Window.onScreen, FlareColors, CircleRect); %Print the concentric cirlces
            
        end
        
        
        
        %Check for trigger
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
        
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
            NextTR=Window.TR+max(TRRecording);
        end
        
        [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
        
        %If they have pressed q then quit
        if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
            Quit=1;
        end
        
        TrialOffs_actual=Screen('Flip',Window.onScreen); %Don't bother storing it
        
        FrameCounter=FrameCounter+1;
        
    end
    
    
    
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

    if Quit==0
        
        %Store stimuli
        
        Data.Stimuli.Origin(StimulusCounter,:)=XY;
        Data.Stimuli.LineOrientations.(sprintf('Trial_%d', StimulusCounter))=FlareOrientations;
        Data.Stimuli.LineColors.(sprintf('Trial_%d', StimulusCounter))=FlareColors(:,1:2:(size(FlareColors,2)-1)); %Only pull out one set of colors
        
        
        % the giblets
        Data.Timing.FrameCounter(StimulusCounter,:)=FrameCounter-1;
        Data.Timing.TrialOns(StimulusCounter,:)=TrialOns_actual;
        Data.Timing.TrialOffs(StimulusCounter,:)=TrialOffs_actual;
        Data.Timing.ITI(StimulusCounter,:)=[ITIOns_actual, ITI];

        
        %Output the trial information
        fprintf('\n Trial: %d; Origin X: %0.0f Y: %0.0f\n', StimulusCounter, XY(1), XY(2));
        
    end
    
    %Issue message
    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Trial_Time:_%0.3f', GetSecs));        
    Window.EyeTracking = Utils_EyeTracker_TrialEnd(Window.EyeTracking);
    
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

%% pack up, go home...

Screen(Window.onScreen,'FillRect',Window.bcolor);
Screen('Flip',Window.onScreen);

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Block_Time:_%0.3f', GetSecs));

fprintf('\n\n -----------------------End of Block-------------------------- \n\n'); 
end

