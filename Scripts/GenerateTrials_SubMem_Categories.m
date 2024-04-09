%% Generate Trial sequence and conditions for event-related subsequent memory task
%
%Generate the appropriate trial sequence with randomization for a number of
%blocks in the event-related subsequent memory experiment
%
% Initial code
% TY 12/6/2019
%
% Only use one memory delay
% Remove images used in a previous session and rebalance conditions in
% thirds
% TY 12/11/2020

function TrialStructure=GenerateTrials_SubMem_Categories(varargin)

Data=varargin{3}; 
Window=varargin{4};

%Set up the parameters of the experiment
Parameters.StimulusDirectory='../Stimuli/SubMem_Categories/'; %Where are the stimuli stored?

Parameters.StimulusLevelNames={'Faces','Objects','Places'}; %Which folders would you like to call from? 

StimulusLevels=length(Parameters.StimulusLevelNames); %How many different stimuli categories will you use

Parameters.Encoding_Timing=2; %how long should encoding last?

Parameters.VPC_Timing=4; %How many seconds should the test comparison last for? 

Stimuli.Disparity=10; % What is the disparity for VPC?

Parameters.MemDelay_Short=[3 4 5]; %Approximately how many encoding trials before the VPC is shown (short memory)?

Parameters.ITITime=[2 4 6];

Parameters.DecayTime=12; %How long does the code need to wait before it can initiate

% Where are the background images stored? 
Parameters.BackgroundImagesDirectory='../Stimuli/GifFrames/';
Temp=dir(Parameters.BackgroundImagesDirectory);
Temp=Temp(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp)); %Remove all hidden files
Temp = Temp(arrayfun(@(x) ~strcmp(x.name(1:4),'Icon'),Temp));
for FileCounter=1:length(Temp)
    Stimuli.GifFiles{FileCounter}=Temp(FileCounter).name; %Store all the appropriate names
end

%Name the blocks
Parameters.BlockNames= {'Start from last trial', 'Start at the beginning (trial 1)'};
Parameters.BlockNum= length(Parameters.BlockNames);           

%% Pull out all of the stimulus names and store them
StimulusLevelFolders=dir(Parameters.StimulusDirectory); %What are the file names
StimulusLevelFolders=StimulusLevelFolders(arrayfun(@(x) ~strcmp(x.name(1),'.'),StimulusLevelFolders)); %Remove all hidden files

%Iterate through all of the folders and select the ones that match the names
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

AvailableIdxs=struct;
All_Names=struct;

for StimulusLevelCounter=1:StimulusLevels
    
    AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)=[];
    All_Names.(StimulusLevelFolders(StimulusLevelCounter).name)={};
    
    %What are the files in a given directory
    Temp=dir([Parameters.StimulusDirectory, StimulusLevelFolders(StimulusLevelCounter).name]);
    
    Temp=Temp(arrayfun(@(x) ~strcmp(x.name(1),'.'),Temp)); %Remove all hidden files
    Temp = Temp(arrayfun(@(x) ~strcmp(x.name(1:4),'Icon'),Temp));
    
    %Iterate through the different files
    for FileCounter=1:length(Temp)
        Stimuli.Filename.(StimulusLevelFolders(StimulusLevelCounter).name){FileCounter}=Temp(FileCounter).name; %Store all the appropriate names
        AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)(end+1)=FileCounter; 
        All_Names.(StimulusLevelFolders(StimulusLevelCounter).name){end+1}=Temp(FileCounter).name; 
        
    end
    
end

%% Determine whether you should remove data

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

% For all sessions with this participant's ID, first check whether or not the file is a backup version of the current session and if not, then load the file and check if we ran this experiment before
% this just counts up previous sessions that may have had the experiment run; then we will decide whether or not we want to use this information to impact which images are shown now
for SessionCounter=1:length(Files)
    
    % Is there a match between this participant name and past ones? if so then dont load it
    if isempty(strfind(['../Data/', Files(SessionCounter).name], [Data.Global.SubjectID, '.mat']))
        
        %if it's not a backup file
        if isempty(strfind(Files(SessionCounter).name,'_bkp'))
            
            %Load the file
            Temp=load(['../Data/', Files(SessionCounter).name], 'CompletedBlocks');
            
            
            %Let the experimenter know how many OtherSessions actually had this experiment run
            if isfield(Temp.CompletedBlocks,'Experiment_SubMem_Categories')
                num_blocks_run=sum(Temp.CompletedBlocks.Experiment_SubMem_Categories);

                % record this information
                if num_blocks_run >= 1
                    OtherSessions{end+1}=Files(SessionCounter).name;
                end
            end
        end
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


