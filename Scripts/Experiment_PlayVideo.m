%% Show a movie.
%
% Opens a movie to be played to the infant to capture attention.
% The movie will end if there is a key press. However, the volume buttons
% can still be used and the left and right arrow keys can be used to
% rewind/fastforward
%
% To add movies just put them in the folder:
% 'Stimuli/AttentionGrabberVideos/' and preferably make them small mp4s.
% Sound will play.
%
%First draft 10/30/15 C Ellis
%Added quitting functionality and better video navigation 2/10/16 C Ellis

function Data=Experiment_PlayVideo(varargin)

%Set variables
ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};
    
%Default to assume you aren't waiting
VideoStruct.WaitforTR=Conditions.Parameters.WaitforTR(ChosenBlock);

%Is the rect value a proportion of the screen or in pixels?
if all(Conditions.Parameters.Rect<1)
    
    RectValues([1,3])=Conditions.Parameters.Rect([1,3]).*Window.Rect(3);
    RectValues([2,4])=Conditions.Parameters.Rect([2,4]).*Window.Rect(4);
    
else %If pixels then just use that value
    
    RectValues=Conditions.Parameters.Rect;
end

VideoStruct.MovieRect= RectValues;


%Set no timing constraints
TimingStruct.Preload=Conditions.Parameters.Preload;
TimingStruct.PlannedOnset=0;

%Set the input constraints
InputStruct.isEyeTracking=Window.isEyeTracking; %Is eye tracking being used?
InputStruct.isAnticipationError=Conditions.Parameters.isAnticipationError; %Will a sound be played if there is a key press?

%Make it so a key press terminates the video
InputStruct.isResponseTermination=1;

% Preset
Data.Timing.TR=[];
Data.Quit=0;

%Preset some variables

Data.MovieChoice={};
Data.MovieStartTime=[];

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));

fprintf('\n\n -----------------------Start of Block-------------------------- \n\n');

