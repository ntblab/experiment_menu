function EyeTracking=Utils_EyeTracker_Check_Eye(EyeTracking)

% Wrapper script to check whether an eye is present. Will display a wait
% screen if it isn't and then allow you to jump to calibration

if ~isempty(EyeTracking)
    
    if strcmp(EyeTracking.EyeTracker_Type, 'EyeLink')
        
        % Try and detect the eye
        eye=Eyelink('EyeAvailable');
        eye_data_struct = Eyelink('NewestFloatSample');
        if isstruct(eye_data_struct)
            x_pos=eye_data_struct.gx(eye+1);
            y_pos=eye_data_struct.gy(eye+1);
        else
            x_pos=-1;
            y_pos=-1;
        end
        % If the eye cannot be found then set up a wait loop
        
        while x_pos<0 || y_pos<0 || x_pos>screenX || y_pos>screenY
            
            DrawFormattedText(Window.onScreen, 'Eye cannot be found\nPress escape key to calibrate', 'center', 'center', uint8([255,255,255]), TextWrap);% Tell the participant to continue
            Screen('Flip',Window.onScreen);
            
            eye=Eyelink('EyeAvailable');
            eye_data_struct = Eyelink('NewestFloatSample');
            if isstruct(eye_data_struct)
                x_pos=eye_data_struct.gx(eye+1);
                y_pos=eye_data_struct.gx(eye+1);
            else
                x_pos=-1;
                y_pos=-1;
            end
            % Check to see if there has been a key press
            [~, keyonset] = KbQueueCheck(Window.KeyboardNum);
            
            % If they pressed the escape key then go into a calibration
            if sum(keyonset>0)==1 && keyonset(KbName('ESCAPE'))>0
                Window.EyeTracking = Utils_EyeTracker_Calibration(Window.EyeTracking);
            elseif keyonset(KbName('q'))>0
                break
            end
        end
    end
end