%% Remove images that have been used before, if asked to 
%Iterate through the previous sessions and remove the images shown before
for SessionCounter=0:length(OtherSessions)
    
    %If there has been more than one session then load these
    %pregenerated trials
    if SessionCounter > 0
        Temp=load(['../Data/', OtherSessions{SessionCounter}], 'Data', 'GenerateTrials'); %Retrieve only the generate trials and actual trials that were run for that participant
        
        %Retrieve subfields from output
        PreGeneratedTrials=Temp.GenerateTrials;
        PreviousData=Temp.Data;
        
        %What are the fields of this data
        PreviousData_Fields = fieldnames(PreviousData);
        
        %Iterate through the fields, corresponding to experiments that have been run
        for FieldCounter = 1:length(PreviousData_Fields)
            
            %Is there a field that contains the appropriate distinction
            if isfield(PreGeneratedTrials,(PreviousData_Fields{FieldCounter})) && isfield(PreGeneratedTrials, 'Experiment_SubMem_Categories') && isfield(PreGeneratedTrials.(PreviousData_Fields{FieldCounter}), 'Stimuli') && isfield(PreGeneratedTrials.(PreviousData_Fields{FieldCounter}).Stimuli, 'VPC_idxs')
                
                Block_Fields=fieldnames(PreviousData.(PreviousData_Fields{FieldCounter}));
                
                for BlockCounter=1:length(Block_Fields)
                    
                    % What stimulus were actually shown in previous sessions?
                    Used_Names=PreviousData.(PreviousData_Fields{FieldCounter}).(Block_Fields{BlockCounter}).Stimuli.Name;
                    
                    %If it is a cell, reshape into a list
                    if ~iscell(Used_Names)
                        Used_Names={Used_Names}; %Make a cell
                    end
                    
                    Used_Names = reshape(Used_Names, numel(Used_Names), 1);
                    
                    Used_All_Names(end+1:end+length(Used_Names))=Used_Names; %Add to the list
                    
                end
                
            else
                sprintf('No appropriate field for %s\n', PreviousData_Fields{FieldCounter});
                
            end
            
        end
    end
    
end

Used_All_Names=Used_All_Names(~cellfun(@isempty, Used_All_Names));

% grab the non-encoding test images that were used (always saved as second in the list) 
for idx=1:length(Used_All_Names)
    
    if iscell(Used_All_Names{idx})
        
        NovelImage=Used_All_Names{idx}{2};
        position=find(NovelImage == '/', 1, 'last'); % for some reason test trials have all the info
        Used_All_Names{idx}=NovelImage(position+1:end);
    end
    
end

TotalStimCount=0;

for StimulusLevelCounter=1:length(fieldnames(AvailableIdxs))
    %What indexes were used
    [~, ~, Used_Idxs]=intersect(Used_All_Names, All_Names.(StimulusLevelFolders(StimulusLevelCounter).name));
    
    %If there is any overlap then remove these stimuli from the
    %available list
    %AvailableIdxs=1:length(All_Names);
    if ~isempty(Used_Idxs)
        AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)=setdiff(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name), Used_Idxs);
    
    end
    
    TotalStimCount=TotalStimCount+length(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name));
    
end

% Quit if there aren't enough stimuli left (arbitrary number, but 20 would definitely be too few)
if TotalStimCount < 20
    TrialStructure=[];
    fprintf('\nInsufficient available stimuli. Could not generate block information. ABORTING\n\n');
    return
else
    
    fprintf('\n Total of %d trials (~ %d encoding) available\n\n',TotalStimCount,round(TotalStimCount/2));
end

%% Select the images used for encoding and VPCs

%If you want to match the categories for the VPCs (test an encoded face
%with another face), then the maximum number of test trials would be
%half of the number of available stimuli

