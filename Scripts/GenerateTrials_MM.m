%% Generate Trial sequence and conditions for Movie Memory Experiment
%
% Generate the appropriate trial sequence with randomization for Movie
% Memory Experiment
%
% Movies and their names are not provided because of copyright, but interested individuals should reach out for a copy 
%
% Re-designed and rewritten 9/19/2017
% Edited spring 2019
% Clean version 05/2021

function TrialStructure=GenerateTrials_MM(varargin)
  
% In case no inputs are given
if nargin > 0
    Window = varargin{4};
else
    Window.ppd = 30;
    Window.centerX = 500;
    Window.centerY = 500;
end

%Set up the parameters of the experiment

Parameters.BaseExt=cd; %What is the current folder directory name
Parameters.BaseExt=Parameters.BaseExt(1:max(find(Parameters.BaseExt=='/'))); %Remove the current folder

Parameters.StimulusDirectory_Full='../Stimuli/MovieMemory/3mins/Full/'; %Where are the video stimuli stored?
Parameters.StimulusDirectory_Dropped='../Stimuli/MovieMemory/3mins/Dropped/'; %Where are the audio only stimuli stored?

Parameters.Preload=0; %Would you like to preload the textures before playing the movie?
 
Parameters.DecayLapse=12; %How many seconds will you wait for

%Specify the 4 values that define the rectangle of the movie. If the values
%are above zero then they will be treated as pixels, if below zero then it
%will be treated as proportion of the screen
%Parameters.Rect= [0.2, 0.2, 0.8, 0.8];
ppd_width=22.75*2;% When we originally ran these movies at Princeton we made them 20% of the screen size, which comes out to 22.75 x 12.75 visual degrees. For preservation, the visual angle has been preserved for these analyses. If a movie is not 16:9 then it will be stretched
ppd_height=12.75*2;
x_width = ppd_width/2 * Window.ppd;
y_width = ppd_height/2 * Window.ppd;
Parameters.Rect=[Window.centerX - x_width, Window.centerY - y_width, Window.centerX + x_width, Window.centerY + y_width];

%Set up the stimuli for the experiment

Temp1=dir([Parameters.StimulusDirectory_Full, '*.mp4']); %What files are in the video directory

Temp2=dir([Parameters.StimulusDirectory_Dropped, '*.mp4']); %What files are in the audio directory

DirNames_1=Temp1(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp1)); %Remove all hidden files
DirNames_2=Temp2(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp2)); %Remove all hidden files

% preset
Stimuli.FullNames={};
Stimuli.DroppedNames={};

Missing_folder=0; % preset to say that neither stimulus dir is empty

%Store the movie names
for FileCounter=1:length(DirNames_1) 
    Stimuli.FullNames{FileCounter}=[Parameters.StimulusDirectory_Full, DirNames_1(FileCounter).name]; 
end

for FileCounter=1:length(DirNames_2)
    Stimuli.DroppedNames{FileCounter}=[Parameters.StimulusDirectory_Dropped, DirNames_2(FileCounter).name]; 
end

% If the folders are empty, give a warning
if isempty(DirNames_1) && isempty(DirNames_2)
    warning('Movie directories are empty, cannot run this experiment. If you do not have access to the stimuli, contact the authors for a copy.')
    TrialStructure=[];
    return
elseif isempty(DirNames_1)
    warning('Movie directory for Full (intact) movies is empty.')
    Missing_folder=1; % set to 1 to indicate full is missing
elseif isempty(DirNames_2)
    warning('Movie directory for Dropped (disrupted) movies is empty.')
    Missing_folder=2; % set to 2 to indicate full is missing
end

% Do a check to see if the directories are the same length, if there are
% files in both of the directories
if length(Stimuli.FullNames) ~= length(Stimuli.DroppedNames) && Missing_folder==0
    warning('There are not equivalent numbers of Full and Dropped movies, this will cause issues in counterbalancing. Specifically, movies may not be shown in Full/Dropped pairs as expected.')
end

% First iterate through the list of forced names
Both_ordered = {};

% Make an array of movie by full vs dropped to represent what movies are
% available for use (based on the folder with more files)
if length(Stimuli.FullNames) >= length(Stimuli.DroppedNames)
    available_movies = ones(length(Stimuli.FullNames), 2); 
