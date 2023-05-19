%% Run the event-related subsequent memory experiment.
%
%This takes in a set of condition information and then selects the relevant
%conditions and executes it.
%This also takes in the window information, including the restricted
%presentation range, and it is assumed that the screen has already been
%set up when this is run
%
%First draft 12/6/2019
%Updating the background 12/12/2019
%Does not loom; could loom
%Reload last trial run 12/18/2020

function Data = Experiment_SubMem_Categories(varargin)

%Set variables
ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};
OldData=varargin{4};

KbQueueFlush(Window.KeyboardNum);

%Condition variables

%Extract the appropriate folder name for this analysis
StimulusFolder = Conditions.Parameters.StimulusDirectory;

StimulusLevelFolders=dir(StimulusFolder); %What are the file names
StimulusLevelFolders=StimulusLevelFolders(arrayfun(@(x) ~strcmp(x.name(1),'.'),StimulusLevelFolders)); %Remove all hidden files

%Are you restarting the test phase or are you continuing from where you
%left off (either this session or another session?)
if ChosenBlock==2
    LastTrial=1;
    LastVPCTrial=1;
else
    %Find the last trial that was run
    
    %Is there a structure already?
    if isfield(OldData, 'Experiment_SubMem_Categories')
        
        %What was the max block?
        Fields=fieldnames(OldData.Experiment_SubMem_Categories);
        
        LastTrial=1;
        for Fieldcounter=1:length(Fields)
            
            Temp=OldData.Experiment_SubMem_Categories.(Fields{Fieldcounter}).TrialCounter;
            Temp2=OldData.Experiment_SubMem_Categories.(Fields{Fieldcounter}).VPCTrialCounter;
            
            %Is this greater than the previous max?
            if Temp>LastTrial
                LastTrial=Temp; %If so then store it
                LastVPCTrial=Temp2;
            end
        end
    else
        LastTrial=1;
        LastVPCTrial=1;
    end
end


fprintf('\n\n Subsequent Memory Categories Block %d\n\n', ChosenBlock);

fprintf('\n\n-----------------------Start of Block--------------------------\n\n');

fprintf('Starting on trial %d\n\n', LastTrial);

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));

%% Set the parameter conditions
%Set timing
EncodingTime = 2; %how long is the image on the screen?
EndImageSize = 20; %How wide in visual degrees do you want the image to end up
EndImage_ppd = EndImageSize*Window.ppd/2;
GifImage_ppd = EndImageSize*Window.ppd*1.5; %make the background GIF 1.5 times the size of the image

Separation=Conditions.Stimuli.Disparity*Window.ppd; %VPC Information -- how far apart are the two images

GifBackground=1; %Do you want a GIF background on during encoding? (not moving)
Gif_ITI=1; %Do you want a GIF background during the ITI?
Starting_Delay=2; %how long do you want to wait before the first image onsets?
GifForward=1; % needed to make the GIF go back and forward (not just in one direction and then starting over)

% platform-independent responses
KbName('UnifyKeyNames');
flipTime = Screen('GetFlipInterval',Window.onScreen);

%Specify some screen attributes
screenX = Window.screenX;
screenY = Window.screenY;
centerX = Window.centerX;
centerY = Window.centerY;

Quit = 0; % Will return the block to the menu if pressed

%Translate the timing of the experiment into appropriate amounts for the flipTime.
Data.Timing.EncodingTime=round(EncodingTime/flipTime)*flipTime;
Data.Timing.VPCTime=round(Conditions.Parameters.VPC_Timing/flipTime)*flipTime;
Data.Timing.Starting_Delay=round(Starting_Delay/flipTime)*flipTime;

