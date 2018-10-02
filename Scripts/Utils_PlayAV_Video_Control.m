% % Function to allow video control to jump forward and backwards in
% movies, in addition to changing the volume or quitting out of the movie
%
% Input = VideoStruct: specifies the screen and video name. If there are two rows
% to rect and name then it will assume it is a simultaneous movie display
%
% Output = Response: describes whether presses occurred
%
% 09/07/2018 TY


function [Response, VideoStruct] = Utils_PlayAV_Video_Control(varargin)

VideoStruct = varargin{1};
Response = varargin{5};


%What video name is being called?
VideoName=VideoStruct.VideoNames;

%Check for a key press. If it is an arrow key then skip
%ahead or back in the movie. If it is anything else then
%record this and break

[keyIsDown,keyCode_onset] = KbQueueCheck(VideoStruct.window.KeyboardNum);
keyCode=keyCode_onset>0;

if keyIsDown==1 && sum(keyCode)==1
    
    %Interpret the response
    if strcmp(KbName(keyCode), 'LeftArrow') || strcmp(KbName(keyCode), 'RightArrow') %Rewind the movie
        if strcmp(KbName(keyCode), 'LeftArrow')
            
            %What time is it now?
            VideoStruct.TimeWhenMovieShouldStart = GetSecs - VideoStruct.movieRestart + VideoStruct.TimeWhenMovieShouldStart - VideoStruct.SkipAmount;
            
            %If you drop below zero for timing then update to zero
            VideoStruct.TimeWhenMovieShouldStart(VideoStruct.TimeWhenMovieShouldStart<0)=0;
            
        elseif strcmp(KbName(keyCode), 'RightArrow')
            
            %What time is it now?
            VideoStruct.TimeWhenMovieShouldStart = GetSecs - VideoStruct.movieRestart + VideoStruct.TimeWhenMovieShouldStart + VideoStruct.SkipAmount;
            
        end
        
        %Report what happened
        fprintf('Skipping to %0.2f\n\n', VideoStruct.TimeWhenMovieShouldStart);
        
        %Stop the movie(s)
        Screen('CloseMovie', VideoStruct.movie{1});
        
        %Just incase all the texs haven't been cleared
        Screen('Close');
        
        %Are there two movies?
        if length(VideoStruct.VideoNames)==2
            SimultaneousVideo=1;
            TempVideoName=VideoStruct.VideoName{1};
        else
            SimultaneousVideo=0;
            TempVideoName=VideoName;
        end
        
        %Open the movie
        [VideoStruct.movie{1}, VideoStruct.movieduration{1}, VideoStruct.fps{1}] = Screen('OpenMovie', VideoStruct.window.onScreen, TempVideoName);
        
        %Set where the movie should start from
        Screen('SetMovieTimeIndex', VideoStruct.movie{1}, VideoStruct.TimeWhenMovieShouldStart);
        
        % start movie
        Screen('PlayMovie', VideoStruct.movie{1},1); %Play the movie. The 1 represents the movie rate
        
        % Do the same if there is a second movie to play
        if SimultaneousVideo==1
            %Open the movie
            [VideoStruct.movie{2}, VideoStruct.movieduration{2}, VideoStruct.fps{2}] = Screen('OpenMovie', VideoStruct.window.onScreen, VideoStruct.VideoName{2});
            
            %Set where the movie should start from
            Screen('SetMovieTimeIndex', VideoStruct.movie{2}, VideoStruct.TimeWhenMovieShouldStart);
            
            % start movie
            Screen('PlayMovie', VideoStruct.movie{2},1); %Play the movie. The 1 represents the movie rate
            
        end
        
        %What time did you restart the movie
        VideoStruct.movieRestart=GetSecs;
        
    elseif strcmp(KbName(keyCode), 'F10') || strcmp(KbName(keyCode), 'F11') || strcmp(KbName(keyCode), 'F12')
        
        fprintf('Changing the volume\n\n');
        
    else
        % Store their key press and stop the movie
        Response.StopMovie=1;
        Response.ResponseTiming=GetSecs-VideoStruct.MovieStartTime;
        Response.ResponseKey=KbName(keyCode);
        
        if strcmp(KbName(keyCode), 'q')
            Response.Quit=1;
        end
        
    end
end