else
    available_movies = ones(length(Stimuli.DroppedNames), 2); 
end

% Specify any ordering that you want to enforce, otherwise the rest will be
% randomly organized
forced_movie_order_names = {'Full_Pilot', 'Drop_Pilot'};

% Excluded movie names
excluded_movies = {'Dragonboy', 'Dustbunnies'};

% Cycle through the forced movie order
for movie_name = forced_movie_order_names
    try
        movie_path = movie_name{1}(strfind(movie_name{1}, '_') + 1:end);
        if strfind(movie_name{1}, 'Full')
            movie_idx = find(cellfun(@isempty, strfind(Stimuli.FullNames, movie_path)) == 0);
            Both_ordered{end+1} = Stimuli.FullNames{movie_idx};
            
            % Remove this item from the list
            available_movies(movie_idx, 1) = 0;
            
        else
            movie_idx = find(cellfun(@isempty, strfind(Stimuli.DroppedNames, movie_path)) == 0);
            Both_ordered{end+1} = Stimuli.DroppedNames{movie_idx};
            
            % Remove this item from the list
            available_movies(movie_idx, 2) = 0;
        end
    catch
        warning('%s is not located in its corresponding movie directory, cannot force it into the movie order.',movie_name{1})
    end
    
end

% Now exclude the movies that should not be run, if they are present in the
% movie directory
for movie_name = excluded_movies
        
    % Remove this item from both lists
    movie_idx = find(cellfun(@isempty, strfind(Stimuli.FullNames, movie_name{1})) == 0);
    movie_idx = find(cellfun(@isempty, strfind(Stimuli.DroppedNames, movie_name{1})) == 0);
    available_movies(movie_idx, :) = 0;
end
    
% With the remaining movies, shuffle the order of all movies (even the ones
% you might have set) and then alternate between dropped and on but only do
% so if they have not been used already

% first, set the movie order based on the stimulus folder with more movies,
% to ensure that you show all of the stimuli in case its unbalanced
if length(Stimuli.FullNames) >= length(Stimuli.DroppedNames)
    movie_order = Shuffle(1:length(Stimuli.FullNames));
else
    movie_order = Shuffle(1:length(Stimuli.DroppedNames));
end

for movie_idx = movie_order

    % Flip a coin as to what the order is for the presentations of dropped
    % and full
    if rand<0.5
        
        % Put the Full movie first (if it hasn't already been used, and if there are movies in this folder)
        if available_movies(movie_idx, 1) == 1 && Missing_folder~=1 && movie_idx <= length(Stimuli.FullNames)
            Both_ordered{end+1} = Stimuli.FullNames{movie_idx};
        end
        
        if available_movies(movie_idx, 2) == 1 && Missing_folder~=2  && movie_idx <= length(Stimuli.DroppedNames)
            Both_ordered{end+1} = Stimuli.DroppedNames{movie_idx};
        end
        
    else
        
        % Put the Dropped movie first (if it hasn't already been used, and if there are movies in this folder)
        if available_movies(movie_idx, 2) == 1 && Missing_folder~=2 && movie_idx <= length(Stimuli.DroppedNames)
            Both_ordered{end+1} = Stimuli.DroppedNames{movie_idx};
        end
        
        if available_movies(movie_idx, 1) == 1 && Missing_folder~=1 && movie_idx <= length(Stimuli.FullNames)
            Both_ordered{end+1} = Stimuli.FullNames{movie_idx};
        end
        
    end
    
end

Parameters.FinalStimuli = Both_ordered;

% Iterate through the blocks and store them based on their name
Parameters.BlockNames = {};
for movie_path = Both_ordered
    
    % What folder is this movie in
    if ~isempty(strfind(movie_path{1}, '/Full/'))
        condition_name = 'Full_';
    else
        condition_name = 'Drop_';
    end
    
    % Pull out just the movie name
    movie_name = movie_path{1}(max(strfind(movie_path{1}, '/')) + 1:end-4);
    
    % Store the name of the block
    Parameters.BlockNames{end + 1} = [condition_name, movie_name];
end

Parameters.BlockNum=length(Parameters.BlockNames); % How many blocks are there

%Store these
TrialStructure.Parameters=Parameters;
TrialStructure.Stimuli=Stimuli;
