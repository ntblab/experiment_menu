
%% Generate Trial sequence and conditions for the memory Experiment

%Adapted from "Generate Trial sequence and conditions for a Live Action
%Movie Experiment"

% Generate the appropriate trial sequence with randomization for Daniel
% Tiger Children Playing movies
%
% Practically the same script as GenerateTrials_MM.m
% Except the block order is completely forced 
%
% SC 03/15/21
% LB for clairity 10/13/26

function TrialStructure=GenerateTrials_Saycam(varargin)

%% Start by determining whether to load or to generate the trial struct.

% Set the base extension.
Parameters.BaseExt = cd; %What is the current folder directory name
Parameters.BaseExt = Parameters.BaseExt(1:max(find(Parameters.BaseExt=='/'))); %Remove the current folder

% Load the LT square which has a presentation order for each of the 20
% sets. Created for the first participant and then loaded in so that the
% order is the same for the second participant.
LTsquarefile = fullfile(Parameters.BaseExt,'/Scripts/Saycam/LTsquare_rand_saycam.mat');
load(LTsquarefile);

% Trial struct that will only exist if this is the second kid.
trialstructfile = fullfile(Parameters.BaseExt,'/Data/Saycam/Saycam_trialstructure.mat');

% If this is the second kid, load and use the existing trial struct.
if exist(trialstructfile, 'file') == 2
   load(trialstructfile);

   fprintf('\n\n-----------------------Loading trialstruct--------------------------\n\n');

% Otherwise, this is the first kid, so let's generate the trials.
elseif exist(trialstructfile, 'file') == 0

   fprintf('\n\n-----------------------Generating a new trialstruct--------------------------\n\n');

% In case no inputs are given.
if nargin > 0
    Window = varargin{4};
else
    Window.ppd = 30;
    Window.centerX = 500;
    Window.centerY = 500;
end

%% Set up the parameters of the experiment.

Parameters.BaseExt = cd; % What is the current folder directory name?
Parameters.BaseExt = Parameters.BaseExt(1:max(find(Parameters.BaseExt == '/'))); % Remove the current folder.

Parameters.StimulusDirectory = fullfile(Parameters.BaseExt, '/Stimuli/Saycam/'); % Where are the video stimuli stored?

Parameters.Preload = 0; % Would you like to preload the textures before playing the movie?
 
Parameters.DecayLapse = 0; % How many seconds will you wait for decay?

tmp = dir(fullfile(Parameters.StimulusDirectory,'A_PC')); % Select a random stimuli folder.
tmp = tmp(arrayfun(@(x) ~strcmp(x.name(1),'.'),tmp)); % Remove the hidden files.
Parameters.numpseudoblocks = length(tmp); % How many files are in this stimuli folder?

%Specify the 4 values that define the rectangle of the movie. If the values
%are above zero then they will be treated as pixels, if below zero then it
%will be treated as proportion of the screen
%Parameters.Rect = [0.2, 0.2, 0.8, 0.8];

% When we originally ran these movies at Princeton we made them 20% of the screen size, which comes out to 22.75 x 12.75 visual degrees. For preservation, the visual angle has been preserved for these analyses. 
%If a movie is not 16:9 then it will be stretched or compressed
%For these movies, the resolution is 1280:800 (instead of 1280:720)
%So we will edit the width to be the appropriate size given the height 
ppd_width = 12.75 * 4/3 *2;
ppd_height = 12.75 * 2;
x_width = ppd_width/2 * Window.ppd;
y_width = ppd_height/2 * Window.ppd;
Parameters.Rect = [Window.centerX - x_width, Window.centerY - y_width, Window.centerX + x_width, Window.centerY + y_width];

clear tmp

%% Create stimuli structure.

% Pre-set known info.
stim_dir = Parameters.StimulusDirectory;
video_ext = 'mp4'; 

