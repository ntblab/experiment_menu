%% Supervise the running of modular experiments in a menu
%
% This script runs the menu system set up for collecting data with modular
% experiments
% 
% This function sets up the display necessary for the projector or screen
% set up, the eye tracker and the response devices (including a scanner).
% Then it has you pick an experiment, generates the trials for the
% experiment (if they have not already been generated), and runs a
% specified block from that experiment. After the block ends, the program
% then cycles back, allowing you to decide to either run another block of
% that experiment, reselecting an experiment from the menu or automatically
% advance to the next block
%
%First created: C Ellis 9/25/15
%Substantial update: C Ellis 2/2/15
%Updated how triggers are received and made some common calls into
%functions: C Ellis 3/9/16
%Updated the names of the files: C Ellis 7/31/16
%Updated all the code to work with KbQueueCheck instead of KbQueue: C Ellis 7/27/17
%Transferred code to Git to start development/updates there: C Ellis 1/7/18

function Data=Menu(SubjectID, varargin)

if nargin==0
    SubjectID='Pilot';
end

%% ############# DEFAULT PARAMETERS #############

TR_Duration=2; % How many seconds is the TR
BurnIn_Triggers=4; %Number of TR burn in period at the start after you have started the scanner for the first time in a while

% EYETRACKER
EyeTracker_Type='FrameGrabber'; % What is the name of the name of the eyetracker you want to use? This relies on a setup file being created with appropriate functionality to communicate with the eyetracker
EyeTracker_Calibration=0; % Do you want to use the eye tracker system calibration (might not work for some systems)
Savelocation='../Data/';
EyeTracking_Experiments={'Experiment_PosnerCuing'}; % List the experiments which need calibration. If an experiment is in this list then it will encourage you to do calibration after you have run this for the first time (useful for offline eye coding, useless for online coding)

% KEYBOARDS
%Find the operator keyboard name that you want to search for. Use
%GetKeyboardIndices to find the names of the keyboards (second output) and
%their corresponding index (first output). If this is a name (string) then
%it will search for that name. Sometimes there will be multiple keyboards
%with the same name. In such cases, use a number (not a string) to specify
%the keyboard index.
if ismac
    device_names.KeyboardNum = 'Apple Internal Keyboard / Trackpad';

elseif IsWindows
    device_names.KeyboardNum = 'Keyboard';
 
elseif IsLinux
    
    % GetKeyboardIndices acts up when there is no keyboard attached on
    % linux. Specifically it doesn't list the master/default keyboard. You
    % could just skip it (set the KeyboardNum to 1) for most purposes but
    % it wont let you set up a kbqueue on the default keyboard anyway
    device_names.KeyboardNum='DELL DELL USB Keyboard';
    
    % For some set ups you will want to set the priority differently than
    % what PTB's MaxPriority specifies. Linux may have timing issues if
    % this set above 0.
    maxPrior = 0;
end
device_names.ScannerNum = '932'; %name of device you want to poll

% ##############################################
%% Take in the inputs

