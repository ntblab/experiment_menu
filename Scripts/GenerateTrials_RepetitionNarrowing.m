%% Generate Trial sequence and conditions for repetition narrowing experiments
%
% Generate the appropriate trial sequence with randomization for a number of
% blocks in the repetition narrowing experiment
%
% C Ellis 12/2/17
%
% updates
% TY 3/19/2019
% have conditions (5) in balanced Latin Square
% fix the way that other sessions are loaded in
% TY 6/20/2019

function TrialStructure=GenerateTrials_RepetitionNarrowing(varargin)

PreGeneratedTrials=varargin{1}; %Specify that the first input refers to Pregenerated trials
Data=varargin{3}; %The third input is data
Window=varargin{4};

%% Set up the parameters of the experiment

Parameters.StimulusDirectory='../Stimuli/RepetitionNarrowing/'; %Where are the stimuli stored?

Parameters.StimuliPerBlock=8; %How many stimuli per block

Parameters.RepetitionLevels=2; %How many different levels of the repetition condition (are some items new, some items old and how many different amounts are there)

Parameters.StimulusLevelNames={'Human_Adult','Scenes','Sheep'}; %Which folders would you like to call from? %This needs to be in the right order

StimulusLevels=length(Parameters.StimulusLevelNames); %How many different stimuli categories will you use

Parameters.BlocksperCondition=5; %How many repetitions of each block type will you do?

Parameters.Match_Group=1; %Do you want to match pairs during the VPC where possible.

Parameters.VPC_Timing=5; %How many seconds should the VPC test last for?

Parameters.VPC_Trials=1; %How many VPC trials do you have?

Stimuli.Disparity=10; % What is the disparity for VPC?

Parameters.VPC_ITI=0.25; %How many seconds between VPC trials? (if there are multiple)

Parameters.DecayTime=12; %How long does the code need to wait before it can initiate

%% Pull out all of the stimulus names and store them

StimulusLevelFolders=dir(Parameters.StimulusDirectory); %What are the file names
StimulusLevelFolders=StimulusLevelFolders(arrayfun(@(x) ~strcmp(x.name(1),'.'),StimulusLevelFolders)); %Remove all hidden files

% Iterate through all of the folders and select the ones that match the names

for Counter= 1:length(StimulusLevelFolders)
    
    %If the folder is in the list then included it
    if ~isempty(strfind(cell2mat(Parameters.StimulusLevelNames), StimulusLevelFolders(Counter).name))
        
        %If it is the first time then preset with the original structure
        if exist('TempStruct')~=1
            TempStruct=StimulusLevelFolders(Counter);
        else
            TempStruct(end+1)=StimulusLevelFolders(Counter);
        end
    end
end
StimulusLevelFolders=TempStruct;

for StimulusLevelCounter=1:StimulusLevels
    
    %What are the files in a given directory
    Temp=dir([Parameters.StimulusDirectory, StimulusLevelFolders(StimulusLevelCounter).name]);
    
    Temp=Temp(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp)); %Remove all hidden files
    Temp = Temp(arrayfun(@(x) ~strcmp(x.name(1:4),'Icon'),Temp));
    
    %Iterate through the different files
    for FileCounter=1:length(Temp)
        Stimuli.Filename.(StimulusLevelFolders(StimulusLevelCounter).name){FileCounter}=Temp(FileCounter).name; %Store all the appropriate names
    end
    
end


% Create the sequence of repetitions that work for this data set
RepetitionLevelSequence= [1:Parameters.StimuliPerBlock/(Parameters.RepetitionLevels-1):Parameters.StimuliPerBlock, Parameters.StimuliPerBlock];

TrialSequenceList=[];

%% Determine whether you should remove stimuli previously shown 

%Preset
Used_All_Names={};
OtherSessions={};