% What are all of the posisble conditions?
fullcondtype = {'A_PC', 'A_Real', 'A_RV','Y_PC','Y_Real','Y_RV'}; 

% How many conditions are there?
N = length(fullcondtype);

% Extract the trial sequences from the LT square file.
TrialSequences = M;

% Set up the ITIs.
ITIcat = [6, 8, 10, 6, 8, 6]; % These are the 6 ITI values present in every set.
ITIs = [];

% For each of the 20 sets randomize the ITI order.
for e = 1:Parameters.numpseudoblocks
    tmpi = Shuffle(ITIcat);
    ITIs = [ITIs;tmpi];
end

% For each of the 20 sets, select the stimuli.
for pseudoblock = 1:Parameters.numpseudoblocks

    % Pull out the order for this set that had been listed in the LT square file.
    curr_rc = TrialSequences(:,pseudoblock);

    % Pre-allocate the stimulus field.
    Stimuli.(sprintf('set_%s',num2str(pseudoblock))) = cell(6,1);

    % For each of the six possible conditions, 
    for i = 1:length(fullcondtype)

        % Isolate tha condition's folder and the videos contained within.
        condtype=fullcondtype{i};
        tmpdir = fullfile(stim_dir, condtype);
        tmpfull=dir([tmpdir, '/*.mp4']);
        tmpfull=tmpfull(arrayfun(@(x) ~strcmp(x.name(1),'.'),tmpfull));

        % Pick the first one in each row.
        % Thus, to randomize, select different block numbers during presentation (e.g. block 1-20)
        tmp=tmpfull(pseudoblock);
        video_name=tmp(arrayfun(@(x) ~strcmp(x.name(1),'.'),tmp));
        x=[tmpdir,'/',video_name.name];
        
        % Save the selected stimulus information.
        Stimuli.(sprintf('set_%s',num2str(pseudoblock))){curr_rc(i)} = x;
        Stimulitype{curr_rc(i),pseudoblock}=condtype;
        Stimulitype_vidname{curr_rc(i),pseudoblock}=video_name.name; %col is pseudoblock

    end
end

% Randomize the stimulus set order.
% Will only work of there are full set of stimuli (i.e., 20)
if Parameters.numpseudoblocks == 20
     
    % Start with each of the 20 possible sets: reshape, shuffle, and save.
    t=(reshape([1:20],[5,4]))';
    for i=1:size(t,1)
        t(:,i)=Shuffle(t(:,i));
    end
    orders=reshape(t,[20,1]);

    % Re-order the sets based on the shuffled order and save.
    for i=1:20
        ordernames{i}=sprintf('set_%d', orders(i));
    end
    Stimuli = orderfields(Stimuli, ordernames);

end

%% Save everything you might need.

%i think this is the 'block'?
Parameters.FinalStimuli = Stimuli;
Parameters.Stimulitype_cell=Stimulitype;
Parameters.Stimulitype_vidname=Stimulitype_vidname;
Parameters.TrialSequences =TrialSequences;
Parameters.ITIs=ITIs;
Parameters.orders=orders;

% Iterate through the blocks and store them based on their name.
Parameters.BlockNames = {};
for BlockCounter =1:Parameters.numpseudoblocks
    Parameters.BlockNames{BlockCounter}= sprintf('set_%d', orders(BlockCounter));
end
 
% Save the number of blocks.
Parameters.BlockNum=length(Parameters.BlockNames); 

% Store what you need to run this experiment.
TrialStructure.Parameters=Parameters;
TrialStructure.Stimuli=Stimuli;

% Find/create a directory to save the trial struct.
savedir = fullfile(Parameters.BaseExt,'/Data/Saycam');
    if ~exist(savedir, 'dir')
       mkdir(savedir)
    end

% Save the resulting trial structure so it can be loaded for the second kid.
savename = fullfile(savedir, 'Saycam_trialstructure.mat');
save(savename, 'TrialStructure')

end
