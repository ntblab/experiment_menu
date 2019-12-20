function EyeTracking=Utils_EyeTracker_TrialEnd(EyeTracking)

% Wrapper script to start recording the eye tracker on a given trial set up for different eye
% tracker types. This is useful for some softwares like Eyelink which
% organize recording sessions into trials. This should be used to turn off
% frame grabbers in order to minimize the total amount of data stored

if ~isempty(EyeTracking)
    if strcmp(EyeTracking.EyeTracker_Type, 'iViewX')
        [Output, EyeTracking] = iViewX('stoprecording', EyeTracking);
        if Output==0
            fprintf('\n\nFailed to stop recording\n\n');
        end
    elseif strcmp(EyeTracking.EyeTracker_Type, 'EyeLink')       
        % If the eye tracker is already running (from the last trial for
        % instance then stop it
        if Eyelink('CheckRecording')==0;
             Eyelink('StopRecording');
        end
    elseif strcmp(EyeTracking.EyeTracker_Type, 'FrameGrabber')
        % Send the stop recording message to the eye tracker
        fprintf(EyeTracking.EyeTracker_fid, '!!-STOP_RECORDING-!!');
    end
end