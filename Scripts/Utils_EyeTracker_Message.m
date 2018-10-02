function EyeTracking=Utils_EyeTracker_Message(EyeTracking, message)

% Wrapper script to send a message to the eye tracker set up for different eye
% tracker types

if ~isempty(EyeTracking)
    
    if strcmp(EyeTracking.EyeTracker_Type, 'iViewX')
        [Output, EyeTracking] = iViewX('message', EyeTracking, message);
        
        if Output==0
            fprintf('\n\nMessage failed to send\n\n');
        end
        
    elseif strcmp(EyeTracking.EyeTracker_Type, 'EyeLink')
        
        Output = Eyelink('Message', message);
        
        if Output==1
            fprintf('\n\nMessage failed to send\n\n');
        end
    elseif strcmp(EyeTracking.EyeTracker_Type, 'FrameGrabber')
        
        % Send the message to the eye tracker
        fprintf(EyeTracking.EyeTracker_fid, message);        
    end
end