%Find the root of the participant name (without the underscore) and
%find all other files with that root
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
        
        %if it's not a backup file
        if isempty(strfind(Files(SessionCounter).name,'_bkp'))
            
            %Load the file
            Temp=load(['../Data/', Files(SessionCounter).name], 'CompletedBlocks');
            
            
            %But, just let the experimenter know how many OtherSessions actually had
            %this experiment run
            if isfield(Temp.CompletedBlocks,'Experiment_RepetitionNarrowing')
                num_blocks_run=sum(Temp.CompletedBlocks.Experiment_RepetitionNarrowing);
                
                if num_blocks_run >= 1
                    OtherSessions{end+1}=Files(SessionCounter).name;
                end
            end
        end
    end
end



fprintf('\n%d past sessions have been detected\n', length(OtherSessions))

if ~isempty(OtherSessions)
    fprintf('\nDo you want to load them and start from the last block run in the most recent session?\n''y'' to confirm, any other key to make a new GenerateTrials\n')
    
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


%% Remove stimuli that may have been used in other experiments with this participant

All_Names={}; %Reset


%Get the names of the available stimuli, keep seperated by folder for
%ease of use
for Counter=1:StimulusLevels
    All_Names{Counter}=Stimuli.Filename.(StimulusLevelFolders(Counter).name);
end

Reload=0; %preset

%Iterate through the sessions and pull out the stimuli that are used
for SessionCounter=0:length(OtherSessions)
    
    %If there has been more than one session then load these
    %pregenerated trials
    if SessionCounter>0
        
        Temp=load(['../Data/', OtherSessions{SessionCounter}], 'GenerateTrials', 'CompletedBlocks'); %Retrieve only the generate trials and chosen trials for that participant
        
        %Retrieve subfields from output
        PreGeneratedTrials=Temp.GenerateTrials;
        CompletedBlocks=Temp.CompletedBlocks;
    end
    
    if isfield(PreGeneratedTrials, 'Experiment_RepetitionNarrowing')
        try
            RandomizedTrialSequence=PreGeneratedTrials.Experiment_RepetitionNarrowing.Stimuli.RandomizedTrialSequence;
           
        catch
            RandomizedTrialSequence=[];
            
            %What stimulus type is it
            RandomizedTrialSequence(:,1)=PreGeneratedTrials.Experiment_RepetitionNarrowing.Stimuli.StimulusTypeSequence;
            
            %Cycle through the blocks
            for BlockCounter=1:size(RandomizedTrialSequence,1)
                
                %Pull out the block
                Block_Name=PreGeneratedTrials.Experiment_RepetitionNarrowing.Parameters.BlockNames{BlockCounter};
                
                %Is this a block with repetitions or not?
                if strcmp(Block_Name(min(strfind(Block_Name, ';'))+2), 'R') %R for repeated; N for novel
                    RandomizedTrialSequence(BlockCounter,2)=Parameters.StimuliPerBlock;
                else
                    RandomizedTrialSequence(BlockCounter,2)=1;
                end
                
                %How many times has this block been run?
                RandomizedTrialSequence(BlockCounter,3)=str2num(Block_Name(end-1:end));
                
            end
        end
    end
    
    %What are the fields of this data
    PreGeneratedTrials_Fields = fieldnames(PreGeneratedTrials);
    
    %Iterate through the fields, corresponding to experiments that have been run
    for FieldCounter = 1:length(PreGeneratedTrials_Fields)
        
        %if we ran Repetition Narrowing before, but did not finish, then give them the
        %blocks that they did not see. if we did finish, tell the
        %experimenter a new generate trials will be made
        if strcmp(PreGeneratedTrials_Fields{FieldCounter}, 'Experiment_RepetitionNarrowing')
            
            %What conditions can be run during this session
            TrialConditions=RandomizedTrialSequence(CompletedBlocks.(PreGeneratedTrials_Fields{FieldCounter})<1, :); %less than 1
            trials_run=size(RandomizedTrialSequence,1)-size(TrialConditions,1);
            
            fprintf('\nParticipant completed %d blocks in a previous session (session %d).\n',trials_run, SessionCounter)
            
            %check if the counterbalancing was the old version or the new
            %version
            if ~isfield(PreGeneratedTrials.Experiment_RepetitionNarrowing.Parameters, 'LatinCondition')
                warning('\nParticipant had an old counterbalancing condition in a previous session. ABORTING\n')
                TrialStructure=[];
                return
                
            %if you finished last time but forgot
            elseif size(TrialConditions,1)==0
                fprintf('\nParticipant completed the study in a previous session (session %d). Generating a new random sequence\n',SessionCounter)
                Reload=0; %do not reload
            
            %if you did not finish, but the size of what was run is less than total possible trials and you chose to reload, then reload    
            elseif size(TrialConditions,1)<size(RandomizedTrialSequence,1) 
                Reload=1; %reload
            
            %if we didn't run any blocks in the last session, we probably
            %should just generate new blocks
            else
                Reload=0;  
            end
            
            %Is there a field that contains the appropriate distinction
        elseif isfield(PreGeneratedTrials.(PreGeneratedTrials_Fields{FieldCounter}), 'Stimuli') && isfield(PreGeneratedTrials.(PreGeneratedTrials_Fields{FieldCounter}).Stimuli, 'SelectedStimuli_Names')
            
            %What stimulus names
            Used_Names=PreGeneratedTrials.(PreGeneratedTrials_Fields{FieldCounter}).Stimuli.SelectedStimuli_Names;
            
            
            if ~iscell(Used_Names)
                Used_Names={Used_Names}; %Make a cell

                %Reshape into a list
                Used_Names = reshape(Used_Names, numel(Used_Names), 1);
                
                Used_All_Names(end+1:end+length(Used_Names))=Used_Names; %Add to the list
            end
            
        else
            sprintf('No appropriate field for %s\n', PreGeneratedTrials_Fields{FieldCounter});
            
        end
    end
