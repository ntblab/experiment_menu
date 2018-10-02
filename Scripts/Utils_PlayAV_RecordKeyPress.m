% % Function to allow experimenter to collect information about key presses without
% stopping or changing the video.
%
% Input = VideoStruct: specifies the screen and video name, and movie
% information such as start time
%
% Output = Response: records whether presses occurred
%
% TY 09/14/2018

function [Response, VideoStruct]=Utils_PlayAV_RecordKeyPress(varargin)

VideoStruct = varargin{1};
Response = varargin{5};

%Setting up the keyboard
[keyIsDown,keyCode_onset] = KbQueueCheck(VideoStruct.window.KeyboardNum);
keyCode=keyCode_onset>0;

%What keys do we care about?
if keyIsDown==1 && sum(keyCode)==1
    if strcmp(KbName(keyCode), 'e')                 %record "e" for "event" key press during movie
        Response.Quit=0;                            %don't quit out
        
        if isfield(Response, 'ResponseKey')         %if there has already been a key press, add to the end
            Response.ResponseKey(end+1)=KbName(keyCode);
            Response.ResponseTiming(end+1)=GetSecs-VideoStruct.MovieStartTime;
        
        else
            Response.ResponseKey=KbName(keyCode);
            Response.ResponseTiming=GetSecs-VideoStruct.MovieStartTime;
        end
        
    elseif strcmp(KbName(keyCode), 'q')         %we only want to quit out when they press q
            Response.Quit=1;                    %store their key press and stop the movie
            Response.ResponseTiming=GetSecs-VideoStruct.MovieStartTime;
            Response.ResponseKey=KbName(keyCode);
    end
end
    
end




