function [ varargout ] = Utils_checkTrigger( varargin )
% This function takes in the predicted time of the next TR and returns
% GetSecs arrival time (secs) of last TR pulse. If not within 50 ms of the
% next TR, it doesn't check for trigger and just exists.
% Multiple outputs are allowed so that if you are listening for a response
% from the participant you can (and should) use this function too

nextTriggerTime=varargin{1}; %Get trigger time

bufferTime = 0.050; %within how many s of predicted future trigger should we be?

if  GetSecs + bufferTime < nextTriggerTime
    varargout{1} = 0;
    varargout{2} = 0;
    varargout{3} = 0;
    return;
else
    
    %If there are two arguments then treat the second as the device,
    %otherwise poll for it.
    if length(varargin) >= 2
        DEVICE=varargin{2};
    else
        
        DEVICENAME ='Current Designs, Inc. 932'; %name of device you want to poll
        
        [index devName] = GetKeyboardIndices;
        for device = 1:length(index)
            if strcmp(devName(device),DEVICENAME)
                DEVICE = index(device);
            end
        end
    end
    
    % Pull out the KbName for a 5
    if length(varargin) < 3
        KeyNumber = KbName('5%');
    end
    
    % Listen to both the first and last trigger you have received and
    % output the second if they are different
    [keydown,trigger_onset,~,second_trigger_onset] = KbQueueCheck(DEVICE);
    if keydown==1 && any(trigger_onset > 0)
        if second_trigger_onset(KeyNumber) - trigger_onset(KeyNumber)>0
            varargout{1} = [trigger_onset(KeyNumber), second_trigger_onset(KeyNumber)];
        else
            varargout{1} = trigger_onset(KeyNumber);
        end
        %Ouput these if required
        varargout{2}=trigger_onset;
        varargout{3}=second_trigger_onset;
        return;
    else
        varargout{1} = 0;
        
        %Ouput these if required
        varargout{2}=trigger_onset;
        varargout{3}=second_trigger_onset;
    end

end


