%% Show a movie.
%
% Opens a movie to be played to the infant to capture attention.
% The movie will end if there is a key press. However, the volume buttons
% can still be used and the left and right arrow keys can be used to
% rewind/fastforward
%
%
% L. Skalaban First draft 07/21/2017
% Various updates by C Ellis and T Yates spring 2019
% Clean version 05/2021 

function Data=Experiment_MM(varargin)

%Set variables
ChosenBlock=varargin{1};
Window=varargin{2};
Conditions=varargin{3};

% Decide whether you are waiting for TR based on whether you are connected
% to the scanner
VideoStruct.WaitforTR=Window.isfMRI;

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

% Preset
Data.Timing.TR=[];
Data.Quit=0;
Quit=Data.Quit;

%Preset some variables

Data.MovieChoice={};
Data.MovieStartTime=[];

while Quit == 0
    
    PresentationOrder = Conditions.Parameters.FinalStimuli;

    %Put both the block names and stimuli directories in same place so they can
    %be iterated through 
    PresentationOrder(2,:) = Conditions.Parameters.BlockNames;

    Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Start_of_Block_Time:_%0.3f', GetSecs));
    
    fprintf('\n\n -----------------------Start of Block-------------------------- \n\n');

    ChosenVideo= PresentationOrder(1,ChosenBlock);

    %If you aren't quiting then skip this
    if Quit==0

        %What is the name of the stim selected
        ChosenStim={ChosenVideo{1}(4:end)};

        fprintf('Playing movie: \n\n');

        %Since you need the base extension for whatever reason here it is
        %concatenate strings
        Connected = strcat(Conditions.Parameters.BaseExt,ChosenStim);
        
        %store here
        VideoStruct.VideoNames=Connected;
        VideoStruct.VideoNames=char(VideoStruct.VideoNames);


        %Issue message

        Window.EyeTracking = Utils_EyeTracker_Message(Window.EyeTracking, sprintf('Movie_Start_Time:_%0.3f', GetSecs));
        if VideoStruct.WaitforTR == 1
            Utils_EyeTracker_TrialStart(Window.EyeTracking);
        end
        
        VideoStruct.MovieWatched=0;
            
        %Store the video name with the starting time
        Data.MovieChoice{end+1}=ChosenStim;
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
        if (Data.Responses.(sprintf('Movie_%d', MovieCounter)).Quit == 1) 
            Quit=1;

            %Record whether that this was quit preemptively
            Data.Quit=1;
            fprintf('\nBlock Terminated\n\n');

        else
            Quit=1;
            fprintf('\nExiting experiment because movie has finished\n\n');

            %Once the movie has finished quit but don't record it as a quit
            Data.Quit=0;
        end


        %Append the TR values to the list that grows with every movie
        if Window.isfMRI && ~isempty(Data.Timing.(sprintf('Movie_%d', MovieCounter)).TR)
            Data.Timing.TR=[Data.Timing.TR, Data.Timing.(sprintf('Movie_%d', MovieCounter)).TR];
            Window.NextTR=Data.Timing.TR(end);
        end

        fprintf('\n\nMovie end');
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
end
    