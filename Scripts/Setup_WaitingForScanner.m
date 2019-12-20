
function [TRTiming, Quit]=Setup_WaitingForScanner(Window)
%% SETUP_WAITINGFORSCANNER Wait for the scanner at the start of an experiment
% If the scanner is running, this script will wait 1 TR to begin. If the
% scanner is not running but could be (because you have said you are
% connected to the scanner) then it will hang until a burn has completed.
% If you have set the environmental variable to think that there is no
% scanner connected then nothing will happen.
%
% The code determines whether the scanner is running within the
% 'Setup_ListenandRecord' script which checks if there haven't been any
% triggers in a while and assumes that means the scanner has stopped.
%
% The input is the window. The TRTiming output specifies what TRs were
% collected in the burn in. Quit specifies whether this function was
% aborted early.
%
% First draft: 3/9/16 C Ellis

NextTR=Window.NextTR; %When is the next TR expected
TRTiming=[]; %Preset as the default
Quit=0; %Assume there won't be a quit called
KbQueueFlush(Window.KeyboardNum); %Flush Key presses

if Window.isfMRI==1 && Window.ScannerisRunning==0
    fprintf('\n****EXPERIMENT IS WAITING FOR SCANNER****\nStart scanner to begin. Press ''q'' to escape experiment, ''s'' to skip and start experiment.\nTime: %s\n\n', datestr(now));
    
    
    %Loop waiting for TRs
    BurnInCounter=1;
    while BurnInCounter<=Window.BurnIn
        
        TRRegistered=0;
        while TRRegistered==0
            
            [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
            
            %If they have pressed q then quit, if they pressed s then skip
            %waiting
            if (keyIsDown) && sum(keyCode_onset>0)==1 
                if strcmp(KbName(keyCode_onset>0), 'q')
                    
                    %Prep for quitting
                    Quit=1;
                    
                    %Quit
                    return
                    
                elseif strcmp(KbName(keyCode_onset>0), 's')
                    
                    fprintf('Burn in period aborted after %0.0f TRs. Time: %s\n\n',BurnInCounter, datestr(now)); 
                    BurnInCounter=Window.BurnIn+1;
                    break
                end
            end
            
            TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
            
            %If there is a recording then update the next TR time and store
            %this pulse
            if any(TRRecording>0)
                
                TRTiming(BurnInCounter:BurnInCounter+length(TRRecording)-1)=TRRecording;
                NextTR=max(TRRecording)+Window.TR;
                
                TRRegistered=1;
                
                %Record and update the TR
                for TRs_Counted=1:length(TRRecording)
                    fprintf('TR %0.0f\n', BurnInCounter);
                    BurnInCounter=BurnInCounter+1;
                end
            end
        end
        
        
    end
    
    
    fprintf('\nBurn in complete.\nExperiment beginning, time: %s\n\n', datestr(now));
    
elseif Window.isfMRI==1 && Window.ScannerisRunning==1
    
    fprintf('Experiment beginning without burn in. Waiting for 1 TR, time: %s\n\n', datestr(now));
    
    TRRegistered=0;
    while TRRegistered==0
        
        [keyIsDown,keyCode_onset] = KbQueueCheck(Window.KeyboardNum);
        
        %If they have pressed q then quit, if they pressed s then skip
        %waiting
        if (keyIsDown) && sum(keyCode_onset>0)==1
            %If they have pressed q then quit, if they pressed s then skip
            %waiting
            if (keyIsDown) && sum(keyCode_onset>0) 
                if strcmp(KbName(keyCode_onset>0), 'q')
                    
                    %Prep for quitting
                    Quit=1;
                    
                    %Quit
                    return
                    
                elseif strcmp(KbName(keyCode_onset>0), 's')
                    TRRegistered=1;
                    fprintf('Wait aborted. Time: %s\n\n', datestr(now)); 
                end
            end
        end
        
        TRRecording=Utils_checkTrigger(NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
        
        %If there is a recording then store this pulse
        if any(TRRecording>0)
            TRTiming=TRRecording;
            TRRegistered=1;
        end
    end
    
    fprintf('Experiment beginning, time: %s\n\n', datestr(now));
    
    
else
    fprintf('TRs not expected, not waiting., time: %s\n\n', datestr(now));
    

end
