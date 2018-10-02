
function [TRTiming, Quit]=Setup_WaitingForScanner(Window)
%% SETUP_WAITINGFORSCANNER Wait for the scanner at the start of an experiment
% If the scanner is running it will wait 1 TR to begin, if it is not
% running but could be then it will hang until a burn has completed. If
% there is no scanner connected then nothing will happen
%
% The input is the window. The TRTiming output specifies what TRs were
% collected in the burn in. Quit specifies whether this function was
% aborted early.
%
% Different blocks specify different conditions, for instance you can make
% it continue the movie from where it left off (within the condition, as
% opposed to between 
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
