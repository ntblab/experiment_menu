%% Generate Trial sequence and conditions for resting state
%
%Use only the defaults, no stimuli are needed.
%
%C Ellis 7/28/16
% Add fixation stimulus if wanted 1/26/2022

function TrialStructure=GenerateTrials_RestingState(varargin)

% need window in order to get keyboard info
Window = varargin{4};

%Put only the necessary information
Parameters.BlockNum=1;
Parameters.BlockNames={'Endless'};
Stimuli.SelectedStimuli_Names='';

%% Store the outputs

% Ask what condition you want to use
fprintf('\nBlank screen, or fixation stimulus? Press a key to continue, or "q" to quit\n')
fprintf(' 1: blank screen\n 2: fixation cross\n')   

% wait until a valid option
fixation=-1;
while fixation==-1
    
    pause(0.2);
    KbName('UnifyKeyNames');
    [~, keyCode]=KbWait(Window.KeyboardNum);

    % choose the condition order
    if strfind(KbName(keyCode), '1')==1
        fixation=0; % no fixation
        
    elseif strfind(KbName(keyCode), '2')==1
        fixation=1; % during the experiment, a cross will be created 
 
    elseif strfind(KbName(keyCode), 'q')==1
       fprintf('\nquitting\n')
       TrialStructure = [];
       return; 
        
    else
        fprintf('\nPlease choose a valid option\n')
    end
    
    pause(0.2);
end

Parameters.fixation=fixation; % save it 

TrialStructure.Parameters=Parameters;

TrialStructure.Stimuli=Stimuli;
