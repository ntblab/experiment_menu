

function EyeTracking=Utils_EyeTracker_Initialize(EyeTracker_Type, Window)

% Wrapper script to initiate the eye tracker set up for different eye
% tracker types

if strcmp(EyeTracker_Type, 'iViewX')
    %% Eye tracker initialization
    % Establish a connection with the eye tracker
    %
    %Two things must be changed on the SMI computer to start the eye tracker.
    %Firstly you must go into Hardware. In the Tracking Device tab you should
    %click advanced and in Advanced settings select the Right Eye to be
    %measured (default is left) unless this changes. The second thing you must
    %do is in Hardware under the Communication tab you should click configure
    %for the Remote Interface 1 and change the IP address that UDP packes are
    %sent to from XXX.XXX.X.X to whatever the IP address is for this connection
    %
    %
    %Upon connecting to the eye tracker you should be able to start recording
    %and send messages. If you start recording then this should change the
    %GUI on the SMI computer.
    %
    %Most recent update C Ellis 2/16/16
    
    % Open connection to eye tracker
    pnet('closeall'); % Force all current pnet connections/sockets (in the present matlab session) to close
    EyeTracking = iViewXInitDefaults; % creates the necessary ivx data structure
    EyeTracking.host = '192.168.1.24'; % eye tracker IP
    EyeTracking.port = 4444; % eye tracker port
    EyeTracking.localport = 4445; % port on stim PC
    [result, EyeTracking]=iViewX('openconnection', EyeTracking);
    if result < 0
        error('Could not establish connection to eye tracker');
    end
    
    
    if result < 0
        fprintf('\n\nCould not estalblish connection with iViewX\n\n');
        
        EyeTracking=[];
        
    else
        fprintf('\n\nConnection with iViewX established\n\n');
    end
    
    EyeTracking.EyeTracker_Type='iViewX';

elseif strcmp(EyeTracker_Type, 'EyeLink')
    
    % The necessary functions in order to be able to use the eyelink system for
    % Chun lab and Prisma A. 
    
    % Provide Eyelink with details about the graphics environment
    % and perform some initializations. The information is returned
    % in a structure that also contains useful defaults
    % and control codes (e.g. tracker state bit and Eyelink key values).
    
    EyeTracking=EyelinkInitDefaults(Window.onScreen);
    
    % Initialization of the connection with the Eyelink Gazetracker.
    % exit program if this fails.
    Output=EyelinkInit();
    if ~Output
        fprintf('Eyelink failed to connect. Unable to perform set up.\n');
    end
    
    [~, version]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', version );
    
    % make sure that we get event data from the Eyelink
    %         Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
    %     Eyelink('command', 'link_event_data = GAZE,GAZERES,HREF,AREA,VELOCITY');
    %     Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,BLINK,SACCADE,BUTTON');
    %
    
    % Specify
    i=Eyelink('Openfile', 'temp.edf');
    
    disp(i);
    
    EyeTracking.EyeTracker_Type='EyeLink';

elseif strcmp(EyeTracker_Type, 'FrameGrabber')
    
    % Set up the UDP connection for transmitting messages
    server_IP = 'XXX.XXX.XXX.XXX';  % What is the IP address of the destination computer (Use ifconfig (mac) or ipconfig /all (windows) to find this out)
    port=5005; % What port have you specified as containing information
    
    EyeTracking.EyeTracker_fid=udp(server_IP, port); % Create the udp communication object
    
    fopen(EyeTracking.EyeTracker_fid); % Initialize the communication
    
    % Send a message for initialization
    fprintf(EyeTracking.EyeTracker_fid, 'Initialized connection. Experiment computer time: %0.3f', GetSecs);
    
    % Name this
    EyeTracking.EyeTracker_Type='FrameGrabber';
end