% Have you preset any of the set up questions you will be asked?
arg_counter = 1;
load_str='';
scanner_str='';
Window_str='';
eyetracker_str='';
Experiment_str='';
Block_str='';
while length(varargin) >= arg_counter
    
    % What do you do if this file already exists?
    prefix='load_';
    if ~isempty(strfind(varargin{arg_counter}, prefix))
        idx=length(prefix) + 1;
        load_str=varargin{arg_counter}(idx:end);
    end
    
    % Is the scanner connected or not?
    prefix='scanner_';
    if ~isempty(strfind(varargin{arg_counter}, prefix))
        idx=length(prefix) + 1;
        scanner_str=varargin{arg_counter}(idx:end);
    end

    % What window option are you choosing (only accepts the last character
    % of the string, don't make the choice more than one character)
    prefix='window_';
    if ~isempty(strfind(varargin{arg_counter}, prefix))
        idx=length(prefix) + 1;
        Window_str=varargin{arg_counter}(idx:end);
    end
    
    % Is the eye tracker connected or not?
    prefix='eyetracker_';
    if ~isempty(strfind(varargin{arg_counter}, prefix))
        idx=length(prefix) + 1;
        eyetracker_str=varargin{arg_counter}(idx:end);
    end
    
    % What is the first experiment you will choose? 
    prefix = 'Experiment_';
    if ~isempty(strfind(varargin{arg_counter}, prefix))
        idx=length(prefix) + 1;
        Experiment_str=varargin{arg_counter}(idx:end);
    end
        
    %What is the first block?
    prefix='Block_';
    if ~isempty(strfind(varargin{arg_counter}, prefix))
        idx=length(prefix) + 1;
        Block_str=varargin{arg_counter}(idx:end);
    end
    
    arg_counter=arg_counter+1;
end

%Set up saving and start diary

EyeTracker_save_file=sprintf('%s%s.edf', Savelocation, SubjectID); % What do you want to save the eyetracker as (can only be eight characters)

svFile=[Savelocation, sprintf('/%s.mat', SubjectID)];

diary([Savelocation,  SubjectID, '_Log']); %Start a log file

%Log the time

fprintf('Experiment start time: %s\n\n', datestr(now));


%Reset the shuffler, do it differently depending on the matlab version

Temp=version; %What version of matlab are you running?
if str2double(Temp(1))>=8
    rng('shuffle');
else
    rand('twister', sum(clock));
end


%% What are the possible programs that could be run. 
% This can be updated after a participant has been run with no consequence

Temp_Experiment=dir('Experiment_*.m');

%Store the experiment function names
%If this is not a pilot participant then ignore all generate trials names
%with pilot in them

ExperimentNames={};
GenerateNames={};
for ExperimentCounter=1:length(Temp_Experiment)
    if logical(isempty(strfind(Temp_Experiment(ExperimentCounter).name, 'Pilot')) && isempty(strfind(Temp_Experiment(ExperimentCounter).name, 'Hide'))) || strcmp(SubjectID, 'Pilot') %Only include functions with pilot in the name when the participant is called pilot
        ExperimentNames{end+1}=str2func(Temp_Experiment(ExperimentCounter).name(1:end-2));
        
        % Make the generate trials names based on the experiment names, check to
        % see they exist and give an error if they don't
        temp_name = ['GenerateTrials_',  Temp_Experiment(ExperimentCounter).name(12:end-2)];
        GenerateNames{end+1}=str2func(temp_name);
        
        % If this file name doesn't exist as a function then abort
        if exist(temp_name) ~= 2
           fprintf('%s does not exist, cannot run this experiment\n\nABORTING\n', temp_name); 
        end
    end
end

%% If you can find this subject name then be ready to re run them.

%Silence all inputs to the command window
if IsWindows == 0
    ListenChar(2);
end

% Check for existing data, act accordingly...
Loaded=0;

if exist(svFile,'file')~=0
    
    %Print the question
    fprintf('Warning! Data file exists! Load it in (L), overwrite (O), or abort (A)?\n?:');
    
    %Wait for a valid response or proceed if you have preregistered it
    if isempty(load_str)
        Response=2;%Reset
        Str='';
        while sum(Response)>=2 || isempty(strfind('loa',Str))
            [~, Response]=KbWait(-1); %Wait for a response (listen to all since you haven't set it up yet
            Str=KbName(Response); %What was the string entered?
        end
    else
        Str=load_str;
    end
    
    fprintf('  %s\n\n', Str); %Output string
    
    if strcmp(Str,'l')
        fprintf('\nLoading...\n');
        
        % Only load a subset of the data that could be loaded in order to
        % minimize the risk of overwriting. Specifically, you are not
        % loading 'Window' which should mean session specific information
        % (such as keyboard) is not reloaded. However, if you have any
        % variables you want to load that aren't stored in these main
        % structures then you may be in trouble
        load(svFile, 'Data', 'GenerateTrials', 'MostRecentExperiment', 'CompletedBlocks');
        Loaded=1;
        
        %If this is the first reload then start this again
        try
            Data.Global.Timing.Loaded(end+1)=GetSecs;
        catch
            Data.Global.Timing.Loaded=GetSecs;
        end
        
        % Create a backup of the data you just loaded
        copyfile(svFile, [Savelocation, sprintf('/%s_bkp.mat', SubjectID)]);
        
    elseif strcmp(Str,'a')
        fprintf('\nAborting...\n');
        ListenChar(1);
        return
        
    end
end

%% Initialize the appropriate variables for a participant

% Only do this if you aren't reloading
if Loaded==0
    
    Data.Global.SubjectID= SubjectID;
    
    Data.Global.Timing.Start=GetSecs;
    
    Data.Global.EyeTrackingToggle=[]; %Has the eye tracking been flipped (on or off)
    
    Data.Global.fMRIToggle=[]; %Has the trigger listening been flipped (on or off)
    
    Data.Global.RunOrder={}; %What order are experiments run in?
    
    Data.Global.Timing.TR=[]; %Don't reset this every participant
    
    GenerateTrials=struct;
    
    CompletedBlocks=struct;
    
end

%% Set the names of the response devices

% Find the index numbers of all the devices
device_fields=fieldnames(device_names);
[index, devName] = GetKeyboardIndices;
for device_counter = 1:length(index)
    for name_counter = 1:length(device_fields)
        device_field=device_fields{name_counter};    
        
        if isnumeric(device_names.(device_field))
            Window.(device_field)= device_names.(device_field);
        else
            if ~cellfun(@isempty, strfind(devName(device_counter), device_names.(device_field))) % Make it so it will not overwrite the first keyboard if there are multiple attached
                Window.(device_field)= index(device_counter);
            end
        end
    end
end

if exist('Window', 'var')==0
    fprintf('Could not find keyboard devices, aborting\n');
    return
end
% Set up the KbQueue function, establishing two queues, one for the
% scanner and response box, one for the keyboard
KbQueueCreate(Window.KeyboardNum);
KbQueueStart(Window.KeyboardNum);

if isfield(Window, 'ScannerNum')
    KbQueueCreate(Window.ScannerNum);
    KbQueueStart(Window.ScannerNum);
end

KbName('UnifyKeyNames'); % To help portability

%% Query if they are using a scanner and so whether you should wait for it

fprintf('Are you connected to the scanner (''y'' for yes, ''n'' for no)? \n');

%Wait until there is a valid response
isfMRI=-1;
Window.NextTR=inf;
while isfMRI==-1

    %Wait for a valid response or proceed if you have preregistered it
    if isempty(scanner_str)
        Response=2;%Reset
        while sum(Response)>=2
            [~, Response]=KbWait(Window.KeyboardNum); %Wait for a response
        end
        Str=KbName(Response); %What was the string entered?
    else
        Str=scanner_str;
    end

    if ~iscell(Str) %Only take in single key presses
        if strcmp(Str(1), 'y')
            
            %Check if the input tp theexists if not then print an error
            if ~isfield(Window, 'ScannerNum')
                warning('Scanner device not detected. Functionality won''t work.')
                Window.ScannerNum=-1; %Set to be absent
            end
            Window.NextTR=0;
            isfMRI=1;

        elseif strcmp(Str(1), 'n')
            Window.ScannerNum=-1;
            isfMRI=0;
        end
    end

end
fprintf('%s\n\n', Str(1)); %Output string

%% Open screen (do it differently depending on whether you are projecting or
%not)

% Initiate the screen setup
Window=Setup_Display(Window, Window_str);

% Add additional infortmation to the window function, like Eyetracking
Window.isfMRI=isfMRI;
Window.TR = TR_Duration; 
Window.BurnIn = BurnIn_Triggers;

% Default to assuming the scanner is off
Window.ScannerisRunning=0;

% Get the original priority so that you can return to it after the block
origPrior = Priority; % for returning to later
if exist('maxPrior') == 0
    maxPrior = MaxPriority(Window.onScreen); % What is the max priority?
end

%% Set up the eye tracker
PrintText_List = {}; % Preset to empty the list of messages that have been printed
PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('\n\nWould you like to connect to the %s eye Tracker (''y'' for yes, ''n'' for no)? \n\n', EyeTracker_Type));

%Wait until there is a valid respons
Window.isEyeTracking=-1;
while Window.isEyeTracking==-1

    %Wait for a valid responseor proceed if you have preregistered it
    if isempty(eyetracker_str)
        Response=2;%Reset
        while sum(Response)>=2
            [~, Response]=KbWait(Window.KeyboardNum); %Wait for a response
        end
        Str=KbName(Response); %What was the string entered?
    else
        Str=eyetracker_str;
    end


    if ~iscell(Str) %Only take in single key presses
        if strcmp(Str(1), 'y')
            
            Window.EyeTracking=Utils_EyeTracker_Initialize(EyeTracker_Type, Window);
            
            % Calibrate eye tracker
            if EyeTracker_Calibration==1
                Window.EyeTracking = Utils_EyeTracker_Calibration(Window.EyeTracking);
            end

            Window.isEyeTracking=1;

        elseif strcmp(Str(1), 'n')
            Window.EyeTracking=[]; % Make an empty variable
            Window.isEyeTracking=0;
        end
    end

end
PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('%s\n\n', Str(1))); %Output string