for StimulusLevelCounter=1:StimulusLevels
    
    StimuliNumber= length(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)); %how many stimuli are available here then?
    Parameters.VPC_Trials(:,StimulusLevelCounter) = floor(StimuliNumber/2);   % how many test trials for this test type are possible?
    
    %shuffle them up!
    Temp = Shuffle(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name));
    
    %These are the ones that will be encoded
    SelectedIdxs.(StimulusLevelFolders(StimulusLevelCounter).name) = Temp(1:Parameters.VPC_Trials(:,StimulusLevelCounter));
    
    %Remove stimulus idxs you have chosen from the available list
    AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)= setdiff(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name), SelectedIdxs.(StimulusLevelFolders(StimulusLevelCounter).name));
    
    %Shuffle again for the novel VPC indexes
    Temp = Shuffle(AvailableIdxs.(StimulusLevelFolders(StimulusLevelCounter).name));
    VPC_temp = Temp(1:Parameters.VPC_Trials(:,StimulusLevelCounter));
    
    %Now save out the encoded image and novel image accordingly (old is in index 1)
    VPC_idxs.(StimulusLevelFolders(StimulusLevelCounter).name)=[SelectedIdxs.(StimulusLevelFolders(StimulusLevelCounter).name);VPC_temp];
end

%Save out encoding idxs
Stimuli.SelectedIdxs=SelectedIdxs;

%Save out where the VPCs will be
Stimuli.VPC_idxs=VPC_idxs;

%% Create the encoding sequence
%Now we want to shuffle the scenes, objects, and faces for encoding
%it's easiest if we save out the image names because they come from
%different folders