end

%Remove any empty files
Used_All_Names=Used_All_Names(~cellfun(@isempty, Used_All_Names));

% Iterate through the stimulus levels and get the indices previously used
for StimulusLevelCounter=1:StimulusLevels
    
    %What indexes were used
    [~, ~, Used_Idxs]=intersect(Used_All_Names, All_Names{StimulusLevelCounter});
    
    %If there is any overlap then remove these stimuli from the
    %available list
    
    %Make a list of all the stimuli indexes
    Idxs=1:length(Stimuli.Filename.(StimulusLevelFolders(StimulusLevelCounter).name));
    AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)=Idxs;
    if ~isempty(Used_Idxs)
        AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)=setdiff(Idxs, Used_Idxs);
    end
end


%Determine how many stimuli per StimulusLevel is possible
for StimulusLevelCounter=1:StimulusLevels
    if length(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name))<(sum(RepetitionLevelSequence + Parameters.VPC_Trials))*Parameters.BlocksperCondition
        
        %How many blocks could you run. Multiply by 2 because you can do a
        %repetition as well as a non repetition
        BlocksPossible(StimulusLevelCounter)=floor(length(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name))/(Parameters.StimuliPerBlock+1));
        
        %Print out how many blocks can be produced with the given stimuli
        fprintf('Insufficient stimuli for %s. Will only produce %d blocks\n\n', StimulusLevelFolders(StimulusLevelCounter).name, BlocksPossible(StimulusLevelCounter));
        
        %How many stimuli do you need per category of stimuli?
        StimuliperStimulusLevel(StimulusLevelCounter)=0;
        for RepetitionLevelCounter=1:Parameters.RepetitionLevels %Iterate through the different amounts of repetitions
            
            StimuliperStimulusLevel(StimulusLevelCounter)=StimuliperStimulusLevel(StimulusLevelCounter)+((RepetitionLevelSequence(RepetitionLevelCounter)+Parameters.VPC_Trials)*BlocksPossible(StimulusLevelCounter));
        end
        
    else %Supply the max block number in this case
        BlocksPossible(StimulusLevelCounter)=Parameters.BlocksperCondition;
        
        if strcmp(StimulusLevelFolders(StimulusLevelCounter).name(1:5), 'Scene')
            StimuliperStimulusLevel(StimulusLevelCounter)=(sum(RepetitionLevelSequence(2) + Parameters.VPC_Trials))*Parameters.BlocksperCondition; %only care about novel condition for the scenes!!
        else
            StimuliperStimulusLevel(StimulusLevelCounter)=(sum(RepetitionLevelSequence + Parameters.VPC_Trials))*Parameters.BlocksperCondition;
        end
    end
