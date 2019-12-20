%% Generate Trial sequence and conditions for statistical learning

%Generate the appropriate randomized block order for carrying out
%statistical learning

%V Bejjanki 3/2/16
%Updated from expose/test version: 3/17/16

function TrialStructure=GenerateTrials_StatLearning(varargin)

countBal_Flag =0;
Data=varargin{3}; %The third input is data
Window = varargin{4};

tes = rand(1);
if (tes > 0.5)
    countBal_Flag = 1;
else
    countBal_Flag =0;
end 
    
Parameters.StimulusDirectory = '../Stimuli/StatLearningStimuli/'; %Location of images used in retinotopy

%Picking the stimuli randomly from all the available fractals
Parameters.TotalStims = 112;    %112 total unique fractals in stimulus directory (NOT QUITE: There were two duplicate pairs (16-60, 20-89) that are excluded, however, this code currently just skips those).

Parameters.NumStrucStims = 6;   %6 fractals used in structured stream

Parameters.NumRandStims = 6;   %6 fractals used in random stream

Parameters.StimNum = Parameters.NumStrucStims + Parameters.NumRandStims;

%Picking 12 unique fractals (for this participant) for strcutured and random streams, randomly from the 112 fractals available

stim_rand_order = Shuffle(1:Parameters.TotalStims);    %Generating the random ordering of all available stims

% Exclude items from the stim list if the participant has done stat
% learning before

%Find the root of the participant name (without the underscore) and
%find all other files with that root
OtherSessions={};
Idx=strfind(Data.Global.SubjectID, '_');

if ~isempty(Idx)
    Files=dir(sprintf('../Data/%s*.mat', Data.Global.SubjectID(1:max(Idx)-1)));
else
    Files=dir(sprintf('../Data/%s*.mat', Data.Global.SubjectID));
end

%Check to see if this particpant name is in the list, if so, remove it.

for SessionCounter=1:length(Files)
    
    % Is there a match between this participant name and past ones, if so
    % then dont load it
    if isempty(strfind(['../Data/', Files(SessionCounter).name], [Data.Global.SubjectID, '.mat']))
        
        %Load the file
        Temp=load(['../Data/', Files(SessionCounter).name], 'CompletedBlocks');

        OtherSessions{end+1}=Files(SessionCounter).name;
    end
end

fprintf('\n%d past sessions have been detected\n', length(OtherSessions))

if ~isempty(OtherSessions)
    fprintf('\nDo you want to load them?\n''y'' to confirm, any other key to make a new GenerateTrials\n')
    
    pause(0.2);
    [~, keyCode]=KbWait(Window.KeyboardNum);
    
    %If they don't press y then remove the OtherSessions variable
    if strcmp(KbName(keyCode), 'y')
        fprintf('\nLoading other participants\n')
        
    else
        OtherSessions={};
        fprintf('\nNot loading other participants\n')
    end
        
    pause(0.2);
end


%Iterate through the sessions and exclude the stimuli that are used
for SessionCounter=1:length(OtherSessions)
    
    % Load the generate trials
    Temp=load(['../Data/', OtherSessions{SessionCounter}], 'GenerateTrials'); %Retrieve only the generate trials and choosen trials for that participant
    
    %Retrieve subfields from output
    PreGeneratedTrials=Temp.GenerateTrials;
    
    %Exclude the fractals that have been used
    if isfield(PreGeneratedTrials, 'Experiment_StatLearning')
        try
            stim_rand_order = setdiff(stim_rand_order, [PreGeneratedTrials.Experiment_StatLearning.Parameters.StrucStims, PreGeneratedTrials.Experiment_StatLearning.Parameters.RandStims]);
        catch
        end
    end
    
end

if length(stim_rand_order) < Parameters.StimNum
    warning('Insufficient stimuli to show as many stimuli as you need. Won''t run');
    TrialStructure=[];
    return
end


% There are two pairs of fractals that are duplicates 16 & 60, 20 & 89.
% Remove the latter from the list
stim_rand_order=stim_rand_order(stim_rand_order~=60);
stim_rand_order=stim_rand_order(stim_rand_order~=89);