%Might already need to quit
Quit=Data.Quit;
while Quit==0
    
    %% If there is more than one video then show the options
    PrintText_List = {}; % Preset to empty the list of messages that have been printed
    if length(Conditions.Stimuli.VideoNames)>1
        
        PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('\n\nWhat video would you like to watch.\n\nYour options are:\n\n'));
        
        %Iterate through the different possible functions you can select
        for VideoNamesCounter=1:length(Conditions.Stimuli.VideoNames)
            VideoName=Conditions.Stimuli.VideoNames{VideoNamesCounter}(length(Conditions.Parameters.StimulusDirectory)+1:end);
            
            PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('%d. %s\n', VideoNamesCounter, VideoName));%Print the function name as a string
            
        end
        
        %Print what they have to do
        PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Type the number corresponding to the video you wish to run. If you want to end press ''q''.\nPress enter/return to submit.\n\n'));%Print the function name as a string
        
        %Wait for a valid response
        isValid=0;
        while isValid==0
            
            %Wait for response
            
            %Prep inputs to the listen response
            Resp_InputStruct.MaxResponseLength=ceil(log(length(Conditions.Stimuli.VideoNames)+1)/log(10));
            Resp_InputStruct.ValidResponse='q';
            Resp_InputStruct.InvalidResponse='q';
            DecayStruct.DecayLapse=inf; %When should the Decay lapse?
            
            %Listen for a response and store the output
            
            [Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, Resp_InputStruct);
            
            %Store TRs
            Data.Timing.TR(end+1:end+length(TRData))=TRData;
           
            
            if ~isnan(str2double(Str)) && ~isempty(find(str2double(Str)==1:length(Conditions.Stimuli.VideoNames)))
                ChoosenVideo=str2double(Str);
                isValid=1;
            elseif strcmp(Str, 'q')
                isValid=1;
                Quit=1;
            else
                PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('%s is an invalid input.\n\n', Str));%Print the function name as a string
                
               
            end
        end
        
    else
        ChoosenVideo=1;
        
        %If this is the first time loaded then play immediately, otherwise
        %ask whether you want it to be replayed.
        
        if isfield(Data.Timing, 'Movie_1')==1
            
            %After it has finished ask whether to replay
            PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('\n\nWould you like to replay (y) or quit (q)?\n\n'));
            
            %Wait for a valid response
            isValid=0;
            while isValid==0 
                
                %Wait for response
                
                %Prep inputs to the listen response
                InputStruct.MaxResponseLength=ceil(log(length(Conditions.Stimuli.VideoNames))/log(10));
                DecayStruct.DecayLapse=inf; %When should the Decay lapse?
                
                %Listen for a response and store the output
                [Str, TRData, Window.ScannerisRunning]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);
                
                %Store TRs
                Data.Timing.TR(end+1:end+length(TRData))=TRData;
                
                
                %Interpret the response
                if strcmp(Str, 'y')
                    isValid=1;
                elseif strcmp(Str, 'q')
                    isValid=1;
                    Quit=1;
                else
                    PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('%s is an invalid input.\n\n', Str));
                   
                end
            end
            
        end
        
    end
    
    %If you aren't quiting then skip this
    if Quit==0
        
        %What is the name of the stim selected
        ChoosenStim=Conditions.Stimuli.VideoNames{ChoosenVideo}(length(Conditions.Parameters.StimulusDirectory)+1:end);
        
        PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Playing movie: %s\n\n', ChoosenStim));
        
        %Since you need the base extension for whatever reason here it is
        VideoStruct.VideoNames=[Conditions.Parameters.BaseExt, Conditions.Stimuli.VideoNames{ChoosenVideo}(4:end)];
        
        
        % Start recording but only if you are also collecting fMRI data
        if VideoStruct.WaitforTR == 1
            Utils_EyeTracker_TrialStart(Window.EyeTracking);
        end
        
        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Movie_Start_Time:_%0.3f', GetSecs));
            
        %Decide at what time to start the movie from
        if ChosenBlock==1 %Means you are starting from where it was last started
            
            if length(Data.MovieChoice)>0 && sum(cell2mat(strfind(Data.MovieChoice, ChoosenStim)))>0 %If there is at least one movie and the choosen name has previously been used then allocate the specified value
                
                % What cells contain this string
                MatchIdx=strfind(Data.MovieChoice, ChoosenStim);
                
                % Iterate through the cells and store the max idx of them
                for Counter=1 : length(MatchIdx)
                    if MatchIdx{Counter}(:)==1
                        Idx= Counter;
                    end
                end
                
                VideoStruct.MovieWatched= Data.Responses.(sprintf('Movie_%d', Idx)).MovieElapsed; %How much of the movie has been run
            
            else 
                VideoStruct.MovieWatched=0;
            end
        else
            VideoStruct.MovieWatched=0;
        end
        
        
        %Store the video name with the starting time
        Data.MovieChoice{end+1}=ChoosenStim;
        Data.MovieStartTime(end+1)=GetSecs;
        
        %What movie number is this?
        MovieCounter=length(Data.MovieStartTime);
        
        
        %Store the video struct information. Do so just before playing so
        %that Window.NextTR is up to date
        VideoStruct.window=Window;

        [Data.Timing.(sprintf('Movie_%d', MovieCounter)), Data.Responses.(sprintf('Movie_%d', MovieCounter)), Data.GazeData.(sprintf('Movie_%d', MovieCounter))]=Utils_PlayAV(VideoStruct, [], TimingStruct, InputStruct); %Plays the movie
        
        
        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Movie_Stop_Time:_%0.3f', GetSecs));
        if VideoStruct.WaitforTR == 1
            Utils_EyeTracker_TrialEnd(Window.EyeTracking);
        end
        
        %If the experimenter pressed q during the presentation then return
        if Data.Responses.(sprintf('Movie_%d', MovieCounter)).Quit==1 
            Quit=1;
            
            %Record whether that this was quit preemptively
            Data.Quit=1;
            PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('\nBlock Terminated\n\n'));
            
        elseif VideoStruct.WaitforTR==1
            
            Quit=1;
            PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('\nExiting experiment because movie has finished\n\n'));
            
            %Once the movie has finished quit but don't record it as a quit
            Data.Quit=0;
        end
        
        
        %Append the TR values to the list that grows with every movie
        if Window.isfMRI && ~isempty(Data.Timing.(sprintf('Movie_%d', MovieCounter)).TR)
            Data.Timing.TR=[Data.Timing.TR, Data.Timing.(sprintf('Movie_%d', MovieCounter)).TR];
            Window.NextTR=Data.Timing.TR(end);
        end
        
        PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('\n\nMovie end'));
    end
    
    
end

Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('End_of_Block_Time:_%0.3f', GetSecs));

fprintf('\n\n -----------------------End of Block-------------------------- \n\n');



%How long must the console wait before the next sequence can run? Prep it
%only if you waited for the TR at the start
if VideoStruct.WaitforTR
    Data.Timing.DecayLapse=Conditions.Parameters.DecayLapse+GetSecs;
else
    Data.Timing.DecayLapse=GetSecs;
end
