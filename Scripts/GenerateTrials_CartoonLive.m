%% Generate Trial sequence and conditions for Cartoon vs. Realistic Movies Experiment
%
% Loads cartoon and live versions of a movie and puts them in a different
% order
%
% Script based off of PlayVideo, MM, etc.
%
% TY 01/26/2022

function TrialStructure=GenerateTrials_CartoonLive(varargin)


% In case no inputs are given
if nargin > 0
    Window = varargin{4};
else
    Window.ppd = 30;
    Window.centerX = 500;
    Window.centerY = 500;
end

Randomise=1; % Do you want to allow the user to choose the order of videos to show (0) or randomly determine the order? 

Parameters.BaseExt=cd; %What is the current folder directory name
Parameters.BaseExt=Parameters.BaseExt(1:max(find(Parameters.BaseExt=='/'))); %Remove the current folder

Parameters.StimulusDirectory='../Stimuli/CartoonLive/'; %Where are the video stimuli stored?

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

Temp=dir([Parameters.StimulusDirectory, '*.mp4']); %What files are in the video directory

DirNames=Temp(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp)); %Remove all hidden files

for FileCounter=1:length(DirNames)
    
    if ~isempty(strfind(DirNames(FileCounter).name,'Cartoon')) && isempty(strfind(DirNames(FileCounter).name,'Live')) % if it is the cartoon version
    
        %Store the movie names
        Stimuli.cartoonNames{FileCounter}=[Parameters.StimulusDirectory, DirNames(FileCounter).name]; 
        
    elseif ~isempty(strfind(DirNames(FileCounter).name,'Live')) && isempty(strfind(DirNames(FileCounter).name,'Cartoon')) % if it is the live version
        
        %Store the movie names
        Stimuli.liveNames{FileCounter}=[Parameters.StimulusDirectory, DirNames(FileCounter).name]; 
    end
    
end

% Now get rid of the empty arrays in there
Stimuli.cartoonNames=Stimuli.cartoonNames(~cellfun(@isempty,Stimuli.cartoonNames));
Stimuli.liveNames=Stimuli.liveNames(~cellfun(@isempty,Stimuli.liveNames));


% Do a check
if length(Stimuli.cartoonNames) ~= length(Stimuli.liveNames)
    warning('There are not equivalent numbers of cartoon and live movies, this will cause issues in counterbalancing. Aborting.')
    return  
end

all_stim_names=horzcat(Stimuli.cartoonNames,Stimuli.liveNames);

% If you don't randomise, the user must choose the condition
if Randomise==0

    % Ask what condition you want to use
    fprintf('\nWhich counterbalancing condition would you like to use? Press a key to continue, or "q" to quit\n')
    fprintf(' 1: Cartoon, Live\n 2: Live, Cartoon\n')   

    % wait until a valid option
    cond_order=-1;
    while cond_order==-1

        pause(0.2);
        KbName('UnifyKeyNames');
        [~, keyCode]=KbWait(Window.KeyboardNum);

        % choose the condition order
        if strfind(KbName(keyCode), '1')==1
            cond_order=[1,2]; % Cartoon, Live
            order_name='Cartoon - Live';
            
        elseif strfind(KbName(keyCode), '2')==1
            cond_order=[2,1]; % Live, Cartoon
            order_name='Live - Cartoon';

        elseif strfind(KbName(keyCode), 'q')==1
           fprintf('\nquitting\n')
            TrialStructure = [];
           return; 

        else
            fprintf('\nPlease choose a valid option\n')

        end

        pause(0.2);
    end

    fprintf('\nUsing counterbalancing condition %s\n',order_name)

% Else, randomise the order 
else
    fprintf('\n Randomising the video order\n')
    
    if rand > 0.5
        cond_order=[1,2];
        order_name='Cartoon - Live';
    else
        cond_order=[2,1];
        order_name='Live - Cartoon';
    end
    
    fprintf('\nUsing counterbalancing condition %s\n',order_name)

end

% Order! 
Both_ordered = {};

for condition_counter=cond_order
    Both_ordered{end+1}=all_stim_names{condition_counter};
end

% save this out ! 
Parameters.FinalStimuli = Both_ordered;

% Iterate through the blocks and store them based on their name
Parameters.BlockNames = {};
for movie_path = Both_ordered
    
    % Pull out just the movie name
    movie_name = movie_path{1}(max(strfind(movie_path{1}, '/')) + 1:end-4);
    
    % Store the name of the block
    Parameters.BlockNames{end + 1} = movie_name;
end

Parameters.BlockNum=length(Parameters.BlockNames); % How many blocks are there

%Store these
TrialStructure.Parameters=Parameters;
TrialStructure.Stimuli=Stimuli;


end