%% Modify the generate trials for Play Video
%
% This allows you to change the movie size

function [GenerateTrials, PrintText_List] = GenerateTrials_Modify_PlayVideo(Window, GenerateTrials, Data, DecayLapse, MostRecentExperiment)


% If you haven't stored this yet then do it now
if ~isfield(GenerateTrials.Experiment_PlayVideo.Parameters, 'Default_Rect')
    GenerateTrials.Experiment_PlayVideo.Parameters.Default_Rect = GenerateTrials.Experiment_PlayVideo.Parameters.Rect;
end

% Figure out the screen size for this and the default
x_width = abs(GenerateTrials.Experiment_PlayVideo.Parameters.Rect(1) - Window.centerX);
y_width = abs(GenerateTrials.Experiment_PlayVideo.Parameters.Rect(2) - Window.centerY);

default_x_width = abs(GenerateTrials.Experiment_PlayVideo.Parameters.Default_Rect(1) - Window.centerX);
default_y_width = abs(GenerateTrials.Experiment_PlayVideo.Parameters.Default_Rect(2) - Window.centerY);

PrintText_List={};
PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('You can change The size of the movies\nCurrent ppd width: %0.2f\nDefault ppd width: %0.2f\n\n', x_width, default_x_width));

PrintText_List=Utils_PrintText(Window, PrintText_List,  '\n\nWould you like to enlarge (''l'' key) the movie size, shrink (''s'' key) the size or return to default (''d'' key)?\nPress ''q'' to quit.\n\n');

%Record a response

%Prep inputs to the listen response
InputStruct.MaxResponseLength=1;
InputStruct.ValidResponse='q';
InputStruct.InvalidResponse='';
DecayStruct.DecayLapse=DecayLapse; %When should the Decay lapse?
DecayStruct.MostRecentExperiment=MostRecentExperiment; %What is the name of the last experiment run?

%Listen for a response and store the output
[Str, TRData, Window.ScannerisRunning, Window.NextTR]=Setup_ListenandRecordResponse(Window, DecayStruct, InputStruct);

%Add the new TR data. If the scanner isn't on this
%does nothing
Data.Global.Timing.TR(end+1:end+length(TRData))=TRData;

%Store the TRs with the last data collected if appropriate
if ~isempty(MostRecentExperiment.Name)
    Data.(MostRecentExperiment.Name).(MostRecentExperiment.Block).Timing.TR(end+1:end+length(TRData))=TRData;
end

%Interpret response
if strcmp('l', Str)
    
    x_width = x_width * 1.5;
    y_width = y_width * 1.5;
    
    PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Increasing the movie size\n\n\'));
elseif strcmp('s', Str)
    
    x_width = x_width / 1.5;
    y_width = y_width / 1.5;
    
    PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Decreasing the movie size\n\n'));
        
elseif strcmp('d', Str)
    
    x_width = default_x_width;
    y_width = default_y_width;
    
    PrintText_List=Utils_PrintText(Window, PrintText_List, sprintf('Returning to the defaults\n\n'));
            
else
    PrintText_List=Utils_PrintText(Window, PrintText_List,  'No change was made\n\n');
end

GenerateTrials.Experiment_PlayVideo.Parameters.Rect=[Window.centerX - x_width, Window.centerY - y_width, Window.centerX + x_width, Window.centerY + y_width];