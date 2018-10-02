function EyeTracking=Utils_EyeTracker_TrialStart(EyeTracking)

% Wrapper script to start recording the eye tracker on a given trial set up for different eye
% tracker types. This is useful for some eyetrackers like Eyelink that
% organize their data into trials. This should be used to turn on
% frame grabbers in order to minimize the total amount of data stored

if ~isempty(EyeTracking)
    
    if strcmp(EyeTracking.EyeTracker_Type, 'iViewX')
        [Output, EyeTracking] = iViewX('startrecording', EyeTracking);
        
        if Output==0
            fprintf('\n\nFailed to start recording\n\n');
        end
        
    elseif strcmp(EyeTracking.EyeTracker_Type, 'EyeLink')
        
        % If the eye tracker is already running (from the last trial for
        % instance then stop it and then start it again
        if Eyelink('CheckRecording')==0;
             Eyelink('StopRecording');
        end
        
        Output=Eyelink('StartRecording');
        
        if Output==1
            fprintf('\n\nFailed to start recording\n\n');
        end
    elseif strcmp(EyeTracking.EyeTracker_Type, 'FrameGrabber')
        % Send the start recording message to the eye tracker
        fprintf(EyeTracking.EyeTracker_fid, '!!-START_RECORDING-!!');
    
    end
end