%Iterate through all the stimuli and pregenerate them, then store thetextures
for TrialCounter=1:length(Conditions.Stimuli.FinalSequence)
    
    %Is this a VPC?
    if iscell(Conditions.Stimuli.FinalSequence{TrialCounter})
        
        % Then read both the images in
        for image_counter = 1:2
            
            % Consider either the left or right image
            if image_counter==1
                image=Conditions.Stimuli.FinalSequence{TrialCounter}{1};
            else
                image=Conditions.Stimuli.FinalSequence{TrialCounter}{2};
            end
            
            % Load in the image
            [iImage, ~, Alphachannel]=imread(image);
            
            %If it is gray scale then you need to do this
            if length(size(iImage))==2
                iImage(:,:,2)=iImage(:,:,1);
                iImage(:,:,3)=iImage(:,:,1);
            end
            
            % Store image as a cell
            Im{image_counter} = iImage;
            
            % If there is an alpha channel then interpret it
            if ~isempty(Alphachannel)
                Im{image_counter}(:,:,4)=Alphachannel;
            end
            
            
            %Save out the scaling factors
            if image_counter==1
                LeftScalingFactor(TrialCounter)=size(iImage,1)/size(iImage,2);
            else
                RightScalingFactor(TrialCounter)=size(iImage,1)/size(iImage,2);
            end
        end
        
        %Make the textures
        EncodingImageTex(TrialCounter)=Screen('MakeTexture', Window.onScreen, Im{1}(:,:,:));
        NewImageTex(TrialCounter)=Screen('MakeTexture', Window.onScreen, Im{2}(:,:,:));
        
    % if this is an encoding
    else
        
        %find the image name 
        iImageName=Conditions.Stimuli.FinalSequence{TrialCounter};
        
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
        ScalingFactor(TrialCounter)=size(iImage,1)/size(iImage,2); %How much bigger is the Y than the x of the image?
        
        %save
        ImageTex(TrialCounter)=Screen('MakeTexture', Window.onScreen, iImage);
        
    end
end

%Did you want to have a gif background (at any point in the experiment?)
if GifBackground==1 || Gif_ITI==1
    % Also store the background image textures
    for GifCounter=1:length(Conditions.Stimuli.GifFiles)
        
        FileList = Conditions.Stimuli.GifFiles; % Pull out the filenames
        
        %Get the path for the given file
        iImageName=[Conditions.Parameters.BackgroundImagesDirectory, '/' FileList{GifCounter}];
        
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
        
        BackgroundTex(GifCounter)=Screen('MakeTexture', Window.onScreen, iImage);
    end
end

%% Wait for the scanner
% If the scanner is running it will wait 1 TR to begin, if it is not
% running but could be then it will hang until a burn has completed. If
% there is no scanner connected then it will just skip it 

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

%% Begin experiment

%When does the test begin
Data.Timing.TestStart=GetSecs;

% preset the counters
GifCounter=1;
TrialCounter=LastTrial; %load in from last time (or it will be 1)
VPCTrialCounter=LastVPCTrial; %load in from last time (or it will be 1)

%Set up the GIF background rect if necessary
if GifBackground ==1 || Gif_ITI==1
    BackRect = [centerX-GifImage_ppd,centerY-(GifImage_ppd*ScalingFactor(1)),centerX+GifImage_ppd,centerY+(GifImage_ppd*ScalingFactor(1))];
end

%If we have a GIF ITI, we want this to be playing at the start (before the
%first image onsets) --> otherwise it will be a short rest following the burnin 
Screen(Window.onScreen,'FillRect',Window.bcolor);

if Gif_ITI==1
    Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
end

ITIOns_actual = Screen('Flip',Window.onScreen);

while (ITIOns_actual+Data.Timing.Starting_Delay)>GetSecs && Quit==0
    %Check key presses
    [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);

    Screen(Window.onScreen,'FillRect',Window.bcolor);
    
    if Gif_ITI==1
        Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
    end
    
    TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
    
    %If there is a recording then update the next TR time and store this pulse
    if any(TRRecording>0)
        Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
        NextTR=max(TRRecording)+Window.TR;
    end
    
    %If they have pressed q then quit
    if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
        Quit=1;
        Data.TrialCounter=0;
        Data.VPCTrialCounter=0;
        break;
    end
    
    % Update the gif going forwards or backwards
    if GifForward==1
        
        if GifCounter==length(Conditions.Stimuli.GifFiles)
            GifForward=0;
        else
            GifCounter=GifCounter+1;
        end
        
    elseif GifForward==0
        
        if GifCounter==1
            GifForward=1;
        else
            GifCounter=GifCounter-1;
        end
    end
    
    Screen('Flip',Window.onScreen); %flip the screen
    
end