Parameters.StrucStims = stim_rand_order([1:Parameters.NumStrucStims]);  %Fractals that will be used in the structured stream for this participant

Parameters.RandStims = stim_rand_order([Parameters.NumStrucStims+1:Parameters.StimNum]); %Fractals that will be used in the random stream for this participant


%Setting up the randomized experimental block order
Parameters.NumConditions = 2; %Two types of stat learning trials -> 'str';'rand';

Parameters.NumTrialsPerCondition = 6; %Six trials of each condition

Parameters.NumRepetitions = 1;  %One repetition of each

Parameters.BlockNum = Parameters.NumConditions*Parameters.NumTrialsPerCondition*Parameters.NumRepetitions;

%Going to use interleaved block order
block_Labels_str = {'str1';'rand1';'str2';'rand2';'str3';'rand3';'str4';'rand4';'str5';'rand5';'str6';'rand6'};

block_Labels_rand = {'rand1';'str1';'rand2';'str2';'rand3';'str3';'rand4';'str4';'rand5';'str5';'rand6';'str6';};

%Assigning block labels to the ordering
if (countBal_Flag)
    for i=1:Parameters.BlockNum      
        Parameters.BlockNames{i,:} = block_Labels_str{(i),:};
    end
else
    for i=1:Parameters.BlockNum
        Parameters.BlockNames{i,:} = block_Labels_rand{(i),:};
    end
end
Parameters.BlockNames = Parameters.BlockNames'; %Making sure everything is properly formatted

%Setting up the stimulus order in each random trial
Parameters.numRepRand = 6;  %Going to set up random order for the entire trial

rand_rand_order_tot = zeros(Parameters.BlockNum/2,Parameters.NumRandStims*Parameters.numRepRand);   %This will be final random stream

for k = 1:Parameters.BlockNum/2 %For only the random blocks
    l=1;
    while l < (Parameters.numRepRand+1)
        rand_rand_order_tot(k,((l-1)*Parameters.NumRandStims)+1:(l*Parameters.NumRandStims)) = randperm(Parameters.NumRandStims);
        if (l > 1 & rand_rand_order_tot(k,(l-1)*Parameters.NumRandStims) == rand_rand_order_tot(k,((l-1)*Parameters.NumRandStims)+1))   % making sure there are never repeats
            l = l-1;
        end
        l=l+1;
    end
end

Parameters.RandStreamElements = zeros(size(rand_rand_order_tot));  
Parameters.RandStreamElements = Parameters.RandStims(rand_rand_order_tot);   %Converting temp indexes into index of fractals assigned to random stream, obtained earlier

%Setting up the stimulus order in each structured trial
Parameters.numRepStruc = 3; %Going to set up randomized structure order for half the trial -> second half will be copy of first half -> diff from random stream

begIndexStruc = [1,3,5];    %First element of each pair
block_begIndex = repmat(begIndexStruc,[1,Parameters.numRepStruc]);

struc_rand_order_tot = zeros(Parameters.BlockNum/2,length(block_begIndex)*4);   %This will be final structured stream

for j = 1:Parameters.BlockNum/2 %For only the structured blocks
    struc_rand_order = repmat(Shuffle(block_begIndex),[1,2]);   %second half of trial is exact replica of first half -> diff from random stream
    struc_rand_order_tot(j,[1:2:length(struc_rand_order_tot)-1]) = struc_rand_order;
    struc_rand_order_tot(j,[2:2:length(struc_rand_order_tot)]) = struc_rand_order+1;
    clear struc_rand_order
end
    
Parameters.StrucStreamElements = zeros(size(struc_rand_order_tot));  
Parameters.StrucStreamElements = Parameters.StrucStims(struc_rand_order_tot);   %Converting temp indexes into index of fractals assigned to structured stream, obtained earlier

TrialStructure.Parameters=Parameters;   %Setting the parameter structure to the output variable

