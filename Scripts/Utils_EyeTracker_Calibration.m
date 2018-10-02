function EyeTracking=Utils_EyeTracker_Calibration(EyeTracking)

% Wrapper script to close the recording connection to the eye tracker set up for different eye
% tracker types

if ~isempty(EyeTracking)
    
    if strcmp(EyeTracking.EyeTracker_Type, 'EyeLink')

        % Do setup and calibrate the eye tracker
        EyelinkDoTrackerSetup(EyeTracking,13);

        % do a final check of calibration using driftcorrection
        % You have to hit esc before return.
        EyelinkDoDriftCorrection(EyeTracking);
        
        % Sometimes the cursor appears
        HideCursor;
    else
        fprintf('No calibration found for %s\n', EyeTracking.EyeTracker_Type);
    end
end