% Create New Matrix From Original Vector (from https://www.mathworks.com/matlabcentral/answers/420553-how-to-split-one-dimensional-array-into-3-equal-chunks)
var3c = @(oldvar) mat2cell(oldvar(:), [fix(numel(oldvar)/3) *[1, 1], numel(oldvar)-2*fix(numel(oldvar)/3)], 1);    

%But we also want to make sure that approximately the same 
%number of images from each category is located in the first and second half 
Temp_1=[];
Temp_2=[];
Temp_3=[];

Total_Num_Images=[];

for StimulusLevelCounter=1:StimulusLevels
    
    %How many encoding items in each third? (for this stimulus type)
    %num_images=size(SelectedIdxs.(StimulusLevelFolders(StimulusLevelCounter).name),2);
    %Total_Num_Images(end+1)=num_images;
    %num_elems=round(num_images/3);
    
    images=SelectedIdxs.(StimulusLevelFolders(StimulusLevelCounter).name)';
    Total_Num_Images(end+1)=length(images);
    
    divisions=var3c(images); % how would you divide this stimulus category into 3 equal sections?
    values=randperm(length(divisions)); % the var3c code will always put the largest value last -- shuffle these so that the thirds are maybe more even
    
    % put these three chunks into the first, second, and third part of the sequence
    Temp_1=horzcat(Temp_1,repmat(StimulusLevelCounter,length(divisions{values(1),:}),1)'); %repmat for matlab2014
    Temp_2=horzcat(Temp_2,repmat(StimulusLevelCounter,length(divisions{values(2),:}),1)'); %repmat for matlab2014
    Temp_3=horzcat(Temp_3,repmat(StimulusLevelCounter,length(divisions{values(3),:}),1)'); %repmat for matlab2014
    
end

%Now we will shuffle the categories for the images randomly
Shuffled_Idxs_1=randperm(length(Temp_1));
Shuffled_Idxs_2=randperm(length(Temp_2));
Shuffled_Idxs_3=randperm(length(Temp_3));

%This tells you which category the items will be coming from
ImageSequence=horzcat(Temp_1(Shuffled_Idxs_1),Temp_2(Shuffled_Idxs_2),Temp_3(Shuffled_Idxs_3));
ImageSequence=ImageSequence(1:sum(Total_Num_Images)); %make sure though that you are not over the amount of images that we actually have (could happen due to rounding)
Stimuli.ImageSequence=ImageSequence; 

%Now let's choose a random encoding-test delay for each encoding image (out of the range we set earlier)
Stimuli.DelaySequence=[];
for i=1:length(ImageSequence)
    
    idx=randi([1,length(Parameters.MemDelay_Short)]); %index
    Stimuli.DelaySequence(end+1)=Parameters.MemDelay_Short(idx); %what was the delay
    
end

%Preset what the selected indexes /could/ be (we may not be able to use all
%of them because of the need to match to the same number of VPC trials)
Leftover_stimuli=Stimuli.SelectedIdxs;

ImageNames={};

%Now actually figure out the stimulus order in terms of the names of the image items
for StimulusCounter=1:length(ImageSequence)
    
    Category=ImageSequence(StimulusCounter); %Which category is this?
    
    if ~isempty(Leftover_stimuli.(StimulusLevelFolders(Category).name))
        
        iStimulus=Leftover_stimuli.(StimulusLevelFolders(Category).name)(1); %What texture to call --> choose the first one that hasn't been used for this category
        ImageIdxs{StimulusCounter}=iStimulus; %save where the index is

        %Update the leftover stimuli
        Leftover_stimuli.(StimulusLevelFolders(Category).name)=Leftover_stimuli.(StimulusLevelFolders(Category).name)(2:end);

        FileList = Stimuli.Filename.(Parameters.StimulusLevelNames{Category}); % Pull out the filenames

        %Get the path for the given file
        iImageName=[Parameters.StimulusDirectory, '/',StimulusLevelFolders(Category).name,'/' FileList{iStimulus}];
        ImageNames{end+1}=iImageName; %save the names as well
    
    end
    
end

%Save the images that we will be using with their paths --> note that these are just the encoding images
Stimuli.EncodingSequence=ImageNames;

%% Super fun horrible part: figure out the real order of everything --> encoding and VPC interleaved
% First set this up
Stimuli.FinalSequence=Stimuli.EncodingSequence;
Stimuli.CategorySequence=Stimuli.ImageSequence;
ActualDelays=[];

% Okay let's do it
for StimulusCounter=1:(length(Stimuli.DelaySequence))
    
    %First, what is the category of this image?
    Category=ImageSequence(StimulusCounter);
    
    %And what is the index?
    iStimulus=ImageIdxs{StimulusCounter};
    
    %Finally, what's the name of this image?
    ImageName=ImageNames{StimulusCounter};
    
    %Now find the VPC column this is in --> the row will always be 1
    %because this is the encoding image
    Temp=Stimuli.VPC_idxs.(StimulusLevelFolders(Category).name);
    [row, col]=find(Temp==iStimulus);
    VPC_novel=Temp(row+1,col); %indices the novel test
    
    %Now find out what image this novel test is
    %Need the relevant file names again
    FileList = Stimuli.Filename.(Parameters.StimulusLevelNames{Category}); % Pull out the filenames
    VPC_ImageName=[Parameters.StimulusDirectory, '/',StimulusLevelFolders(Category).name,'/' FileList{VPC_novel}];
    
    %For now, we will put all of the encoding images on the left
    %The side of presentation will be done during the experiment
    VPC_Pair={{ImageName; VPC_ImageName}};
    
    %Tricky part! We want the delay to be in terms of encoding images, not
    %VPCs. So count the number of non-VPCs that follow the Stimulus Counter
    %and make that equal the delay
    
    %BUT NOTE: the stimulus may have been moved up (ooooh) so the stimulus
    %counter may not be correct in this sense --> so we need to find the
    %index of where the image we want is
    isName = cellfun(@(x)isequal(x,ImageNames{StimulusCounter}),Stimuli.FinalSequence);
    [row,col] = find(isName);
    FinalCounter=col;
    DelayCounter=1;
    
    %if the VPC needs to be inserted somewhere in the final sequence
    if FinalCounter+Stimuli.DelaySequence(StimulusCounter)<=length(Stimuli.FinalSequence)
        
        if sum(~cellfun(@iscell,Stimuli.FinalSequence(FinalCounter+1:FinalCounter+Stimuli.DelaySequence(StimulusCounter))))==Stimuli.DelaySequence(StimulusCounter)
            
            %if there are no VPCs in between, then the delay is as we expected
            DeterminedDelay=Stimuli.DelaySequence(StimulusCounter);
            
        else
            %however if there are cells in between and we do not have the right
            %number of encoding items in between, add to the list and find the
            %delay that is appropriate
            DelayCounter=1;
            delay_not_found=1; %preset to 1 each time
            
            while delay_not_found==1
                
                % If the delay will not put you over the length of the
                % stimulus
                if FinalCounter+Stimuli.DelaySequence(StimulusCounter)+DelayCounter<=length(Stimuli.FinalSequence)
                    
                    %add another element to that delay
                    new_delay_seq=Stimuli.FinalSequence(FinalCounter+1:FinalCounter+Stimuli.DelaySequence(StimulusCounter)+DelayCounter);
                
                %If it does, just tag it to the end
                else
                    new_delay_seq={};
                    delay_not_found=0;
                    DeterminedDelay=length(Stimuli.FinalSequence)-FinalCounter;
                end
                
                if sum(~cellfun(@iscell,new_delay_seq))==Stimuli.DelaySequence(StimulusCounter)
                    
                    %if the number in between is correct, break the loop and
                    %use this as the delay
                    DeterminedDelay=Stimuli.DelaySequence(StimulusCounter)+DelayCounter;
                    delay_not_found=0;
                    
                else
                    %keep trying
                    DelayCounter=DelayCounter+1;
                end
                
            end
            
        end
    
    %But if the delay is past the end of the stimulus, you need to just tag it on to
    %the end
    else
        DeterminedDelay=length(Stimuli.FinalSequence)-FinalCounter;
        
    end
    
    if FinalCounter+DeterminedDelay>=length(Stimuli.FinalSequence)
        
        ActualDelays(end+1)=DeterminedDelay;
        Stimuli.FinalSequence=[Stimuli.FinalSequence,VPC_Pair];
        Stimuli.CategorySequence=[Stimuli.CategorySequence,Category];
    else
        ActualDelays(end+1)=DeterminedDelay;
    
        %FINALLY we are going to insert this VPC at the appropriate delay
        Stimuli.FinalSequence=[Stimuli.FinalSequence(1:FinalCounter+DeterminedDelay),VPC_Pair,Stimuli.FinalSequence(FinalCounter+DeterminedDelay+1:end)];
           
        %And also update the category sequence 
        Stimuli.CategorySequence=[Stimuli.CategorySequence(1:FinalCounter+DeterminedDelay),Category,Stimuli.CategorySequence(FinalCounter+DeterminedDelay+1:end)];
        
    end
    
end

%Save the actual delays of the sequences (minus the ITIs)
Stimuli.ActualDelays=ActualDelays;

%This tells you if each trial is a VPC trial or not
Stimuli.isVPCTrial=cellfun(@iscell,Stimuli.FinalSequence);

%Finally, let's decide on the ITIs here so we can get a sense of the timing
%structure (and thus the memory delays) before running the experiment
Stimuli.ITI_Times=[];
for TrialCounter=1:length(Stimuli.FinalSequence)
    random_ITI=randi(length(Parameters.ITITime));% Randomly select the ITI
    Stimuli.ITI_Times(end+1)=Parameters.ITITime(random_ITI);
end

extra_counts=[];

%Calculating the time between encoding and test for each stimulus
Stimuli.ActualDelay_Secs=[];
for StimulusCounter=1:length(Stimuli.EncodingSequence)
    
    %First find out where this is in the Final Sequence
    isName = cellfun(@(x)isequal(x,ImageNames{StimulusCounter}),Stimuli.FinalSequence);
    [row,col] = find(isName);
    FinalCounter=col;
    
    %The index of the VPC is then this counter + the actual delay + 1

    if ~isnan(ActualDelays(StimulusCounter)) %But only if you are actually testing this image 
        
        % don't just guess where the image is, find it
        found_vpc=0;
        extra_count=0;
        
        while found_vpc==0
            Temp_idx=FinalCounter+ActualDelays(StimulusCounter)+extra_count; % Check this one
            
            if iscell(Stimuli.FinalSequence{Temp_idx}) && ~isempty(strfind(Stimuli.FinalSequence{Temp_idx}{1},ImageNames{StimulusCounter}))
                VPC_idx=Temp_idx;
                found_vpc=1;
            
            else
                extra_count=extra_count+1;
            end
        end
        extra_counts(end+1)=extra_count;
        
        %What are the intervening trials?
        intervening_trials=Stimuli.isVPCTrial(FinalCounter:VPC_idx);
        intervening_trials=double(intervening_trials); %change it to a double

        intervening_trials(intervening_trials==0)=Parameters.Encoding_Timing; % if it is 0 it is encoding 
        intervening_trials(intervening_trials==1)=Parameters.VPC_Timing; % if it is 1 it is a VPC

        %What are the intervening ITIS?
        intervening_ITIs=Stimuli.ITI_Times(FinalCounter:VPC_idx-1);

        Stimuli.ActualDelay_Secs(end+1)=sum(intervening_trials)+sum(intervening_ITIs);
    else
        Stimuli.ActualDelay_Secs(end+1)=NaN; %You didn't test this image
    
    end
end

TrialStructure.Parameters=Parameters;

TrialStructure.Stimuli=Stimuli;



end