%Send a message about the initialization of the eye tracker (but only if
% the eye tracker the initialized (and thus the struct has content))
Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Initiate_Eye_tracker_Time:_%0.3f', GetSecs));


%% Present menu of experimental options

% Preset before they are overwritten
JustCompletedBlock=0;
QuitMenu=0;
MostRecentExperiment.Name='';
DecayLapse=0; %Assume no burn in period at the start of the experiment
LastSecondAborted=0; %DId you abort while waiting for the decay to lapse.
JumpToVideo=0; %Assume you are not jumping to the video until told otherwise

while QuitMenu==0
    
    %% Do you want to quickly advance to the next block (if there is one)
    if JustCompletedBlock==1
        
        if ChoosenBlock+1<=BlockNumber
            PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('\n\nWould you like to continue with next block (''y'') or repeat this block (''r'')?\nNext is block %d: %s of %s\n\nAlternatively press the block number you would like to go to. Press ''s'' to display the options.\n\nTo go back to the main menu press ''n''\n\n', ChoosenBlock+1, GenerateTrials.(SelectedExperimentName).Parameters.BlockNames{ChoosenBlock+1}, SelectedExperimentName));
        else
            PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n\nPress ''r'' to repeat or type in the block number you would like to go to. Press ''s'' to display the options.\n\nTo go back to the main menu press ''n''\n\n');
        end
        
        % If you have completed a block which requires eye tracking to be
        % considered but have not yet done a calibration then output a
        % warning.
        
        Experiments=fieldnames(Data);
        EyeTracking_Experiment=0; % Has an eye tracking expt been run?
        
        for ExperimentCounter=1:length(Experiments)
            % If any of the experiments needing this have been done then
            % make this
            for EyeTracking_Experiment_Counter=1:length(EyeTracking_Experiments)
                if ~isempty(strfind(Experiments{ExperimentCounter}, EyeTracking_Experiments{EyeTracking_Experiment_Counter}))
                    EyeTracking_Experiment=1; % It has been run
                end
            end
        end
        
        EyeTrackingCalib=isfield(Data, 'Experiment_EyeTrackerCalib');
        
        %Print reminder message
        if EyeTrackingCalib==0 && EyeTracking_Experiment==1
            PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n\n############################\n\nYou haven''t done the Eye Tracker Calibration yet.\n\n############################\n\n')
        end
        
        % Has the next block already been specified by the previous block
        % in such a way that you
        if isfield(Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block), 'NextBlock')
            Automatic_next_block_selection=Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).NextBlock;
        else
            Automatic_next_block_selection=0; % Don't automatically advance, wait for input
        end
        
        % Has the next block already been selected and initiated?
        if Automatic_next_block_selection==0
            
            %Prep inputs to the listen response
            InputStruct.MaxResponseLength=ceil(log(BlockNumber+1)/log(10));
            InputStruct.ValidResponse='ynqrs';
            InputStruct.InvalidResponse='';
            DecayStruct.DecayLapse=DecayLapse; %When should the Decay lapse?
            DecayStruct.MostRecentExperiment=MostRecentExperiment; %What is the name of the last experiment run?
            
            %Listen for a response and store the output
            [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);

            %Add the new TR data
            Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;
            
            %Store the TRs with the last data collected
            Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
        
        else
            % Assume you are moving on immediately, unless they pressed
            % quit
            if Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Quit==0
                Str='y';
            else
                Str='q';
            end
        end
        
        
        %If they responded with s then display the different blocks and
        %listen for response again
        if strcmp(Str, 's')
            
            %Print out all of the block names
            PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('You have done %d blocks of %d for this experiment.\n\nBlock options include:', sum(CompletedBlocks.(SelectedExperimentName)>0), BlockNumber));
            
            %Present the block names
            for BlockCounter=1:BlockNumber
                
                %Use roman numerals to rename the files
                if CompletedBlocks.(MostRecentExperiment.Name)(BlockCounter)>0
                    Prefix=Utils_num2roman(CompletedBlocks.(MostRecentExperiment.Name)(BlockCounter)); %Put the number of repetitions at the front
                else
                    Prefix='';
                end
                
                PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('\n\n %s   %0.0f: %s', Prefix, BlockCounter, GenerateTrials.(MostRecentExperiment.Name).Parameters.BlockNames{BlockCounter}));
            end
            
            %Ask participants to choose
            
            PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('\n\nWhat one would you like to do? Press ''b'' to go back.\n\n'));
            
            %Listen for a response and store the output
            
            [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);
            
            %Add the new TR data
            Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;
            
            %Store the TRs with the last data collected
            Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
            
        end
        
        
        if strcmp(Str, 'y') && ChoosenBlock+1<=BlockNumber
            
            DecidedBlock=1; %Have you decided what block to go to next
            ChoosenBlock=ChoosenBlock+1;
            
        elseif strcmp(Str, 'r') %Decided to repeat a block, don't change what was choosen
            
            DecidedBlock=1;
            
        elseif find(str2double(Str)==1:BlockNumber)
            
            DecidedBlock=1; %Have you decided what block to go to next
            ChoosenBlock=str2double(Str);
            
        elseif strcmp(Str, 'v') %Jump to the video, skipping other parts of the menu
            DecayLapse=0; %Set to zero so that you can immediately start the next block. This might not be what you want.
            JumpToVideo=1;
            DecidedBlock=0;
            JustCompletedBlock=0;
            
        else
            
            DecidedBlock=0;
            JustCompletedBlock=0;
        end
        
    else
        DecidedBlock=0;
    end
    
    %% Select an experiment, generate trials
    
    if DecidedBlock==0 %If you are yet to determine what block to go to
        
        %Loop until there is a valid input
        
        ValidEntry=0;
        
        while ValidEntry==0
            %% Experiment menu
            
            %Are you doing the menu because you aren't jumping to video?
            
            if JumpToVideo==0
                
                %Give them the options of the experiments
                
                PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('\n\nSelect what to do next.\n\nYour options are:\n\n'));
                
                %Iterate through the different possible functions you can select
                for ExperimentNamesCounter=1:length(ExperimentNames)
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('%d. %s\n\n', ExperimentNamesCounter, func2str(ExperimentNames{ExperimentNamesCounter}))); %Print the function name as a string
                end
                
                PrintText_List=Utils_PrintText(Window, PrintText_List, '\no. Options\n\n'); %Print the function name as a string
                
                %Print what they have to do
                PrintText_List=Utils_PrintText(Window, PrintText_List, 'Type the number corresponding to the program you wish to run. If you want to end press ''q''.\nPress enter/return to submit.\n\n');
                
                %Record a response
                if isempty(Experiment_str)
                    %Prep inputs to the listen response
                    InputStruct.MaxResponseLength=ceil(log(length(ExperimentNames)+1)/log(10));
                    InputStruct.ValidResponse='qo';
                    InputStruct.InvalidResponse='';
                    DecayStruct.DecayLapse=DecayLapse; %When should the Decay lapse?
                    DecayStruct.MostRecentExperiment=MostRecentExperiment; %What is the name of the last experiment run?
                    
                    %Listen for a response and store the output
                    [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);
                    
                    %Add the new TR data. If the scanner isn't on this
                    %does nothing
                    Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;
                    
                    %Store the TRs with the last data collected if appropriate
                    if ~isempty(MostRecentExperiment.Name)
                        Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
                    end
                    
                else
                    Str=Experiment_str;
                end
                
                %Rename this string a number so it can be dealt with
                if strcmp(Str, 'o')
                    Str=num2str(ExperimentNamesCounter+1);
                end
                
                
               
                if strcmp(Str, 'v') %Jump to the video, skipping other parts of the menu
                    DecayLapse=0; %Set to zero so that you can immediately start the next block. This might not be what you want.
                    JumpToVideo=1;
                end
            end
            
            %Make the selection the one with PlayVideo if appropriate
            if JumpToVideo==1
                Counter=1;
                while ~strcmp(func2str(ExperimentNames{Counter}), 'Experiment_PlayVideo')
                    Counter=Counter+1;
                end
                
                Str=num2str(Counter); %Store the appropriate string
            end
            
            %Is the response a number and is it possible?
            if ~isnan(str2double(Str)) && length(find(str2double(Str)==1:length(ExperimentNames)))==1
                
                
                %What expt did they choose
                SelectedExperiment=str2double(Str);
                SelectedExperimentName=func2str(ExperimentNames{SelectedExperiment});
                
                PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('\nYou chose %s.\n\n', SelectedExperimentName));
                
                %Is this a viable experiment choice?
                if find(1:length(ExperimentNames), SelectedExperiment)
                    
                    %Figure out whether these trials have been generated
                    
                    GeneratedExperiments=fieldnames(GenerateTrials);
                    
                    %Is there an experiment by this name? If not then
                    %generate trials.
                    
                    if isempty(cell2mat(strfind(GeneratedExperiments, SelectedExperimentName))) || isempty(GenerateTrials.(SelectedExperimentName))
                        
                        %Generate the trial structures used in these experiments
                        GenerateTrials.(SelectedExperimentName)=GenerateNames{SelectedExperiment}(GenerateTrials, CompletedBlocks, Data, Window);
                        
                        %If you made a generate trials when you shouldn't
                        %have then make it empty and the experiment won't
                        %crash
                        if isempty(GenerateTrials.(SelectedExperimentName))
                            
                            %Remove this field
                            GenerateTrials=rmfield(GenerateTrials, SelectedExperimentName);
                            
                            warning('GenerateTrials was empty. Experiment cannot be run.')
                            
                            Str='q';
                            
                            break
                        end
                        
                        %Which blocks of each experiments have been run and
                        %how many times? Preset to zero upon generation
                        CompletedBlocks.(SelectedExperimentName)=zeros(GenerateTrials.(SelectedExperimentName).Parameters.BlockNum,1);
                        
                        
                    end
                    
                    
                    %Pull out how many blocks there are from this design.
                    BlockNumber=GenerateTrials.(SelectedExperimentName).Parameters.BlockNum;
                    
                    %Jump ahead if it isn't necessary
                    if JumpToVideo==1
                        ValidEntry=1;
                        ChoosenBlock=1;
                    else
                        
                        %Specify what blocks have been done
                        PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('You have done %d blocks of %d for this experiment.\n\nBlock options include:', sum(CompletedBlocks.(SelectedExperimentName)>0), BlockNumber));
                        
                        %Present the block names
                        for BlockCounter=1:BlockNumber
                            
                            %Put a roman numeral in front of a block for every time it has been completed
                            if CompletedBlocks.(SelectedExperimentName)(BlockCounter)>0
                                Prefix=Utils_num2roman(CompletedBlocks.(SelectedExperimentName)(BlockCounter)); %Put the number of repetitions at the front
                            else
                                Prefix='';
                            end
                            
                            PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('\n\n %s   %0.0f: %s\n\n', Prefix, BlockCounter, GenerateTrials.(SelectedExperimentName).Parameters.BlockNames{BlockCounter}));
                        end
                        
                        
                        %Ask what block number you would like to do
                        if BlockNumber>1
                            
                            %Ask participants to choose
                            
                            PrintText_List=Utils_PrintText(Window, PrintText_List, 'What one would you like to do? Press ''b'' to go back.\n\n');
                            
                            %Record a response unless it has already been
                            %pre-registered
                            if isempty(Block_str)
                                %Prep inputs to the listen response
                                InputStruct.MaxResponseLength=ceil(log(BlockNumber+1)/log(10));
                                InputStruct.ValidResponse='qb';
                                InputStruct.InvalidResponse='';
                                DecayStruct.DecayLapse=DecayLapse; %When should the Decay lapse?
                                DecayStruct.MostRecentExperiment=MostRecentExperiment; %What is the name of the last experiment run?

                                %Listen for a response and store the output
                                [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);

                                %Add the new TR data. If the scanner isn't on this
                                %does nothing
                                Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;
                                
                                
                                %Store the TRs with the last data collected if appropriate
                                if ~isempty(MostRecentExperiment.Name)
                                    Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
                                end
                            else
                                Str=Block_str;
                                
                            end
                            
                            %If the answer was a number in the range then continue,
                            %otherwise go back to the higher menu.
                            
                            if find(str2double(Str)==1:BlockNumber)
                                ChoosenBlock=str2double(Str);
                                
                                ValidEntry=1;
                                
                                %Report back
                                PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('\nYou chose block %d.\n\n', ChoosenBlock));
                                
                                
                            elseif strcmp('v', Str) %If they pressed v then jump to video
                                DecayLapse=0; %Set to zero so that you can immediately start the next block. This might not be what you want.
                                JumpToVideo=1;
                                
                            else
                                PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('%s is invalid.\n\n', Str));
                                
                            end
                        else %If there is only one block don't ask
                            ValidEntry=1;
                            ChoosenBlock=1;
                        end
                        
                    end
                end
                
                
                
            elseif ~isnan(str2double(Str)) && length(find(str2double(Str)==length(ExperimentNames)+1))==1
                %% Options menu
                
                %If they picked the options menu then jump here. If you
                %don't make ValidEntry==1 then you will loop around here
                
                OptionNames={'Pause',... %Stop listening for triggers and recording data
                    'Toggle isEyetracking',... %Flip whether eye tracking is recorded (either turn it on or turn it off)
                    'Calibrate Eyetracker',... %Run the eye tracker calibration again.
                    'Toggle isfMRI',... %Flip whether triggers are expected(either turn it on or turn it off)
                    'Check status',... %Check the status of variables
                    'Change GenerateTrial defaults',... %Allow you to edit the defaults, when specified here, of a GenerateTrials that has been created
                    'Delete a GenerateTrial',... %Delete some generate trials
                    };
                
                %Give them the option.
                PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n\n ------ OPTIONS ------ \n\nSelect what to do next.\n\nYour options are:\n\n');
                
                %Iterate through the different possible functions you can select
                for OptionCounter=1:length(OptionNames)
                    PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('%d. %s\n\n', OptionCounter, OptionNames{OptionCounter})); %Print the option name
                end
                
                PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('\n%d. Return\n\n', OptionCounter+1)); %Have the ability to return
                
                %Print what they have to do
                PrintText_List=Utils_PrintText(Window, PrintText_List,  'Type the number corresponding to the program you wish to run. If you want to end press ''q''.\nPress enter/return to submit.\n\n');
                
                
                %Record a response
                
                %Prep inputs to the listen response
                InputStruct.MaxResponseLength=ceil(log(length(OptionNames)+1)/log(10));
                InputStruct.ValidResponse='bq';
                InputStruct.InvalidResponse='';
                DecayStruct.DecayLapse=DecayLapse; %When should the Decay lapse?
                DecayStruct.MostRecentExperiment=MostRecentExperiment; %What is the name of the last experiment run?
                
                %Listen for a response and store the output
                [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);
                
                %Add the new TR data. If the scanner isn't on this
                %does nothing
                Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;
                
                %Store the TRs with the last data collected if appropriate
                if ~isempty(MostRecentExperiment.Name)
                    Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
                end
                
                %Execute different functions depending on the input. If
                %anything other than the following are pressed it will jump
                %back to the main menu
                
                if strcmp(Str, '1') %Pause function
                    
                    %Print out what will happen
                    
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n\nYou have initiated a pause. TRs won''t be listened for and eye tracking will be stopped\n\nPress any key in order to return this functionality\n\n');
                    
                    %Send a message with the eye tracker and stop recording
                    
                    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Pause_Start_Time:_%0.3f', GetSecs));
                    
                    %Wait for a key press
                    
                    KbWait(Window.KeyboardNum);
                    
                    % Start recording and send a message with the eye tracker
                    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Pause_Stop_Time:_%0.3f', GetSecs));
                    
                    
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  'You have ended a pause. TRs will be listened for and eye tracking has resumed\n\n');
                    
                    
                elseif strcmp(Str, '2') %Eye tracking toggle
                    
                    ToggleNames={'Off', 'On'};
                    PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('\n\nEye tracker is set to %s. Now it is set to %s\n\n', ToggleNames{Window.isEyeTracking+1}, ToggleNames{3-(Window.isEyeTracking+1)}));
                    
                    if Window.isEyeTracking == 1
                        %Stop the eye tracker if it is going
                        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Toggle_Stop_Time:_%0.3f', GetSecs));
                        Window.EyeTracking = Utils_EyeTracker_Close(Window.EyeTracking);
                        
                    else
                        
                        %Start the eye tracker if it was stopped
                        Window.EyeTracking = Utils_EyeTracker_Initialize(Window.EyeTracking);
                        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Toggle_Start_Time:_%0.3f', GetSecs));
                    end
                    
                    %Toggle the eye tracker
                    Window.isEyeTracking= 1 - Window.isEyeTracking;
                    
                    %Record the time when the eye tracking information was
                    %changed
                    Data.Global.EyeTrackingToggle(end+1,:)=[Window.isEyeTracking, GetSecs];
                
                elseif strcmp(Str, '3') %Do eyetracking calibration
                    
                    % Preform the calibration
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  'Running a calibration\n');
                    Window.EyeTracking = Utils_EyeTracker_Calibration(Window.EyeTracking);
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  'Calibration complete\n\n');
                    
                elseif strcmp(Str, '4') %Trigger listening toggle
                    
                    ToggleNames={'Off', 'On'};
                    PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('\n\nListening for Triggers is now set to %s\n\n', ToggleNames{3-(Window.isfMRI+1)}));
                    
                    %Toggle isfMRI
                    Window.isfMRI= 1 - Window.isfMRI;
                    
                    %Listen for a TR. If none are issued then flip back to
                    %no fMRI
                    
                    if Window.isfMRI==1
                        try
                            PrintText_List=Utils_PrintText(Window, PrintText_List,  'Now listening for triggers. If it fails to hear one then will toggle listening off\n\n')
                            Utils_WaitTRPulsePTB3_skyra(1);
                            
                            PrintText_List=Utils_PrintText(Window, PrintText_List,  'Trigger heard. \n\n');
                            
                            %Record the time when the fMRI information was
                            %changed
                            Data.Global.fMRIToggle(end+1,:)=[Window.isfMRI, GetSecs];
                            
                        catch
                            PrintText_List=Utils_PrintText(Window, PrintText_List,  '***** Scanner not found ***** Listening toggled off\n\n');
                            Window.isfMRI=0;
                        end
                    end
                    
                elseif strcmp(Str, '5') %Report the status of several variables
                    
                    ToggleNames={'Off', 'On'};
                    ConfirmationNames={'No', 'Yes'};
                    PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf(['\n\nPrinting the status of variables\n\n',...
                        'Run time is %0.02f minutes\n',...
                        'Scanner is found: %s\n',...
                        'Scanner is running: %s\n',...
                        'Next TR is in %0.02f seconds\n',...
                        'Eye Tracker is %s\n'],...
                        (GetSecs-Data.Global.Timing.Start)/60,...
                        ConfirmationNames{Window.isfMRI+1},...
                        ConfirmationNames{Window.ScannerisRunning+1},...
                        Window.NextTR-GetSecs,...
                        ToggleNames{Window.isEyeTracking+1}));
                    
                elseif strcmp(Str, '6')
                    
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n\nWhich GenerateTrials would you like to change?\n');
                    
                    GenerateFields=fieldnames(GenerateTrials);
                    for FieldCounter = 1:length(GenerateFields)
                        PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('%d: %s\n', FieldCounter, GenerateFields{FieldCounter}));
                    end
                    
                    %Print what they have to do
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  '\nType the number corresponding to the GenerateTrials you want to alter. If you want to abort press ''q''.\nPress enter/return to submit.\n\n');
                    
                    %Record a response
                    
                    %Prep inputs to the listen response
                    InputStruct.MaxResponseLength=ceil(log(length(GenerateTrials)+1)/log(10));
                    InputStruct.ValidResponse='q';
                    InputStruct.InvalidResponse='';
                    DecayStruct.DecayLapse=DecayLapse; %When should the Decay lapse?
                    DecayStruct.MostRecentExperiment=MostRecentExperiment; %What is the name of the last experiment run?
                    
                    %Listen for a response and store the output
                    [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);
                    
                    %Add the new TR data. If the scanner isn't on this
                    %does nothing
                    Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;
                    
                    %Store the TRs with the last data collected if appropriate
                    if ~isempty(MostRecentExperiment.Name)
                        Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
                    end
                    
                    %Interprete the valid responses
                    if ~isnan(str2double(Str)) && length(find(str2double(Str)==1:length(GenerateFields)))==1
                        
                        %Which experiment are you altering
                        Field=GenerateFields{str2double(Str)};
                        
                        % Get the function and run it if it exists
                        temp_name = ['GenerateTrials_Modify_', Field(12:end)];
                        if exist(temp_name) == 2
                            
                            % Run the GenerateTrials_ modification script
                            func=str2func(temp_name);
                            [GenerateTrials, PrintText_List] = func(Window, GenerateTrials, Data, DecayLapse, MostRecentExperiment);
                        else
                            PrintText_List=Utils_PrintText(Window, PrintText_List,  'No options to change available. Exiting.\n\n');
                        end
                        
                    end
                    
                elseif strcmp(Str, '7') %Do you want to delete an experiment you have previously created a GenerateTrials structure for?
                    
                    
                    %Which experiments have been run
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n\nWhat Generate trials would you like to delete?.\n\nYour options are:\n\n')
                    
                    %Iterate through the different possible functions you can select
                    GenerateFields=fieldnames(GenerateTrials); %What trials have been generated
                    for ExperimentNamesCounter=1:length(GenerateFields)
                        
                        PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('%d. %s\n\n', ExperimentNamesCounter, GenerateFields{ExperimentNamesCounter})); %Print the function name as a string
                    end
                    
                    %Print what they have to do
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  'Type the number corresponding to the GenerateTrials you want to delete. If you want to end press ''q''.\nPress enter/return to submit.\n\n');
                    
                    %Record a response
                    
                    %Prep inputs to the listen response
                    InputStruct.MaxResponseLength=ceil(log(length(GenerateTrials)+1)/log(10));
                    InputStruct.ValidResponse='1';
                    InputStruct.InvalidResponse='';
                    DecayStruct.DecayLapse=DecayLapse; %When should the Decay lapse?
                    DecayStruct.MostRecentExperiment=MostRecentExperiment; %What is the name of the last experiment run?
                    
                    %Listen for a response and store the output
                    [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);
                    
                    %Add the new TR data. If the scanner isn't on this
                    %does nothing
                    Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;
                    
                    %Store the TRs with the last data collected if appropriate
                    if ~isempty(MostRecentExperiment.Name)
                        Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
                    end
                    
                    %Interprete the valid responses
                    
                    if ~isnan(str2double(Str)) && length(find(str2double(Str)==1:length(GenerateFields)))==1
                        
                        %What expt did they choose
                        DeletedGenerateTrials=str2double(Str);
                        DeletedGenerateTrials=GenerateFields{DeletedGenerateTrials};
                        
                        %Ask whether you are sure you want to delete the
                        %provided generate trials
                        
                        PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('\n\n############################\n\nAre you sure you want to delete %s? This cannot be undone!\nPress ''y'' to confirm\n\n############################\n\n', DeletedGenerateTrials));
                        
                        %Prep inputs to the listen response
                        InputStruct.MaxResponseLength=1;

                        %Listen for a response and store the output
                        [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);
                        
                        %Add the new TR data. If the scanner isn't on this
                        %does nothing
                        Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;
                        
                        %Store the TRs with the last data collected if appropriate
                        if ~isempty(MostRecentExperiment.Name)
                            Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
                        end
                        
                        %If they pressed y then delete the generate trials
                        if strcmp('y', Str) 
                            
                            %Don't actually delete this, just put it in the
                            %trash (although it will overwrite)
                            Trash.(DeletedGenerateTrials)=GenerateTrials.(DeletedGenerateTrials);
                            
                            %Now remove it
                            GenerateTrials=rmfield(GenerateTrials, DeletedGenerateTrials);
                            
                            %Report what has happened
                            PrintText_List=Utils_PrintText(Window, PrintText_List,  sprintf('\n\nYou have put %s in the trash\n\n', DeletedGenerateTrials));
                        else
                            
                            PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n\nYou have not deleted anything\n\n');
                            
                        end
                        
                    else
                        
                        PrintText_List=Utils_PrintText(Window, PrintText_List,  '\nYou have not deleted anything\n\n');     
                    end    
                end
            else
                %If they pressed q then quit
                if strcmp(Str, 'q')
                    ValidEntry=1;
                else
                    PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('%s is invalid.\n\n', Str));
                    
                end
            end
            
        end
        
        
    end
    
    %% Experiment confirmation or quit
    if strcmp(Str, 'q')
        
        PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n\nAre you sure want to quit? Press ''y'' if yes, any other key to go back to menu\n\n');

        % Loop through until you hear 5 q's, a y or you hear something else
        q_counter=0;
        while QuitMenu==0
            %Record a response

            InputStruct.MaxResponseLength=1;
            DecayStruct.DecayLapse=DecayLapse; %When should the Decay lapse?
            DecayStruct.MostRecentExperiment=MostRecentExperiment; %What is the name of the last experiment run?

            %Listen for a response and store the output
            [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);

            %Add the new TR data. If the scanner isn't on this
            %does nothing
            Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;

            %Store the TRs with the last data collected if appropriate
            if ~isempty(MostRecentExperiment.Name)
                Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
            end

            if strcmp(Str, 'y')
                QuitMenu=1;
            elseif strcmp(Str, 'q')
                q_counter=q_counter+1; % Increment
                if q_counter == 5
                    QuitMenu=1;
                end
            else
                % THey pressed something else so abort
                break;
            end
        end
        
    else
        
        %Check that the block has not been run yet. Name the block accordingly
        if isfield(Data, SelectedExperimentName)
            
            try
                Fields=fieldnames(Data.(SelectedExperimentName)); %What are block names that exist?
                
                %Iterate through the fields to see if the block is
                %mentioned at all
                
                Counter=0;
                for StructCounter=1:length(Fields)
                    
                    %What block does this field correspond to
                    block_split = strsplit(Fields{StructCounter}, '_');
                    FieldBlock=str2num(block_split{2});
                    
                    if FieldBlock==ChoosenBlock %Extract the block number
                        Counter=Counter+1;
                    end
                end
                
                %If the block is found at least once then add the addendum
                if Counter>0
                    
                    %Tell them you are about to re run a block
                    PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('You are about to re run block %d for %s.\n\n', ChoosenBlock, SelectedExperimentName));
                end
                
                %Always record how many times this block has been run
                BlockNameSuffix=[num2str(ChoosenBlock) '_', num2str(Counter+1)];
                
                
            catch
                % If there was an error then call it block 1
                fprintf('Error in computing block suffix, assuming this is block 1\n');
                BlockNameSuffix=[num2str(ChoosenBlock) '_1']; %Default to run this block for the first time
                
            end
        else
            BlockNameSuffix=[num2str(ChoosenBlock) '_1']; %Default to run this block for the first time
        end
        
        %Ask for confirmation of conditions
        
        if DecidedBlock==0 && JumpToVideo==0 %Only if there are no trials or you haven't specified to jump
            PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('You are running %s on %s for block %d. Would you like to proceed: ''y'' or to reselect: ''n''\n\n', SubjectID, SelectedExperimentName, ChoosenBlock));
            
            %Record a response
            
            %Prep inputs to the listen response
            if isempty(Experiment_str) && isempty(Block_str)
                InputStruct.MaxResponseLength=1;
                DecayStruct.DecayLapse=DecayLapse; %When should the Decay lapse?
                DecayStruct.MostRecentExperiment=MostRecentExperiment; %What is the name of the last experiment run?

                %Listen for a response and store the output
                [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);

                %Add the new TR data. If the scanner isn't on this
                %does nothing
                Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;
                
                %Store the TRs with the last data collected if appropriate
                if ~isempty(MostRecentExperiment.Name)
                    Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
                end
                
            else
                Str='y';
                % Clear these for later
                Experiment_str='';
                Block_str=''; 
            end

            
            if strcmp('v', Str) %If they pressed v then jump to video
                DecayLapse=0; %Set to zero so that you can immediately start the next block. This might not be what you want.
                JumpToVideo=1;
            end
            
        else
            %If the block was decided ahead of time then skip this
            Str='y';
        end
        
        if strcmp(Str, 'y') || strcmp(Str, 'R') %If yes then run, if no then just go back to the top. Treat Return as a yes too
            
            
            %% Initiate the experiment
            
            %If a different experiment is being run, and the time hasn't
            %yet lapsed then run the full decay lapse (by recovering it
            %from)
            if ~isempty(MostRecentExperiment.Name) && ~strcmp(SelectedExperimentName, MostRecentExperiment.Name) && (((DecayLapse-EndTime_GetSecs)*2 + EndTime_GetSecs)-GetSecs)>0
                PrintText_List=Utils_PrintText(Window, PrintText_List,  'Different experiments run consecutively. Waiting full DecayLapse\n\n');
                DecayLapse=(DecayLapse-EndTime_GetSecs)*2 + EndTime_GetSecs;
            end
            
            %Wait for the decay to lapse if necessary
            WaitTime=DecayLapse-GetSecs;
            
            if WaitTime>0 %If this is not negative
                
                %Issue a message about how long you will have to wait
                PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Must wait %0.2f seconds until the next experiment can start\n\nPress any key to return to menu\n\n', WaitTime));
                
                %Loop and listen for pulses
                KbQueueFlush(Window.KeyboardNum);
                while DecayLapse>GetSecs
                    
                    %If there is an experiment to put the TRs to
                    if Window.isfMRI==1
                        
                        TRRecording=Utils_checkTrigger(Window.NextTR, Window.ScannerNum); %Returns the time if a TR pulse happened recently
                        
                        %If there is a recording then update the next TR time and store
                        %this pulse
                        if any(TRRecording>0)
                            
                            %Only store this if there is something to store
                            %into
                            if ~isempty(MostRecentExperiment.Name)
                                Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRRecording))=TRRecording;
                            end
                            
                            Data.Global.Timing.TR(end+1)=TRRecording;
                            Window.NextTR=max(TRRecording)+Window.TR;
                        end
                    end
                    
                    %If there is a response then
                    if KbQueueCheck(Window.KeyboardNum)
                        PrintText_List=Utils_PrintText(Window, PrintText_List,  'Aborted wait for decay to lapse\n\n');
                        LastSecondAborted=1;
                        break
                    else
                        LastSecondAborted=0; %Default to assume it hasn't been aborted
                    end
                    
                end
                
                %Issue a message that you have finished
                PrintText_List=Utils_PrintText(Window, PrintText_List,  'Decay has lapsed\n\n');
                
            else
                LastSecondAborted=0; %Default to assume it hasn't been aborted
            end
            
            %If you aborted during a decaylapse then go back to menu
            if LastSecondAborted==0
                
                % Set the max priority
                Priority(maxPrior);
                
                %Record block start time
                StartTime=datestr(now);
                StartTime_GetSecs=GetSecs;
                PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('Block start time: %s\n\n', StartTime));
                
                % Send message to eye tracker
                Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('About_to_begin_%s_%s_Time:_%0.3f', SelectedExperimentName, sprintf('Block_%s', BlockNameSuffix), GetSecs));
                    
                if Window.isEyeTracking    
                    %If the eye tracker is on, make sure
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  '##CHECK THE EYE TRACKER IS ON##\n\n');
                    PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n          ,.--~=''=~--..\n      .-''  |           |  ''-.\n   ,       | , .---. , |     ''.\n .`       |   |:::::|   |       `.\n  .       |   |:::::|   |      . \n   `.     |  ,  ~~~  ,  |     . \n     `-._  |           |  _.-` \n         ''=~~.._  _..~~=''  \n');
                    
                end
                
                %Run the specified experiment with the appropriate provided code
                Data.(SelectedExperimentName).(sprintf('Block_%s', BlockNameSuffix))=ExperimentNames{SelectedExperiment}(ChoosenBlock, Window, GenerateTrials.(SelectedExperimentName), Data);
                
                %Store the TRs in a global bucket
                Data.Global.Timing.TR(end+1:end+length(Data.(SelectedExperimentName).(sprintf('Block_%s', BlockNameSuffix)).Timing.TR))=Data.(SelectedExperimentName).(sprintf('Block_%s', BlockNameSuffix)).Timing.TR;
                
                %Update the next TR if there are any registerd
                if ~isempty(Data.(SelectedExperimentName).(sprintf('Block_%s', BlockNameSuffix)).Timing.TR)
                    Window.NextTR=Data.(SelectedExperimentName).(sprintf('Block_%s', BlockNameSuffix)).Timing.TR(end) + Window.TR; %Add 1.5s on to the last TR and that is when the next is anticipated
                    
                    %Update whether the scanner is considered on based on when
                    %the last TR was
                    if (GetSecs-Data.Global.Timing.TR(end))<Window.TR
                        Window.ScannerisRunning=1; %Turn it on
                    end
                end
               
                % Send message to eye tracker
                Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Finished_%s_%s_Time:_%0.3f', SelectedExperimentName, sprintf('Block_%s', BlockNameSuffix), GetSecs));
                
                %Store the order that experiments were run, with the start
                %and the end times too
                EndTime_GetSecs=GetSecs; %Save because you want to call this above
                Data.Global.RunOrder(end+1,:)={SelectedExperimentName, sprintf('Block_%s', BlockNameSuffix),...
                    StartTime, StartTime_GetSecs, datestr(now),  EndTime_GetSecs,...
                    Data.(SelectedExperimentName).(sprintf('Block_%s', BlockNameSuffix)).Quit};
                
                
                %Store this so that you can store the TR information
                MostRecentExperiment.Name=SelectedExperimentName;
                MostRecentExperiment.Block=sprintf('Block_%s', BlockNameSuffix);
                
                %Increment the block number if they didn't quit
                if Data.(SelectedExperimentName).(sprintf('Block_%s', BlockNameSuffix)).Quit==0
                    
                    CompletedBlocks.(SelectedExperimentName)(ChoosenBlock)=CompletedBlocks.(SelectedExperimentName)(ChoosenBlock)+1;
                end
                
                %Allow for the ability to skip ahead do the next block
                JustCompletedBlock=1;
                
                %Save the data after every block
                save(svFile);
                
                % aaaaand exhale...
                Priority(origPrior);
                
                PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('Block end time: %s\n\n', datestr(now)));
                
                %Calculate when the next file can start
                
                DecayLapse=Data.(SelectedExperimentName).(sprintf('Block_%s', BlockNameSuffix)).Timing.DecayLapse;
                DecayLapse=(DecayLapse-EndTime_GetSecs)/2 + EndTime_GetSecs; %Automatically halve it since this is the default
            
                JumpToVideo=0; %Assume you are not jumping to the video until told otherwise
            end
        end
    end
    
end

PrintText_List=Utils_PrintText(Window, PrintText_List,   sprintf('Experiment end time: %s\n\n', datestr(now)));

% Send message to eye tracker
Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Finished_experiment:_%0.3f', GetSecs));
Data.Global.Timing.Finish=GetSecs;

%Stop the eye tracker and close the connection
Window.EyeTracking = Utils_EyeTracker_Close(Window.EyeTracking, EyeTracker_save_file);

%Save the data
save(svFile);

%Clear window and hand controls back
sca;
commandwindow;
ListenChar(1);

%Release all of the queues
KbQueueRelease;
fprintf('\n\n----------------------Finishing up-------------------\n\n');

diary off % Turn the diary function off



