%% Generate Trial sequence and conditions for retinotopy
%
%Generate the appropriate randomized block order for carrying out
%retinotopy. The default parameters for this script are set to run the meridian
% mapping and spatial frequency blocks of the retinotopy experiments.
%
% DISCLAIMER, this is a frankenstein script and will likely be very hard to
% read. First it was written by two people (first Vikranth Bejjanki and
% then Cameron Ellis) and has become very convoluted. This is because this
% same script was adapted for different iterations of retinotopy
% experiments (some with infants, some with adults). Indeed, since much of
% the functionality of this script is legacy, many of the alternative
% parameters shouldn't expected to run because of missing files.
% Nonetheless it was included to ensure that the script made public is the
% same script that we used, in case there are any bugs (hope there is not!)
%
%V Bejjanki 2/12/16

function TrialStructure=GenerateTrials_Retinotopy(varargin)

Parameters.NumConditions = 4; %Four types of retinotopy runs -> 'cw';'ccw';'in';'out' or 'horizontal';'vertical';'highlow';'lowhigh' ;

Parameters.NumRunsPerCondition = 4;

Parameters.NumRepetitions = 1;  %How many repetitions of the conditions per block

Parameters.BlockNum = Parameters.NumConditions*Parameters.NumRunsPerCondition;

Parameters.MovieDirectory = [pwd, '/../Stimuli/RetinotopyStimuli/']; %Where are the videos stored

Parameters.AttentionTask=0; % Do you want an attention task to be going on during the experiment?

Parameters.FixationStimulus=1;          % What do you want as the fixation stimulus: 0) none, 1) Movie, 2) Faces

Parameters.Fix_motion_envelope = 5; % How many visual degrees do you want the central fixation to move over    

Parameters.Fix_motion_frequency = 0.1; % At what frequency is the fixation oscillating (

if  Parameters.FixationStimulus == 1
    Parameters.MovieName=[Parameters.MovieDirectory, 'Shapes_contrast_0.5.mp4']; %What movie do you want to display
%     
%     Temp=VideoReader(Parameters.MovieName); %load the movie
%     
    Parameters.MovieLength=231;            % How long is the movie
end

Parameters.DecayLapse=12; %How long is the decay lapse

Parameters.TravellingWave=0; % How is retinotopy created: travelling wave or meridian mapping/eccentricity mapping

Parameters.StimulusDirectory = '../Stimuli/RetinotopyStimuli/'; %Location of images used in retinotopy

Parameters.SFDirectory = '../Stimuli/Retinotopy_SF/'; %Location of images used in retinotopy

Parameters.fmask_size=2.25;            % Radius of black mask around fixation in degrees or the movie stimulus

Parameters.iswedge = 1; % Do you want to specify a wedge shape

%Specify experiment type specific information

if Parameters.TravellingWave==1
    block_Labels = {'cw';'ccw';'in';'out'};
    
    
    Parameters.rot_period =  32;           % rotation period of wedge or ring
    
    Parameters.Redundancy =  10;           % How much extra time will you sample
    
    Parameters.cut_out=       0;           % cut out n deg (radius) of center
    
    Parameters.cut_in=       14;           % cut in n deg (radius) from outer max; equals max eccen of wedge
    
    Stimuli=[]; %Because it is required
elseif Parameters.TravellingWave==0
    
    block_Labels = {'horizontal_first';'vertical_first';'highlow';'lowhigh'};
    
    Parameters.rot_period =  40;           % How long is each block
    
    Parameters.Redundancy =  0;           % How much extra time will you sample
    
    Parameters.Stim_Repetitions = 8;      % How many times does each stim repeat?
    
    Parameters.cut_out=       0;           % cut out n deg (radius) of center
    
    Parameters.cut_in=       40;           % cut in n deg (radius) from outer max; equals max eccen of wedge
    
    Parameters.fmask_size=   1.5;              % What is the width of the lines?
    
    Parameters.NumRepetitions = 1;  %One repetition of each
    
    % Store all of the names of the stimuli in an easily accessed format
    %CyclesPerDeg = [3, 2, 1, .8, .5, .4, .2, .1]; 
    CyclesPerDeg = [60/Parameters.cut_in, 0, 0, 0, 0, 0, 0, 2/Parameters.cut_in]; % Using this your Cycles per degree are now wrong but it allows you to use an arbitrary image

    for cycle_counter = 1:length(CyclesPerDeg)
        StimNames= dir(sprintf('%sCyc%d_*', Parameters.SFDirectory, CyclesPerDeg(cycle_counter)*Parameters.cut_in));
        
        for stim_counter = 1:length(StimNames)
            Stimuli.StimNames{stim_counter, cycle_counter} = StimNames(stim_counter).name;
        end
    end
    
    Parameters.Stim_Duration= Parameters.rot_period/(numel(Stimuli.StimNames) * Parameters.Stim_Repetitions);

elseif Parameters.TravellingWave==-1
    
    block_Labels = {'radial_low_freq'; 'radial_high_freq'};
    
    Parameters.BlockNum=length(block_Labels); % Override
    
    Parameters.check_rows = 3;
    
    Parameters.check_wedges = 4;
    
    Parameters.rot_period =  360;           % How long is each block
    
    Parameters.Redundancy =  0;           % How much extra time will you sample
    
    Parameters.Stim_Repetitions = 2;      % How many times does each stim repeat?
    
    Parameters.cut_out=       0;           % cut out n deg (radius) of center
    
    Parameters.cut_in=       10;           % cut in n deg (radius) from outer max; equals max eccen of wedge
    
    Parameters.background =  128;          % Set the background color 
    
    Stimuli.Sparsity=[1, 1/10]; %Proportion representing the average number of non gray elements

    Stimuli.flash_frequency=[1, 10]; %At what hertz are flashes occuring?
    
%     % Determine the stimulus order
%     checks = Parameters.check_wedges * Parameters.check_rows;
%     
%     refresh=60;
%     
%     %Interleave ones in the sequence
%     base_sequence=zeros(1,60);
%     base_sequence(1:checks:refresh)=1;
%     
%     % Cycle through the sequences
%     for checkcounter = 0:checks-1
%         Stimuli.flash_sequences(:,checkcounter+1)=circshift(base_sequence,[0,checkcounter]);
%     end
%     
%     % Make this matrix longer
%     Stimuli.flash_sequences=repmat(Stimuli.flash_sequences,[Parameters.rot_period,1]);
end

rand_order = [];
for rep_counter = 1:Parameters.NumRunsPerCondition
    
    % Ensure an AB design
    while 1
        order = Shuffle(1:Parameters.NumConditions);
        % Are the first two elements from the same pair of conditions
        if logical((order(1) < 3 && order(2) < 3) || (order(1) > 2 && order(2) > 2))
            continue
        else
            break
        end
    end
    
    rand_order = [rand_order, order];    %Generating the random ordering
end

%Assigning block labels to the ordering
for i=1:Parameters.BlockNum
    Parameters.BlockNames{i,:} = block_Labels{rand_order(i),:};
end

Parameters.BlockNames = Parameters.BlockNames'; %Making sure everything is properly formatted

TrialStructure.Stimuli=Stimuli;
TrialStructure.Parameters=Parameters;   %Setting the parameter structure to the output variable