% Now let's start the stimulus presentation
while TrialCounter <= length(Conditions.Stimuli.FinalSequence) && Quit==0
    
    % if this is an encoding trial
    if ~iscell(Conditions.Stimuli.FinalSequence{TrialCounter}) 
        
        % get the encoding trial info
        ITITime=Conditions.Stimuli.ITI_Times(TrialCounter);% What was the randomly selected ITI?
        ITI=round(ITITime/flipTime)*flipTime; %translate it into flip time
        
        EndRect = [centerX-EndImage_ppd,centerY-(EndImage_ppd*ScalingFactor(TrialCounter)),centerX+EndImage_ppd,centerY+(EndImage_ppd*ScalingFactor(TrialCounter))];
        
        % Present the encoding image
        Screen(Window.onScreen,'FillRect',Window.bcolor);
        
        if GifBackground==1
            Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
        end
        
        Screen('DrawTexture', Window.onScreen, ImageTex(TrialCounter), [], EndRect); %Draw the image in the specified rect
        InitialImageOns_actual = Screen('Flip',Window.onScreen);
        
        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOns_of_Trial_%d_Time:_%0.3f', TrialCounter, InitialImageOns_actual));
        
        % Show the encoding image during the encoding time
        while InitialImageOns_actual+Data.Timing.EncodingTime-flipTime>GetSecs && Quit==0
            
            %Check for quits
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            %Refresh what we are showing
            Screen(Window.onScreen,'FillRect',Window.bcolor);
            
            if GifBackground ==1
                Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
            end
            
            Screen('DrawTexture', Window.onScreen, ImageTex(TrialCounter), [], EndRect);
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
            end
            
            %If they have pressed q then quit
            if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
                Quit=1;
                break;
            end
            
            Screen('Flip',Window.onScreen); %flip the screen
            
        end
        
        %Wait until the image has been present long enough and then start the ITI
        Screen(Window.onScreen,'FillRect',Window.bcolor);
        
        %ITI will have GIF background if we want it to 
        if Gif_ITI==1
            Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
        end
        
        ITIOns_actual = Screen('Flip',Window.onScreen);
        
        if Quit==0
            
            % save the timing information
            Data.Timing.ImageOns(TrialCounter,:)=InitialImageOns_actual;
            Data.Timing.ITIOns(TrialCounter,:)=ITIOns_actual;
            Data.Timing.ITITime(TrialCounter,:)=ITI;
            
            %Last part of the name
            temp=Conditions.Stimuli.FinalSequence{TrialCounter};
            temp=strsplit(temp,'/');
            Picture_Name=temp{end};
            Category_Name=temp{4};
            
            %Store what stimuli were presented
            Data.Stimuli.Category{TrialCounter}=Category_Name;
            Data.Stimuli.Name{TrialCounter}=Picture_Name;
            Data.Stimuli.isVPC(TrialCounter,:)=0;

            
            %Tell us the trial information
            fprintf('\n Trial: %d; Category: %s, Stimulus: %s\n', TrialCounter,Category_Name, Picture_Name);
            
        end
        
        %Clear up the screens so that you don't store the irrelevant textures.
        Screen('Close', ImageTex(TrialCounter))
        
        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOffs_of_Trial_%d_Time:_%0.3f', TrialCounter, GetSecs));
        
        % Update the gif going forwards or backwards
        if GifForward==1
        
            if GifCounter==length(Conditions.Stimuli.GifFiles)
                GifForward=0;   
            else
                GifCounter=GifCounter+1;
            end
            
        elseif GifForward==0
                    
            if GifCounter==1
                GifForward=1;
            else
                GifCounter=GifCounter-1;
            end
        end
        
        % Wait for the ITI
        while (ITIOns_actual+ITI)>GetSecs && Quit==0
            %Check for quits
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            Screen(Window.onScreen,'FillRect',Window.bcolor); %fill the screen
            
            %Gif if you Gif
            if Gif_ITI==1
                Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
            end
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
            end
            
            %If they have pressed q then quit
            if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
                Quit=1;
                break;
            end
            
            % Update the gif going forwards or backwards
            if GifForward==1
                
                if GifCounter==length(Conditions.Stimuli.GifFiles)
                    GifForward=0;
                else
                    GifCounter=GifCounter+1;
                end
                
            elseif GifForward==0
                
                if GifCounter==1
                    GifForward=1;
                else
                    GifCounter=GifCounter-1;
                end
            end
            
            Screen('Flip',Window.onScreen); %flip the screen
            
        end
        
        
    % if you are on a VPC trial
    else
        
        % still need an ITI time
        ITITime=Conditions.Stimuli.ITI_Times(TrialCounter);% What was the randomly selected ITI?
        ITI=round(ITITime/flipTime)*flipTime; %translate it into flip time
        
        %What is being shown here?
        VPC_Pair=Conditions.Stimuli.FinalSequence{TrialCounter};
        
        %flip a coin about which one is going to be to the left or the right
        New_Side=randi([1,2]);
        
        if New_Side > 1 %if it is number 2
            LeftStim=VPC_Pair{1}; %image name on the left (is encoding)
            RightStim=VPC_Pair{2}; %image name on the right (is new) 
            
            LeftImageTex=EncodingImageTex(TrialCounter); %left is encoding
            RightImageTex=NewImageTex(TrialCounter); %right is new
        else
            LeftStim=VPC_Pair{2}; %image name on the left (is new)
            RightStim=VPC_Pair{1}; %image name on the right (is encoding)
            
            LeftImageTex=NewImageTex(TrialCounter); %left is new
            RightImageTex=EncodingImageTex(TrialCounter); %right is encoding
        end
        
        % Which category is it? (We can just use the left stimulus to figure this out)
        Temp1=strsplit(LeftStim,'/');
        Category=Temp1{4};
        Left=Temp1{end}; %also what's the image name?
        
        Temp2=strsplit(RightStim,'/');
        Right=Temp2{end}; %and image name of the right image
        
        PositionNames={'Left', 'Right'};
        fprintf('\n\nDisplaying %s and %s (%s)\n\n%s is new\n', Left, Right,Category, PositionNames{New_Side})
        
        % And how big?
        LeftRect=[centerX-EndImage_ppd*2-(Separation/2), centerY-(EndImage_ppd*LeftScalingFactor(TrialCounter)), centerX-(Separation/2), centerY+(EndImage_ppd*LeftScalingFactor(TrialCounter))];
        RightRect=[centerX+(Separation/2), centerY-(EndImage_ppd*RightScalingFactor(TrialCounter)), centerX+(Separation/2)+EndImage_ppd*2,centerY+(EndImage_ppd*RightScalingFactor(TrialCounter))];

        Screen(Window.onScreen,'FillRect',Window.bcolor);
        
        %Set up and show the background gif image
        if GifBackground==1
            Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
        end
        
        Screen('DrawTexture', Window.onScreen, LeftImageTex, [], LeftRect); %Draw the image in the specified rect
        Screen('DrawTexture', Window.onScreen, RightImageTex, [], RightRect); %Draw the image in the specified rect
        
        VPCOns_actual = Screen('Flip',Window.onScreen);
        
        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOns_of_VPC_Time:_%0.3f', VPCOns_actual));
        
        % Show the VPC for the duration of the VPC timing
        while VPCOns_actual+Data.Timing.VPCTime-flipTime>GetSecs && Quit==0
            
            %Check for quits
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            %Refresh what we are showing
            Screen(Window.onScreen,'FillRect',Window.bcolor);
            
            if GifBackground ==1
                Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
            end
            
            Screen('DrawTexture', Window.onScreen, LeftImageTex, [], LeftRect); %Draw the image in the specified rect
            Screen('DrawTexture', Window.onScreen, RightImageTex, [], RightRect); %Draw the image in the specified rect
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
            end
            
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            %If they have pressed q then quit
            if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
                Quit=1;
                break;
            end

            Screen('Flip',Window.onScreen); %flip the screen
            
        end
        
        %Wait until the image has been present long enough and then start the ITI
        Screen(Window.onScreen,'FillRect',Window.bcolor);
        
        if Gif_ITI==1
            Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
        end
        
        ITIOns_actual = Screen('Flip',Window.onScreen);
        
        % Send the message
        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('ImageOffs_of_VPC_%d_Trial_%d_Time:_%0.3f', VPCTrialCounter, TrialCounter, GetSecs));
        
        % Update the gif going forwards or backwards
        if GifForward==1
            
            if GifCounter==length(Conditions.Stimuli.GifFiles)
                GifForward=0;
            else
                GifCounter=GifCounter+1;
            end
            
        elseif GifForward==0
            
            if GifCounter==1
                GifForward=1;
            else
                GifCounter=GifCounter-1;
            end
        end
        
        if Quit==0
            
            % save the timing information 
            Data.Timing.ImageOns(TrialCounter,:)=VPCOns_actual;
            Data.Timing.ITIOns(TrialCounter,:)=ITIOns_actual;
            Data.Timing.ITITime(TrialCounter,:)=ITI;
            
            %Store what stimuli were presented
            Data.Stimuli.Category{TrialCounter}=Category;
            Data.Stimuli.Name{TrialCounter}=VPC_Pair; %VPC pair names
            Data.Stimuli.isVPC(TrialCounter,:)=1;
            
            %Also put this info in a specific VPC place, in case that's useful later 
            Data.Timing.VPC_ImageOns(VPCTrialCounter,:)=VPCOns_actual;
            Data.Timing.VPC_ITIOns(VPCTrialCounter,:)=ITIOns_actual;
            Data.Stimuli.VPC_Names{VPCTrialCounter}=VPC_Pair; %VPC pair names
            Data.Stimuli.VPC_Side{VPCTrialCounter}=New_Side; %VPC pair names
            
        end
        
        %Clear up the screens so that you don't store the irrelevant textures.
        Screen('Close', LeftImageTex)
        Screen('Close', RightImageTex)
       
        %ITI: wait for a certain amount of time after the offset of the images 
        while (ITIOns_actual+ITI)>GetSecs && Quit==0
            
            %Check for quits
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            Screen(Window.onScreen,'FillRect',Window.bcolor);
            
            if Gif_ITI==1
                Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
            end
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
            end
            
            %If they have pressed q then quit
            if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q')
                Quit=1;
                break;
            end
   
            % Update the gif going forwards or backwards
            if GifForward==1
                
                if GifCounter==length(Conditions.Stimuli.GifFiles)
                    GifForward=0;
                else
                    GifCounter=GifCounter+1;
                end
                
            elseif GifForward==0
                
                if GifCounter==1
                    GifForward=1;
                else
                    GifCounter=GifCounter-1;
                end
            end
            
            Screen('Flip',Window.onScreen); %flip the screen
            
        end
        
        %Add to the VPC Counter
        VPCTrialCounter=VPCTrialCounter+1;
        
    end
    
    %Add to the general trial counter
    TrialCounter=TrialCounter+1;
    
    %Remember to break if you want to quit
    if (keyIsDown) && sum(keyCode_onset>0)==1 && strcmp(KbName(keyCode_onset>0), 'q') || Quit==1
        Quit=1;
        break;
    end
    
    Screen(Window.onScreen,'FillRect',Window.bcolor);
    
    if Gif_ITI==1
        Screen('DrawTexture', Window.onScreen, BackgroundTex(GifCounter), [], BackRect);
    end
    
    % Update the gif going forwards or backwards
    if GifForward==1
        
        if GifCounter==length(Conditions.Stimuli.GifFiles)
            GifForward=0;
        else
            GifCounter=GifCounter+1;
        end
        
    elseif GifForward==0
        
        if GifCounter==1
            GifForward=1;
        else
            GifCounter=GifCounter-1;
        end
    end
    
    Screen('Flip',Window.onScreen); %flip the screen
    
