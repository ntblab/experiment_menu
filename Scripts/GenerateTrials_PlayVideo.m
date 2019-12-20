%% Generate Trial sequence and conditions for the Play Video

%Generate the appropriate trial sequence with randomization for a number of
%blocks in the narrowing/localizer experiment

%C Ellis 9/25/15

function TrialStructure=GenerateTrials_PlayVideo(varargin)

Window = varargin{4};

%Set up the parameters of the experiment

Parameters.BaseExt=cd; %What is the current folder directory name
Parameters.BaseExt=Parameters.BaseExt(1:max(find(Parameters.BaseExt=='/'))); %Remove the current folder

Parameters.StimulusDirectory='../Stimuli/AttentionGrabberVideos/'; %Where are the stimuli stored?

Parameters.BlockNum=3; %These actually represent two modes of interacting with the experiment

%Save these names so they can be used in the menu. Remember blocks
%indicate different ways of interacting with the experiment
Parameters.BlockNames={'Movies resume from where most recently run', 'Movies restart every call', 'Wait for TRs at the start of the experiment'};

Parameters.WaitforTR=[0,0,1]; %On what blocks should you wait for a TR?

Parameters.Preload=0; %Would you like to preload the textures before playing the movie?

Parameters.isAnticipationError=0; %Don't receive responses
 
Parameters.DecayLapse=12; %How many seconds will you wait for

% Specify the movie size for each block type
ppd_width=[22.75*2, 22.75, 22.75];% When we originally ran these movies at Princeton we made them 20% of the screen size, which comes out to 22.75 x 12.75 visual degrees. For preservation, the visual angle has been preserved for these analyses. If a movie is not 16:9 then it will be stretched
ppd_height=[12.75*2, 12.75, 12.75];
for block_counter = 1:Parameters.BlockNum
    x_width = ppd_width(block_counter)/2 * Window.ppd;
    y_width = ppd_height(block_counter)/2 * Window.ppd;
    Parameters.Rect{block_counter}=[Window.centerX - x_width, Window.centerY - y_width, Window.centerX + x_width, Window.centerY + y_width];
end

% Get all of the files in this directory

Temp=dir(Parameters.StimulusDirectory); %What files are in the directory
DirNames=Temp(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp)); %Remove all hidden files

% If you don't have any files then download an example movie you could use
if length(DirNames) == 0
    PrintText_List={};
    PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Could not find a movie file in %s. Instead downloading the open-source Big Buck Bunny (Blender studios) movie from the internet for use, Be aware, this movie might not be appropriate for young children.\n\nThis may take a few minutes (or may crash immediately if the link is broken or there is no internet connection) ....\n', Parameters.StimulusDirectory));
    
    % Make the directory if it doesn't exist
    if exist(Parameters.StimulusDirectory) == 0
        mkdir(Parameters.StimulusDirectory);
    end
    
    % Load the data
    try

        urlwrite('https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4', [Parameters.StimulusDirectory, 'BigBuckBunny.mp4'])

        PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Finished downloading\n'));
    catch
        PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Failed to load the data\n'));
    end
    
    % Refind what is contained in the stimulus folder
    Temp=dir(Parameters.StimulusDirectory); %What files are in the directory
    DirNames=Temp(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp)); %Remove all hidden files

end


for FileCounter=1:length(DirNames)
    
    %Store the movie names
    Stimuli.VideoNames{FileCounter}=[Parameters.StimulusDirectory, DirNames(FileCounter).name]; 
    
end



%Store these

TrialStructure.Parameters=Parameters;

TrialStructure.Stimuli=Stimuli;
