%% Run a block of the Statistical Learning experiment

%This takes in a set of condition information and then selects the relevant
%conditions and executes it.
%This also takes in the window information, including the restricted
%presentation range, and it is assumed that the screen has already been
%set up when this is run

%V Bejjanki 3/2/16
%Updated 3/17/16
%Updated 5/11/16
%Updated to make timing work better 5/30/17

function Data = Experiment_StatLearning(varargin)

%Set variables
block=varargin{1};
wind=varargin{2};
gTrialConds=varargin{3};

quit =0;

runTypeAndNum = gTrialConds.Parameters.BlockNames{block};
fprintf('\n\nStatistical Learning. Block: %d, Block_Label: %s\n\n', block, runTypeAndNum);

blockNum = runTypeAndNum(length(runTypeAndNum));    %Trial number in each condition
type = runTypeAndNum(1:length(runTypeAndNum)-1);    %Figuring out condition to run -> structured or random
if strcmp(type(length(type)),'1')   %if block number has two digits -> only checking for 1 because max is 12
    type = type(1:length(type)-1);
    blockNum = strcat(['1' blockNum]);
end
blockNum = str2num(blockNum);    

if strcmp(type, 'str')
    stimOrder = gTrialConds.Parameters.StrucStreamElements(blockNum,:);
    numStim = gTrialConds.Parameters.NumStrucStims;
    stimIndx = gTrialConds.Parameters.StrucStims;
elseif strcmp(type,'rand')
    stimOrder = gTrialConds.Parameters.RandStreamElements(blockNum,:);
    numStim = gTrialConds.Parameters.NumRandStims;
    stimIndx = gTrialConds.Parameters.RandStims;
else
    fprintf('\n\nBlock type unrecognized\n\n');
    quit =1;
    
end

if ~quit
    
    %Screen dimensions
    screen_w = wind.Screen_width;
    screen_d = wind.Viewing_dist;
    
    %Key Codes
    KbName('UnifyKeyNames');
    quit_key = KbName('Q');
    but1 = KbName('1!');        %First button on buttonbox
    
    w = wind.onScreen;
    rect = wind.Rect;
    snX = wind.screenX;
    snY = wind.screenY;
    ifi = wind.frameTime;
    ppd = wind.ppd;
    
    white_index = wind.white;
    black_index = 0;
    Bkcolor=black_index;
    
    %find center of screen
    xc = rect(3)/2;
    yc = rect(4)/2;
    max_viewing = round(sqrt((rect(4)^2)+(rect(3)^2)));          % maximum screen distance in radius (deg)
    
    stimPresentDur = 1; %second
    baseStimSize = 2.4; %degrees
    finStimSize = 14.6; %degrees
    loomTime = 1.0; %period over which image looms to finStimSize from baseStimSize
    
    end_blank_time = 12;        %blank time at end (sec)
  
    %Read in stim images
    cd ../Stimuli/StatLearningStimuli/
    for i=1:length(stimOrder)
        stimImageStr = strcat('stim_', int2str(stimOrder(i)), '.png');
        tes = imread(stimImageStr);
        stimImg(i,:,:,:) = tes;
        stimImg_baseLength(i) = length(tes);
        clear tes
    end
    cd ../../Scripts
   
    numLoomFrames = floor((loomTime-ifi)/ifi);    %Making sure rounding error doesnt extend total duration of trial 
    
    % --------------------
    % start experiment now: Wait for key press to begin
    % --------------------
    
    %HideCursor;	% Hide the mouse cursor
    fprintf('\n\n-----------------------Start of Block--------------------------\n\n');
    
    %initialize screens
    Screen('FillRect',w, [0 0 0]);
    Screen('Flip', w,0,1);
   
    % Wait for the scanner
    
    % If the scanner is running it will wait 1 TR to begin, if it is not
    % running but could be then it will hang until a burn has completed. If
    % there is no scanner connected then�
    [Data.Timing.TR, quit]=Setup_WaitingForScanner(wind);
    
    %Calculate when is the next TR expected
    if ~isempty(Data.Timing.TR)
        NextTR=Data.Timing.TR(end)+wind.TR;
    else
        NextTR=wind.NextTR;
    end
    
%     if wind.isfMRI
%         fprintf('\n\n --------------------Waiting for Trigger----------------------- \n\n');
%         Utils_WaitTRPulsePTB3_skyra(1);
%     end
    Data.Timing.InitPulseTime=GetSecs;
    Utils_EyeTracker_TrialStart(wind.EyeTracking);
    wind.EyeTracking = Utils_EyeTracker_Message(wind.EyeTracking, sprintf(['Start_Of_Block__Time_' num2str(Data.Timing.InitPulseTime)]));
      
    for l=1:length(stimOrder)        
        %Check for Quit command
        
        [~, keycode_onset] = KbQueueCheck(wind.KeyboardNum); %check response
        if keycode_onset(quit_key)>0
            quit=1;
            fprintf('\nBlock Terminated\n');
            Data.Timing.TerminateTime = GetSecs;
            wind.EyeTracking = Utils_EyeTracker_Message(wind.EyeTracking, sprintf(['Block_Terminated__Time_' num2str(Data.Timing.TerminateTime)]));
            break;
        end
        stimImgCurrSize = baseStimSize*ppd;     %initializing to base size
        Data.Timing.LoomOnset(l) = GetSecs;
        OffsetTime=Data.Timing.InitPulseTime + (loomTime*l) - ifi; 
        flipcounter=1;
        
        % Flip the appropriate number of times until the offset time
        while flipcounter <= numLoomFrames && OffsetTime > GetSecs
            %Write TR
            TRRecording=Utils_checkTrigger(NextTR, wind.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                NextTR=max(TRRecording)+wind.TR;
            end     
            stimImgCurrSize = stimImgCurrSize + ((finStimSize - baseStimSize)*ppd)/numLoomFrames;
            img_scale = stimImgCurrSize/stimImg_baseLength(l);
            img_resized = imresize(squeeze(stimImg(l,:,:,:)),img_scale);
            stimImageTex =  Screen('MakeTexture', w, img_resized);
            Screen('DrawTexture',w,stimImageTex);
            Screen('Close',stimImageTex);
            Screen('Flip', w);
            flipcounter=flipcounter+1;
        end
        Data.Timing.Fliptotal(l) = flipcounter-1;
        
        Screen('FillRect',w, [0 0 0]);  
        Data.Timing.LoomOffset(l) = Screen('Flip', w, OffsetTime);
        
    end

    wind.EyeTracking = Utils_EyeTracker_Message(wind.EyeTracking, sprintf(['End_of_Block__Time_' num2str(GetSecs)]));
    Utils_EyeTracker_TrialEnd(wind.EyeTracking);
    Data.Timing.BlockEndTime = GetSecs;
    Data.Timing.DecayLapse = end_blank_time + Data.Timing.BlockEndTime;
    Data.totalRunTime = Data.Timing.BlockEndTime-Data.Timing.InitPulseTime;
    Data.Quit = quit;
    
    fprintf('\n\n -----------------------End of Block-------------------------- \n\n'); 
end