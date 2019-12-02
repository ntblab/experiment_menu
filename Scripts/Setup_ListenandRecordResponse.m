function [Str, TRTiming, ScannerisRunning, NextTR] = Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct)
%SETUP_LISTENANDRECORDRESPONSE 
%   Listen for triggers and key presses. Output both the timing of any TRs
%   while you wait and also the key press. Pressing 'v' will immediately
%   quit, in the service of making you jump to playing a video
%
%
% This requires a number of inputs:
%       Window: specifies information about whether fMRI and eye tracking
%       is being run, as well as parameters related to these.
%
%       DecayStruct: The main variable is DecayLapse: When are we ready to
%       initate a new experiment? Put inf or zero in for this value if you
%       want to skip it. If DecayLapse is potentially going to be met then
%       you need to have a MostRecentExperiment struct in DecayStruct,
%       specifying the name and block
%
%       InputStruct: specifies aspects of the input. MaxResponseLength
%       decides how long the input is expected to be. This also specifies
%       any letters that are expected or not registered.
%
%This ouputs 4 things:
%       Str: the input people made and should be interpreted
%       
%       TRTiming: the timing of the TRs that were collected during this
%       function
%
%       ScannerisRunning: a logical value as to whether TRs are coming in
%       at the anticipated rate.
%       
%       NextTR: When is the NextTR expected
%
%
%First created by C Ellis 3/4/16

MaxResponseLength=InputStruct.MaxResponseLength; % How many characters should you wait for
%If these details were supplied then grab them, otherwise assume everything
%is valid

if isfield(InputStruct, 'ValidResponse')
    ValidResponse=InputStruct.ValidResponse; %If empty then any response is valid
else
    ValidResponse='';
end

if isfield(InputStruct, 'InvalidResponse')
    InvalidResponse=InputStruct.InvalidResponse; %If empty then any response is valid
else
    InvalidResponse='';
end

DecayLapse=DecayStruct.DecayLapse; %When should the Decay lapse?

%If the decay will lapse within 1 minute then fill in these details
%otherwise assume it is blank
if abs(DecayLapse-GetSecs)<60
    MostRecentExperiment.Name=DecayStruct.MostRecentExperiment.Name; %What is the name of the last experiment run?
    MostRecentExperiment.Block=DecayStruct.MostRecentExperiment.Block; %What block was run for the last experiment?
end

TRTiming=[];

%Has the decay lapsed yet?
if DecayLapse<GetSecs
    DecayHasLapsed=1;
else
    DecayHasLapsed=0;
end

ScannerisRunning=Window.ScannerisRunning;

NextTR=Window.NextTR;

Str='';
Notewriting=0;
KbQueueFlush(Window.KeyboardNum);
while (1)
    
    %% Has the decay lapsed yet? When it does issue a response
    
    if Window.isfMRI==1 && DecayLapse<GetSecs && DecayHasLapsed==0
        
        DecayHasLapsed=1; %Alter this value
        
        %Issue a message about how long you will have to wait
        fprintf('-----Decay has lapsed now-----\n\n');
        
        %Issue an eye tracking message so you know when the
        %decay lapsed
        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('DecayLapse_%s_%s_Time:_%0.3f', MostRecentExperiment.Name, MostRecentExperiment.Block, GetSecs));
            
    end
    
    
    %If you are expecting TRs then check for the trgger
    if Window.isfMRI==1
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
        
        %If there is a recording then update the next TR time and store
        %this pulse
        if any(TRRecording>0)
            
            TRTiming(end+1:end+length(TRRecording))=TRRecording;
            NextTR=max(TRRecording)+Window.TR;
            
            ScannerisRunning=1;
            
        elseif ScannerisRunning==1 && (GetSecs-NextTR)>(Window.TR*3)
            %If the scanner goes off (we miss the NextTR by 3 TRs) 
            %then state this and this will cause the next experiment to
            %hang waiting for a burn in
            
            %Print message and issue it to the eye tracker
            fprintf('**3 TRs have been missed.**\n\n**Scanner is assumed to be off**\n\n');
            
            Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, 'Scanner_is_assumed_to_be_off');
                        
            %Update
            ScannerisRunning=0;
        end
    else
        ScannerisRunning=0; %Scanner is not running
    end
    
    
    %% Listen for key press
    
    [keyIsDown,keyCode_onset, keyCode_offset] = KbQueueCheck(Window.KeyboardNum);
    
    %If they have pressed something then confirm this response
    if (keyIsDown) && sum(keyCode_onset>0)==1
        Temp=KbName(keyCode_onset>0); %What was the string entered?
        
        %Wait while a keypress is still ongoing
        while keyCode_offset(keyCode_onset>0)==0
            [~,~, keyCode_offset] = KbQueueCheck(Window.KeyboardNum);
        end
        
        %If break the loop if return is pressed but only when the string
        %isn't empty
        if ~isempty(Str) && strcmp(Temp, 'Return') 
            if Notewriting==0
                break
            else
                Notewriting=0; %Switch back
                Str=''; %Reset the string
                
                fprintf('\n\n-------------End of note-------------\n\n');
            end
        end
        
        %Record the response if no responses are invalid, or an invalid
        %response was not pressed 
        if isempty(InvalidResponse) || isempty(strfind(InvalidResponse, Str)) || Notewriting==1
            
            %Allow for deletes and spaces and then manage letter presses inputs
            if strcmpi(Temp, 'DELETE')
                Str=Str(1:end-1);
                fprintf('\b');
            elseif strcmpi(Temp, 'space')
                Str(end+1)=' ';
                fprintf(' ');
            elseif ~isempty(strfind(Temp, 'Shift'))
                %Do nothing, ignore it
            else
                Str(end+1)=Temp(1);
                fprintf('%s', Temp(1)); %Output string
            end
            
        end
        
        
        
        %Initiate note writing
        if strcmp(Str, 'j')
            fprintf('\n\n-------------Writing a note-------------\n\n');
            Str=''; %Clear the string
            Notewriting=1;
        end
        
        if Notewriting==0
            %If they press 'v' then immediately jump to a movie
            if strcmp(Str, 'v')
                fprintf('\n\nJumping to movie...\n\n');
                break
            end
            
            
            %If they have specified some keys as appropriate then skip if these
            %are heard
            if ~isempty(ValidResponse)
                if ~isempty(strfind(ValidResponse, Str))
                    break
                end
            end
            
            %Terminate if the length of the input is sufficient
            if MaxResponseLength<=length(Str) && length(Str)>=1
                break
            end
            
        end
    end
    
end
fprintf('\n\n'); %Make space after the input


end