end

%% Iterate through the different conditions and generate the stimuli lists for this participant
% HOWEVER, if you didn't finish last time and would like to, you may load
% in the past session's stimulus list
% Note that this will reload from just the most recent session, and not
% sessions before that.
% Also, we are going to make sure that you begin at a set of 5
% counterbalancing -- this means that if you completed up to block 6 in a previous session, you will start back at block 6
% Note that this means that the subject will possibly be see stimuli that were shown before. We assume that the only reason 
% why you did not complete a block of 5 was because the infant was quite upset (and therefore maybe not paying attention to the stimuli in the first place)
% By doing this, we maximize the number of possible blocks that we can get from a single participant

if Reload==1
    try 
        %Change the relevant things to get rid of previously run blocks,
        %keeping the ones that you have not run and not changing the
        %parameters
        
        %First, we want to re-label the number of completed blocks so that
        %you will restart an unfinished counterbalancing set
        Sets_completed=CompletedBlocks.Experiment_RepetitionNarrowing(Parameters.BlocksperCondition:Parameters.BlocksperCondition:end);
        
        fprintf('\nLast completed set was %d, assuming you would like to start at block number %d.\n',sum(Sets_completed),sum(Sets_completed)*Parameters.BlocksperCondition+1)
        
        CompletedBlocks_Relabeled=zeros(length(CompletedBlocks.Experiment_RepetitionNarrowing),1);
        
        for SetCounter=1:length(Sets_completed)
            if Sets_completed(SetCounter)==1
                CompletedBlocks_Relabeled(Parameters.BlocksperCondition*(SetCounter-1)+1:Parameters.BlocksperCondition*SetCounter)=1;
            end
        end
        
        %Important parameters to update
        Parameters.BlockNames=PreGeneratedTrials.Experiment_RepetitionNarrowing.Parameters.BlockNames(CompletedBlocks_Relabeled<1); %make sure block names are correct
        Parameters.BlockNum=length(Parameters.BlockNames); %length of blocks that have not yet been run
        Parameters.LatinCondition=PreGeneratedTrials.Experiment_RepetitionNarrowing.Parameters.LatinCondition; %remember which counterbalancing this was
        
        %important stimuli to update based on the number of completed blocks
        Stimuli.RandomizedTrialSequence=PreGeneratedTrials.Experiment_RepetitionNarrowing.Stimuli.RandomizedTrialSequence(CompletedBlocks_Relabeled<1, :);
        Stimuli.StimulusTypeSequence=PreGeneratedTrials.Experiment_RepetitionNarrowing.Stimuli.StimulusTypeSequence(CompletedBlocks_Relabeled<1);
        Stimuli.StimulusTokenSequence=PreGeneratedTrials.Experiment_RepetitionNarrowing.Stimuli.StimulusTokenSequence(:,CompletedBlocks_Relabeled<1);
        Stimuli.TestTokens=PreGeneratedTrials.Experiment_RepetitionNarrowing.Stimuli.TestTokens(:,CompletedBlocks_Relabeled<1);
        Stimuli.New_Position=PreGeneratedTrials.Experiment_RepetitionNarrowing.Stimuli.New_Position(CompletedBlocks_Relabeled<1);
        
        %These few are likely the same as at the top of this script but use the
        %old generate trials just in case
        Parameters.StimuliPerBlock=PreGeneratedTrials.Experiment_RepetitionNarrowing.Parameters.StimuliPerBlock;
        Parameters.RepetitionLevels=PreGeneratedTrials.Experiment_RepetitionNarrowing.Parameters.RepetitionLevels;
        Parameters.BlocksperCondition=PreGeneratedTrials.Experiment_RepetitionNarrowing.Parameters.BlocksperCondition;
        Parameters.Match_Group=PreGeneratedTrials.Experiment_RepetitionNarrowing.Parameters.Match_Group;
        Stimuli.Disparity=PreGeneratedTrials.Experiment_RepetitionNarrowing.Stimuli.Disparity;
    catch
        Reload=0;
    end
