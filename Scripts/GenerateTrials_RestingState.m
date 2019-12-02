%% Generate Trial sequence and conditions for resting state
%
%Use only the defaults, no stimuli are needed.
%
%C Ellis 7/28/16

function TrialStructure=GenerateTrials_RestingState(varargin)

%Put only the necessary information
Parameters.BlockNum=1;
Parameters.BlockNames={'Endless'};
Stimuli.SelectedStimuli_Names='';

%% Store the outputs

TrialStructure.Parameters=Parameters;

TrialStructure.Stimuli=Stimuli;
