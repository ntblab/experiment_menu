% %Plays a video and/or audio track and potentially collects eye tracking data
%
% %Inputs
%
% VideoStruct: specifies the screen and video name. If there are two rows
% to rect and name then it will assume it is a simultaneous movie display
% AudioStruct: specifies the audio properties and the audio name
% TimingStruct: When do the stimuli start?
% InputStruct: Decide what information to take in, including what keyboard responses
% do and eye tracking
%
% %Outputs
%
% MovieTiming: includes the movie start and end time and also all the
% frame times. This is in terms of local time
% Response: describes whether key presses occurred and what the keys were
% GazeData: collects the fixation positions (as a matrix that can be
% analyzed using ParseGazeData. This also contains timing of each gaze
% packets, both in the local time and the eye tracker time.
% VideoStruct: movie-specific information such as movie duration, frames per
% second, and the time when movie started if it reloades
%
%
% Edited 09/14/2018 TY

function [MovieTiming, Response, GazeData]=Utils_PlayAV(VideoStruct, AudioStruct, TimingStruct, InputStruct)

MovieTiming=struct;
Response=struct;
GazeData=struct;

KbQueueFlush(VideoStruct.window.KeyboardNum); %listen for key presses

MovieTiming.TR=[];
Quit=0;

%%Extract the information for the study

%Pull out the video information if there is any
if ~isempty(VideoStruct)
    isVideo=1;
    
    %Get screen info
    ScreenNumber=VideoStruct.window.onScreen;
    flipTime=VideoStruct.window.frameTime;
    Rect=VideoStruct.MovieRect;
    
    %What video name is being called?
    VideoName=VideoStruct.VideoNames;
    
    %How much of the movie has been watched previously? 0 means start from the start
    VideoStruct.TimeWhenMovieShouldStart=VideoStruct.MovieWatched;
    
    %Are there two movies?
    if length(VideoName)==2
        SimultaneousVideo=1;
        TempVideoName=VideoName{1};
    else
        SimultaneousVideo=0;
        TempVideoName=VideoName;
    end
    
    %Set up the movie
 
    [VideoStruct.movie{1}, VideoStruct.movieduration{1}, VideoStruct.fps{1}] = Screen('OpenMovie', ScreenNumber, TempVideoName);
    
    %Set where the movie should start from
  
    Screen('SetMovieTimeIndex', VideoStruct.movie{1}, VideoStruct.TimeWhenMovieShouldStart);

    %Wait for the burn in TR if appropriate
    if VideoStruct.window.isfMRI==1 && VideoStruct.WaitforTR==1
        
        [MovieTiming.TR, Quit]=Setup_WaitingForScanner(VideoStruct.window);
        
        %Calculate when is the next TR expected
        if ~isempty(MovieTiming.TR)
            VideoStruct.window.NextTR=MovieTiming.TR(end)+VideoStruct.window.TR;
        else
            VideoStruct.window.NextTR=VideoStruct.window.NextTR;
        end
        
    end
    
    %Start the movie
    Screen('PlayMovie', VideoStruct.movie{1},1); %Play the movie. The 1 represents the movie rate
    
    %Play a simultaneous movie if necessary
   if SimultaneousVideo==1
        [VideoStruct.movie{2}, VideoStruct.movieduration{2}, VideoStruct.fps{2}] = Screen('OpenMovie', ScreenNumber, VideoName{2});
        
         start movie
        Screen('PlayMovie', VideoStruct.movie{2},1); %Play the movie. The 1 represents the movie rate
        
    end
    
    %For default video control, how many seconds are you jumping ahead?
    VideoStruct.SkipAmount=5;
    
else
    isVideo=0;
end

%Pull out the audio information if there is any
if ~isempty(AudioStruct)
    
    %Will it play an error if there is a key press?
    isError=AudioStruct.isError;
    
    %If there is an error then pull it out and save it
    if isError==1
        Error=AudioStruct.Error;
        Errorfs=AudioStruct.Errorfs;
    end
    
    %What is the name of the audio (only works if there is one, there might
    %just be an error)
    
    if sum(cell2mat(strfind(fieldnames(AudioStruct),'AudioName')))>0
        AudioName=AudioStruct.AudioName;
        isAudio=1;
        
        %Setting up the audio
        
        %Are you playing two audio streams?
        if length(AudioName)==2
            SimultaneousAudio=1;
        else
            SimultaneousAudio=0;
        end

        %either use one audio clip or combine them
        if SimultaneousAudio==0
            TempName=AudioName;
            
            AudioFile=audioread(TempName);
            
        else
            
            %make the audio streams play to different airs
            LeftEar=mean(audioread(AudioName{1}),2); %average them so they are mono
            RightEar=mean(audioread(AudioName{2}),2);
            
            if size(LeftEar,1)~=size(RightEar,1)
                
                %Pull out which ear has fewer samples and which one has
                %more in order to economize code.
                
                if size(LeftEar,1)>size(RightEar,1)
                    
                    LowerEar=RightEar;
                    HigherEar=LeftEar;
                    
                    TempName=AudioName{1}; %Store the name of the clip with the higher sampling rate

                    
                elseif size(LeftEar,1)<size(RightEar,1)
                    
                    LowerEar=LeftEar;
                    HigherEar=RightEar;
                    
                    TempName=AudioName{2}; %Store the name of the clip with the higher sampling rate
                end
                
                
                %Heavily compressed mp3s cause there to be pauses at the
                %start and end which will mess with timing. To correct for
                %this we cut them off before 
                
                Lagsize=100; %How big is the moving window
                MinimumTrim=0.01;
                
                %Trim the start
                
                TrimContinue=1;
                TrimCounter=Lagsize;
                
                while TrimContinue==1
                    
                    
                    Idx=TrimCounter-Lagsize:TrimCounter;
                    
                    Idx=Idx(Idx>0); %Ignore negative values
                    
                    MovingWindowAverage=mean(abs(LowerEar(Idx)));
                    
                    if MovingWindowAverage>MinimumTrim
                        StartingSample=min(Idx);
                        TrimContinue=0;
                    else
                        TrimCounter=TrimCounter+1;
                    end
                end
                
                
                %Trim the end
                TrimContinue=1;
                TrimCounter=length(LowerEar)-Lagsize;
                
                while TrimContinue==1
                    
                    
                    Idx=TrimCounter-Lagsize:TrimCounter;
                    
                    Idx=Idx(Idx<=length(LowerEar)); %Ignore excessive values
                    
                    MovingWindowAverage=mean(abs(LowerEar(Idx)));
                    
                    if MovingWindowAverage>MinimumTrim
                        EndingSample=min(Idx)+1;
                        TrimContinue=0;
                    else
                        TrimCounter=TrimCounter-1;
                    end
                end
                
                %Take this trimmed number
                LowerEar=LowerEar(StartingSample:EndingSample);
                
                
                %Interpolate from the ear with the fewer samples to the one
                %with more
                LowerEar=interp(LowerEar, round(size(HigherEar,1)/size(LowerEar,1)))';
                
                if size(LeftEar,1)>size(RightEar,1)
                    RightEar=LowerEar(1:end-1)';
                else
                    LeftEar=LowerEar(1:end-1)';
                end
                
                
            else
                TempName=AudioName{1}; %Doesn't matter if no difference
            end

            
            %Throw warning if the above doesn't fix it
             %if length(RightEar) ~= length(LeftEar)
             %    warning('AUDIO NOT SAME SAMPLING RATE');
             %end
            
            %Store the audio (or as much as possible)
            AudioFile=[LeftEar(1:min([length(LeftEar), length(RightEar)])), RightEar(1:min([length(LeftEar), length(RightEar)]))];
            
        end
        
        %Get the details on this audio, specifically you need the sample rate
        
        AudioInfo=audioinfo(TempName);
        
        %Load the audio, it will run much faster now.
        AudioObject=audioplayer(AudioFile, AudioInfo.SampleRate);
        
        
        %Get the movieduration it isn't coming from the video
        if isVideo==0
            VideoStruct.movieduration=AudioInfo.Duration;
        end
            
    end
    
else
    isError=0;
    isAudio=0;
end

%What timing informationis being fed in?
if ~isempty(TimingStruct)
    
    %When will it start?
    PlannedOnset=TimingStruct.PlannedOnset;
    
    %Should you preload the movie?
    Preload=TimingStruct.Preload;
    
else %Default to run immediately
    Preload=0;
    PlannedOnset=0;
end


%What do you do with your input structure information

if ~isempty(InputStruct)
    
    isEyeTracking=InputStruct.isEyeTracking; %Is eye tracking being used?
    
    %If you would like to use responses to terminate, use this line
    %isResponseTermination= InputStruct.isResponseTermination; %Will the movie terminate if a key is pressed?
    
    % Decide how to treat user responses
    if isfield(InputStruct, 'Response_function')    
        PlayAV_response_function=InputStruct.Response_function; 
    else
        PlayAV_response_function=str2func('Utils_PlayAV_Video_Control'); %if not specified, default to video control
    end
    
end

%Wait to initiate the experiment
if isVideo
    Screen('Flip',ScreenNumber, PlannedOnset); %Flip screen after
elseif isAudio
    
    while GetSecs<PlannedOnset
    end
end

StartedMov=0; %Set so the inital can be recorded
VideoStruct.movieRestart=GetSecs; %Just in case

%Preallocate texture IDs if preloading (so as to speed things up)
if Preload==1
    texids=zeros(1,ceil(VideoStruct.movieduration{1}*VideoStruct.fps{1}));
    texcounter=1;
end

%Playback loop: Runs until end of movie or keypress, if that key press
%terminates the movie

%Initialize
VideoStruct.MovieStartTime=GetSecs; %When does the movie start
Stillframes=1; %Are there still frames to be played?
FrameCounter=1;
Response.Quit=0; 
Response.StopMovie=0;

if isVideo
    MovieTiming.Frames.Local=zeros(ceil(VideoStruct.movieduration{1}*VideoStruct.fps{1}),1); %Present size
    
    %Output the duration of the video that will be played
    fprintf('\n\n Movie duration: %0.2f seconds\n\nStarting at %0.2f seconds\n\nTime now: %s\n\n', VideoStruct.movieduration{1}, VideoStruct.TimeWhenMovieShouldStart, datestr(now));
end

%If you are playing video then go through this, otherwise wait
if isVideo && Quit==0
    
    while Stillframes==1
        
        %If you are preloading trials then do it now, otherwise
        %just play the clip
        
        if Preload==0
          
            %Checks for responses
            [Response, VideoStruct] = PlayAV_response_function(VideoStruct, AudioStruct, TimingStruct, InputStruct, Response); 
            
            if Response.Quit==1 || Response.StopMovie==1
                fprintf('Stopping movie\n'); 
                break;
            end
            
            % Wait for next movie frame, retrieve texture handle to it
            tex{1} = Screen('GetMovieImage', ScreenNumber, VideoStruct.movie{1});
            
            if SimultaneousVideo==1
                tex{2} = Screen('GetMovieImage', ScreenNumber, VideoStruct.movie{2});
            end
            
            % Valid texture returned? A negative value means end of movie reached:
            if tex{1}<=0
                % We're done, break out of loop:
                Stillframes=0;
                
                break
            end
            
            
            % Draw the new texture immediately to screen:
            Screen('DrawTexture', ScreenNumber, tex{1}, [], Rect(1,:));
            
            if SimultaneousVideo==1
                Screen('DrawTexture', ScreenNumber, tex{2}, [], Rect(2,:));
            end
            
            % Update display:
            if StartedMov==0 %Is it the first frame?
                
                if isAudio
                    play(AudioObject); %Play audio (only ~80ms to run)
                end
                
                movieStart=Screen('Flip', ScreenNumber);
                VideoStruct.movieRestart=movieStart; %Set as a baseline
                
                %The first frame has been played
                StartedMov=1;
                
                %Store the timing of this frame
                MovieTiming.Frames.Local(FrameCounter)=movieStart;
                
            else
                
                TRRecording=Utils_checkTrigger(VideoStruct.window.NextTR, VideoStruct.window.ScannerNum); %Returns the time if a TR pulse happened recently
                
                %If there is a recording then update the next TR time and store
                %this pulse
                if any(TRRecording>0)
                    MovieTiming.TR(end+1:end+length(TRRecording))=TRRecording;
                    VideoStruct.window.NextTR=VideoStruct.window.TR+max(TRRecording);
                end
                
                %Get the timing of the frame
                MovieTiming.Frames.Local(FrameCounter)=Screen('Flip', ScreenNumber);
                
            end
            
            %Increment
            FrameCounter=FrameCounter+1;
            
            % Release texture:
            Screen('Close', tex{1});
            
            if SimultaneousVideo==1
                Screen('Close', tex{2});
            end
            
        elseif Preload==1 %If preloading then just iterate through them all
            
            while (1)
                % Wait for next movie frame, retrieve texture handle to it
                tex{1} = Screen('GetMovieImage', ScreenNumber, VideoStruct.movie{1});
                
                if tex{1}<=0
                    % We're done, break out of loop:
                    Stillframes=0;
                    break
                end
                
                texids(texcounter)=tex{1};
                texcounter=texcounter+1;
            end
        end
    end
    
    if Preload==1
        %If you are preloading then now all the items have been
        %preloaded and you can play them as usual.

        texcounter=1;
        
        while texcounter<=length(texids)
            Screen('DrawTexture', ScreenNumber, texids(texcounter), [], Rect);
            
            
            % Update display:
            
            if StartedMov==0
                
                
                %Play audio if appropriate
                if isAudio
                    play(AudioObject); %Play audio (only ~80ms to run)
                end
                
                %Determine texture onset times
                TexOnsets=(VideoStruct.movieduration{1}/max(texids):VideoStruct.movieduration{1}/length(texids):VideoStruct.movieduration{1})+GetSecs;
                
                %Wait for the first TR if appropriate
                if VideoStruct.window.isfMRI==1 && VideoStruct.WaitforTR==1
              
                    [MovieTiming.TR, Quit]=Setup_WaitingForScanner(VideoStruct.window);
                    
                    %Calculate when is the next TR expected
                    if ~isempty(MovieTiming.TR)
                        VideoStruct.window.NextTR=MovieTiming.TR(end)+VideoStruct.window.TR;
                    end
                    
                    %Was a quit command issued?
                    if Quit==1 
                        Response.Anticipationresponse=1;
                        Response.AnticipationresponseTiming=GetSecs-VideoStruct.MovieStartTime;
                        Response.Anticipationbutton=KbName(keyCode);
                        
                        %Break now that the data has been recorded
                        break
                    end
                end
                
                movieStart=Screen('Flip', ScreenNumber, TexOnsets(texcounter)-flipTime);
                StartedMov=1;
            else
                TRRecording=Utils_checkTrigger(VideoStruct.window.NextTR, VideoStruct.window.ScannerNum); %Returns the time if a TR pulse happened recently
                
                %If there is a recording then update the next TR time and store
                %this pulse
                if any(TRRecording>0)
                    MovieTiming.TR(end+1:end+length(TRRecording))=TRRecording;
                    VideoStruct.window.NextTR=VideoStruct.window.TR+max(TRRecording);
                end
                
                Screen('Flip', ScreenNumber, TexOnsets(texcounter)-flipTime);
            end
            
            % Release texture:
            Screen('Close',  texids(texcounter));
            
            texcounter=texcounter+1;
        end
        movieEnd=GetSecs;
        
        
    elseif Preload==0
        %If they aren't preloading then it is done now
        movieEnd=GetSecs;
        
       
    end
  
    % Stop playback and get the number of frames dropped:
    DroppedFrames=Screen('PlayMovie', VideoStruct.movie{1}, 0);
    
    % Close movie:
    Screen('CloseMovie', VideoStruct.movie{1});
    
    if SimultaneousVideo==1
        DroppedFrames(end+1)=Screen('PlayMovie', VideoStruct.movie{2}, 0);
        Screen('CloseMovie', VideoStruct.movie{2});
    end
    
    %Just incase all the texts haven't been cleared
    Screen('Close');
    
    %So that the movie isn't paused here
    Screen('Flip',VideoStruct.window.onScreen);
    
elseif isAudio==1%If there is no video playing then jump ahead and just play audio
    
    play(AudioObject); %Play audio (only ~80ms to run)
    
    %When do the movies start?
    movieStart=GetSecs;
    
    %Check for a key press. Play error sound and record that
    %information if there is one
    while GetSecs< (VideoStruct.movieduration+ movieStart) %Keep waiting for response until the audio ends
        
        [Response, VideoStruct] = PlayAV_response_function(VideoStruct, AudioStruct, TimingStruct, InputStruct, Response);
        
    end
    
    %Store end of stim information
    movieEnd=GetSecs;
    DroppedFrames=0;
    
end

%Store the data (if there is any)

if StartedMov==1
    MovieTiming.movieStart.Local=movieStart;
    MovieTiming.movieEnd.Local=movieEnd;
    MovieTiming.DroppedFrames=DroppedFrames;
    
else
    movieStart=0;
    movieEnd=0;
end


%Store elapsed movie duration % Just commented out isResponseTermination==1 && 
if  VideoStruct.TimeWhenMovieShouldStart>VideoStruct.movieduration{1}
    Response.MovieElapsed=0; %If you enable playback controls then restart when finished
else
    Response.MovieElapsed= movieEnd-movieStart + VideoStruct.TimeWhenMovieShouldStart;
end


end