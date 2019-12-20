
%% Generate the stimuli sequences for the PosnerCuing experiments
%
% This code generates stimuli sequences for Posner cuing.
%
% This is set up by default to only use peripheral cuing but can be changed
% to use central images as the cues
%
%Created C Ellis 12/14/15

function TrialStructure=GenerateTrials_PosnerCuing(varargin)


%What are the parameters for this experiment?

Parameters.StimEccentricity = 10; %How many visual degrees is the cue away from the midline?

Parameters.ValidityProportion =[.5,.25,.25]; %What proportion of trials will the cue predict the target location, cue be invalid or cue be neutral?

Parameters.TargetLocations = 2; %How many target locations are there?

Parameters.CueTiming= 0.1; %What is cue timing duration?

Parameters.TimingSteps = 1; %How many cue target timing steps are there? (i.e. how many interpolated steps are there between the min and max range?)

Parameters.MinCueTargetTiming= [0.1 1]; %What is the min cue target timing for the different blocks?

Parameters.MaxCueTargetTiming= [.6 2]; %What is the max of the above?

Parameters.MinimumTrials=max(1./Parameters.ValidityProportion(Parameters.ValidityProportion>0)) * Parameters.TargetLocations; %A multiple of the validity value by side of display

Parameters.TrialNumber=Parameters.MinimumTrials; %How many times will you iterate through the trials?

%Store the block names
% Assuming only peripheral cuing
Parameters.BlockNames={'Exogenous'}; % {'Exogenous', 'Endogenous'}; 

Parameters.BlockNum=length(Parameters.BlockNames); 

Parameters.DecayTime=12; %How long does the code need to wait before it can initiate a new experiment

%Generate the trial list, not shuffled

for BlockCounter=1:Parameters.BlockNum
    
    %Generate the different timing conditions
    
    Interval=(Parameters.MaxCueTargetTiming-Parameters.MinCueTargetTiming)/Parameters.TimingSteps; %How far apart are the values supposed to be spaced out?
    
    TimingLevels= Parameters.MinCueTargetTiming(BlockCounter) : Interval : Parameters.MaxCueTargetTiming(BlockCounter); %Make a temporary list of the timing
    
    TimingLevels=TimingLevels(1:end-1); %Take away the last timing value.
    
    Trial_Amounts = Parameters.ValidityProportion * Parameters.TrialNumber;
    
    Trialtypes=[repmat(1, 1, Trial_Amounts(1)), repmat(2, 1, Trial_Amounts(2)), repmat(3, 1, Trial_Amounts(3))];
    
    Counter=1;
    for Repetitions=1 : (Parameters.TrialNumber/Parameters.MinimumTrials) %How many times do you repeat the trials?
        
        for TimingCounter= 1: Parameters.TimingSteps %How many different CueTargetTimes are there?
            
            CueTargetTime=TimingLevels(TimingCounter); %What is the time for this iteration?
            
            for ValidityCounter=1:Parameters.MinimumTrials/Parameters.TargetLocations %How many validity levels are there?
                
                for TargetCounter=1 : Parameters.TargetLocations %How many target locations are there
                    
                   
                    %Decide what kind of cue to present
                    
                    if Trialtypes(Counter)==1
                        
                        %If it is valid then it is in a target position
                        CueCounter=TargetCounter;
                        
                        %Is it an invalid iteration
                    elseif Trialtypes(Counter)==2
                        
                        %If it is invalid then make it in a non-target position
                        CueCounter= Parameters.TargetLocations+1-TargetCounter;
                    elseif Trialtypes(Counter)==3
                        
                        CueCounter=0;
                    end
                    
                    
                    Stimuli.StimulusSequence(Counter,:, BlockCounter)=[CueCounter, TargetCounter, Parameters.CueTiming(BlockCounter), CueTargetTime];
                    
                    Counter=Counter+1;
                end
            end
        end
    end
    
end

%State the critical location of the stimuli
Stimuli.EyeTrackerCalib_Locations= [-1*Parameters.StimEccentricity, 0; Parameters.StimEccentricity, 0];

%Store the generated variables
TrialStructure.Parameters=Parameters;
TrialStructure.Stimuli=Stimuli;