end

% If you finish the experiment, then add the trial counter
if isfield(Data.Timing,'ImageOns')
    Data.TrialCounter=length(Data.Timing.ImageOns); % use the number of images actually shown 
else
    Data.TrialCounter=1;
end

% If you finish, then also add to the VPC trial counter
if isfield(Data.Timing,'VPC_ImageOns')
    Data.VPCTrialCounter=length(Data.Timing.VPC_ImageOns); % use the number of images actually shown 
else
    Data.VPCTrialCounter=1;
end

%Issue a quit message
if Quit==1
    fprintf('\nBlock Terminated on Trial %d\n\n', Data.TrialCounter);

end

%Record whether this was quit preemptively --> In literally every case we
%are going to quit out before the block ends so only count it as a real
%quit out if it was before the 2nd image

if Data.TrialCounter - LastTrial < 2 % You want it to still say it was a quit if you didn't show anything
    Data.Quit=1;
else
    Data.Quit=0; % Otherwise, wasn't a real quit ;)
end

% End it all!
Data.Timing.TestEnd=GetSecs;
Utils_EyeTracker_TrialEnd(Window.EyeTracking); %trial end

%Record the time at which the next experiment can start

Data.Timing.DecayLapse=Data.Timing.TestEnd+Conditions.Parameters.DecayTime;

%% pack up, go home...

Screen(Window.onScreen,'FillRect',Window.bcolor);
Screen('Flip',Window.onScreen);

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Block_Time:_%0.3f', GetSecs));

fprintf('\n\n -----------------------End of Block-------------------------- \n\n');
end