end        

if Reload==0
    for StimulusLevelCounter=1:StimulusLevels
        
        %% Do you want to match the race and gender of the human test stimuli?
        
        if Parameters.Match_Group==1
            
            % Which indexes in the file name discriminate group
            
            if strcmp(StimulusLevelFolders(StimulusLevelCounter).name(1:5), 'Human')
                group_compare_idxs=1:2;
                     
            %don't want to pretend that I can group sheep though
            elseif strcmp(StimulusLevelFolders(StimulusLevelCounter).name(1:5), 'Sheep')
            
                %What are the indexes you are saying are acceptable
                possible_idxs=Shuffle(1:length(Stimuli.Filename.(StimulusLevelFolders(StimulusLevelCounter).name)));
                pairs=(BlocksPossible(StimulusLevelCounter) * Parameters.RepetitionLevels * Parameters.VPC_Trials);
                
                % Pull out the number of paired items and shape them appropriately
                VPC_idxs=reshape(possible_idxs(1:pairs*2), pairs, 2);
                
                %empty group_compare_idxs so you won't go through the loop of
                %finding VPC pairs for this stimulus level
                group_compare_idxs=[];
                
            else
                group_compare_idxs=1;
            end
            
            if ~isempty(group_compare_idxs)
                % Identify the names that stimuli have
                group_labels={};
                group=[];
                for Stim_counter=1:length(Stimuli.Filename.(StimulusLevelFolders(StimulusLevelCounter).name))
                    group_label=Stimuli.Filename.(StimulusLevelFolders(StimulusLevelCounter).name){Stim_counter}(group_compare_idxs);
                    
                    % Is this a new group label? If so add it to the list
                    if isempty(strcmp(group_labels, group_label)) || all(strcmp(group_labels, group_label)==0)
                        group_labels{end+1}=group_label;
                        group(end+1)=length(group_labels);
                    else
                        group(end+1)=find(strcmp(group_labels, group_label));
                    end
                end
                
                
                X_idx=[];
                % What idxs could be used
                for group_counter=1:length(group_labels)
                    if ~isempty(strfind(group_labels{group_counter}(group_compare_idxs), 'X'))
                        X_idx(end+1)=group_counter;
                    end
                end
                
                % Which idxs ought to be excluded
                excluded_idxs=[];
                for X_counter=1:length(X_idx)
                    excluded_idxs=[excluded_idxs, find(group==X_idx(X_counter))];
                end
                
                % What idxs are available
                possible_idxs=Shuffle(setdiff(1:length(group), excluded_idxs));
                
                % Cycle through the pairs you need to make
                possible_idx_counter=1;
                for pair_counter=1:(BlocksPossible(StimulusLevelCounter) * Parameters.RepetitionLevels * Parameters.VPC_Trials)
                    
                    % What is the group of this possible idx?
                    idx_group=group(possible_idxs(possible_idx_counter));
                    
                    % What idx is matched for group?
                    pair_idx = min(find(idx_group==group(possible_idxs(possible_idx_counter+1:end)))) + possible_idx_counter;
                    
                    % Did you find a pair? If you did then store it and remove
                    % these from the possible idxs. If you didn't go to another
                    % possible index
                    if ~isempty(pair_idx)
                        
                        VPC_idxs(pair_counter, :)=[possible_idxs(possible_idx_counter), possible_idxs(pair_idx)];
                        
                        % Remove used idxs from the list
                        possible_idxs=Shuffle(setdiff(possible_idxs, VPC_idxs(pair_counter, :)));
                        possible_idx_counter=1;
                    else
                        % Increment index
                        possible_idx_counter=possible_idx_counter+1;
                    end
                end
            end
            
        else
            %What are the indexes you are saying are acceptable
            possible_idxs=Shuffle(1:length(Stimuli.Filename.(StimulusLevelFolders(StimulusLevelCounter).name)));
            pairs=(BlocksPossible(StimulusLevelCounter) * Parameters.RepetitionLevels * Parameters.VPC_Trials);
            
            % Pull out the number of paired items and shape them appropriately
            VPC_idxs=reshape(possible_idxs(1:pairs*2), pairs, 2);
            
        end
        
        %What idxs are available after the VPC ones have been removed
        AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)=Shuffle(setdiff(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name), VPC_idxs(:)));
        
        %% Separate the given stimuli into different blocks
        BlockCounter=1;
        
        %if it's scenes we don't care about the novel/repeat conditions
        if strcmp(StimulusLevelFolders(StimulusLevelCounter).name(1:5), 'Scene')
            DifferentStimPerBlock=(RepetitionLevelSequence(2));
            for BlocksperConditionCounter=1:BlocksPossible(StimulusLevelCounter)
                
                % If there are no VPC trials just take a random draw
                if exist('VPC_idxs')==0
                    
                    %Take a draw of the stimuli not yet used. The higher the
                    %repetition amount, the fewer there will be
                    
                    SelectedIdxs=AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)(1:DifferentStimPerBlock); %Take as many stimuli as you need (depends on repetitions and VPC trials
                    
                else
                    % Take the familar VPC idx and add some amount of other
                    % idxs then shuffle
                    SelectedIdxs=Shuffle([VPC_idxs(BlockCounter,1), AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)(1:DifferentStimPerBlock-1)]);
                end
                
                %Increase the length in the case that you are presenting a
                %stimulus multiple times
                if (length(SelectedIdxs)-Parameters.VPC_Trials)<Parameters.StimuliPerBlock %Is this a repetition block?
                    
                    %Leave the first N stimuli for being in the VPC_Trials
                    SelectedIdxs(1:Parameters.StimuliPerBlock)=repmat(SelectedIdxs, (Parameters.StimuliPerBlock)/length(SelectedIdxs),1); %Replicate the matrix a given amount
                    
                    SelectedIdxs=fliplr(SelectedIdxs); %Make the indices end on the novel stim
                    
                end
                
                %Record the stimuli idxs you have choosen.
                %Make a 4d matrix containing all of the different stimuli,
                %reading down a column to see a potential block (in a
                %randomized order)
                Stimuli.SelectedStimuli(:, StimulusLevelCounter, RepetitionLevelCounter, BlocksperConditionCounter)=SelectedIdxs;
                
                Stimuli.VPC_idxs(:, StimulusLevelCounter, RepetitionLevelCounter, BlocksperConditionCounter)=VPC_idxs(BlockCounter,:);
                
                
                %Store the stimuli names
                for Counter=1:length(SelectedIdxs)
                    Stimuli.SelectedStimuli_Names{Counter, StimulusLevelCounter, RepetitionLevelCounter, BlocksperConditionCounter}=Stimuli.Filename.(StimulusLevelFolders(StimulusLevelCounter).name){SelectedIdxs(Counter)};
                end
                
                %Remove the stimulus idxs you have choosen from the available
                %list. Have to shuffle because setdiff orders them
                AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)=Shuffle(setdiff(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name), SelectedIdxs));
                
                %if you didn't add anything then don't do it
                if BlocksperConditionCounter<=BlocksPossible(StimulusLevelCounter)
                    TrialSequenceList(end+1,:)=[StimulusLevelCounter, RepetitionLevelCounter, BlocksperConditionCounter]; %Make a list of all the possible condition indexes
                end
                
                BlockCounter=BlockCounter+1;
            end
            
        else
            for RepetitionLevelCounter=1:Parameters.RepetitionLevels %Iterate through the different amounts of repetitions
                
                %How many different stimuli will there be per block
                DifferentStimPerBlock=(RepetitionLevelSequence(RepetitionLevelCounter));
                
                for BlocksperConditionCounter=1:BlocksPossible(StimulusLevelCounter)
                    
                    % If there are no VPC trials just take a random draw
                    if exist('VPC_idxs')==0
                        
                        %Take a draw of the stimuli not yet used. The higher the
                        %repetition amount, the fewer there will be
                        
                        SelectedIdxs=AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)(1:DifferentStimPerBlock); %Take as many stimuli as you need (depends on repetitions and VPC trials
                        
                    else
                        % Take the familar VPC idx and add some amount of other
                        % idxs then shuffle
                        SelectedIdxs=Shuffle([VPC_idxs(BlockCounter,1), AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)(1:DifferentStimPerBlock-1)]);
                    end
                    
                    %Increase the length in the case that you are presenting a
                    %stimulus multiple times
                    if (length(SelectedIdxs)-Parameters.VPC_Trials)<Parameters.StimuliPerBlock %Is this a repetition block?
                        
                        %Leave the first N stimuli for being in the VPC_Trials
                        SelectedIdxs(1:Parameters.StimuliPerBlock)=repmat(SelectedIdxs, (Parameters.StimuliPerBlock)/length(SelectedIdxs),1); %Replicate the matrix a given amount
                        
                        SelectedIdxs=fliplr(SelectedIdxs); %Make the indices end on the novel stim
                        
                    end
                    
                    %Record the stimuli idxs you have choosen.
                    %Make a 4d matrix containing all of the different stimuli,
                    %reading down a column to see a potential block (in a
                    %randomized order)
                    Stimuli.SelectedStimuli(:, StimulusLevelCounter, RepetitionLevelCounter, BlocksperConditionCounter)=SelectedIdxs;
                    
                    Stimuli.VPC_idxs(:, StimulusLevelCounter, RepetitionLevelCounter, BlocksperConditionCounter)=VPC_idxs(BlockCounter,:);
                    
                    
                    %Store the stimuli names
                    for Counter=1:length(SelectedIdxs)
                        Stimuli.SelectedStimuli_Names{Counter, StimulusLevelCounter, RepetitionLevelCounter, BlocksperConditionCounter}=Stimuli.Filename.(StimulusLevelFolders(StimulusLevelCounter).name){SelectedIdxs(Counter)};
                    end
                    
                    %Remove the stimulus idxs you have choosen from the available
                    %list. Have to shuffle because setdiff orders them
                    AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)=Shuffle(setdiff(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name), SelectedIdxs));
                    
                    %if you didn't add anything then don't do it
                    if BlocksperConditionCounter<=BlocksPossible(StimulusLevelCounter)
                        TrialSequenceList(end+1,:)=[StimulusLevelCounter, RepetitionLevelCounter, BlocksperConditionCounter]; %Make a list of all the possible condition indexes
                    end
                    
                    BlockCounter=BlockCounter+1;
                end
            end
        end
    end
    
    
    %% Generate the randomized trial sequence
    
    %Sort the blocks so that each set of StimulusLevel*RepetitionLevel is
    %random but in a chunk
    %The best way we can do this is to preset balanced Latin Squares
    %
    
    %flip a coin to decide if using the traditional latin square or its mirror
    %image
    flip=randi([0,1]);
    if flip >0
        LatinSquare=[1, 2, 5, 3, 4; 2, 3, 1, 4, 5; 3, 4, 2, 5, 1; 4, 5, 3, 1, 2; 5, 1, 4, 2, 3];
        fprintf('Counterbalancing -- A \n\n')
        Parameters.LatinCondition='A';
    else
        LatinSquare=[4, 3, 5, 2, 1; 5, 4, 1, 3, 2; 1, 5, 2, 4, 3; 2, 1, 3, 5, 4; 3, 2, 4, 1, 5];
        fprintf('Counterbalancing --- B \n\n')
        Parameters.LatinCondition='B';
    end
    
    RandomizedTrialSequence=[];
    for BlockRepCounter=unique(TrialSequenceList(:,3))'
        Idxs=find(TrialSequenceList(:,3)==BlockRepCounter);
        
        %what's the order ?
        Order=LatinSquare(BlockRepCounter,:);
        Idxs=Idxs(Order);
        
        %Append this chunk on to the end
        RandomizedTrialSequence(end+1:end+length(Idxs),:)=TrialSequenceList(Idxs,:); %Take the randomly ordered indexes here
        
    end
    
    %Store for later
    Stimuli.RandomizedTrialSequence=RandomizedTrialSequence;
    
    Parameters.BlockNum=size(RandomizedTrialSequence,1); %How many blocks are there in this experiment
    
    %Quit if there aren't enough stimuli left to make a block
    if Parameters.BlockNum==0
        TrialStructure=[];
        fprintf('\nInsufficient available stimuli. Could not generate block information. ABORTING\n\n');
        return
    end
    
    for BlockCounter=1:Parameters.BlockNum
        
        %What category of stimuli are being selected?
        
        Stimuli.StimulusTypeSequence(BlockCounter)=RandomizedTrialSequence(BlockCounter,1);
        
        %What exemplars of the given category are to be choosen (don't take the
        %last one
        
        Stimuli.StimulusTokenSequence(:,BlockCounter)=Stimuli.SelectedStimuli(:, RandomizedTrialSequence(BlockCounter,1), RandomizedTrialSequence(BlockCounter,2), RandomizedTrialSequence(BlockCounter,3));
        
        %Which stimuli from this block will be used in the VPC? The first is
        %the familar one
        Stimuli.TestTokens(:,BlockCounter)=Stimuli.VPC_idxs(:, RandomizedTrialSequence(BlockCounter,1), RandomizedTrialSequence(BlockCounter,2), RandomizedTrialSequence(BlockCounter,3));
        
    end
    
    %% Decide on the old versus new ordering (left vs right)
    
    Temp=repmat(1:2, Parameters.VPC_Trials, round(Parameters.BlockNum/2));
    
    % Is the new stimulus on the left or the right?
    for Counter=1:Parameters.VPC_Trials
        Stimuli.New_Position(Counter,:)=Shuffle(Temp(Counter,:));
    end
    
    %% Set up block names, what the blocks are called and can be supplied to the menu system
    
    for BlockCounter=1:size(RandomizedTrialSequence,1)
        
        %WHat category is being selected
        Category=StimulusLevelFolders(RandomizedTrialSequence(BlockCounter,1)).name;
        if strcmp(Category(1:5), 'Scene')
            Repetitions='Novel';
        else
            %How many repetitions per block are there?
            Repetitions=RepetitionLevelSequence(RandomizedTrialSequence(BlockCounter,2));
            if Repetitions > 1
                Repetitions='Novel';
            else
                Repetitions='Repeated';
            end
        end
        %What number block of this type is this?
        nthBlock=RandomizedTrialSequence(BlockCounter,3);
        
        %What is the name
        Parameters.BlockNames{BlockCounter}=sprintf('%s; %s; Block: %0.0f', Category, Repetitions, nthBlock);
     
    end
end    

%% Store the outputs

TrialStructure.Parameters=Parameters;

TrialStructure.Stimuli=Stimuli;
