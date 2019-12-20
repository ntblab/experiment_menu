function EyeTracking=Utils_EyeTracker_Close(EyeTracking, save_file)

% Wrapper script to close the recording connection to the eye tracker set up for different eye
% tracker types

if ~isempty(EyeTracking)
    
    if strcmp(EyeTracking.EyeTracker_Type, 'iViewX')
        
        % First save the file
        [Output, EyeTracking] = iViewX('datafile', EyeTracking, save_file);
        if Output==0
            fprintf('\n\nFailed to save to idf\n\n');
        end
        
        % Close the connection to the eye tracker       
        [Output, EyeTracking]=iViewX('closeconnection', EyeTracking);
        if Output==0
            fprintf('\n\nFailed to stop recording\n\n');
        end
    elseif strcmp(EyeTracking.EyeTracker_Type, 'EyeLink')
        
        % close data file
        Eyelink('CloseFile'); 
        
        % download data file
        try
            % Retrieve the data
            fprintf('Receiving data file\n');
            status=Eyelink('ReceiveFile');
            if status > 0
                fprintf('ReceiveFile status %d\n', status);
            end
            
            if exist('temp.edf', 'file')==2
                fprintf('Data file has been created\n');
                fprintf('Creating file: %s', save_file);
                movefile('temp.edf', save_file);
            end
            
        catch error_message
            fprintf('Problem receiving data file ''%s''\n', save_file );
            error_message
        end
        
        % Turn off eye tracker
        Eyelink('Shutdown');    
        
    elseif strcmp(EyeTracking.EyeTracker_Type, 'FrameGrabber')
        
        % Send the end session message to the eye tracker
        fprintf(EyeTracking.EyeTracker_fid, '!!-END_SESSION-!!');
        
        % Close the connection
        fclose(EyeTracking.EyeTracker_fid);
        
        try
            delete(EyeTracking.EyeTracker_fid);
        catch
            fprintf('Couldn''t delete udp object, may cause problems\n');
        end
        echoudp('off')
        
    end
end