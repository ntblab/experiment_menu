%% Run a block of the Retinotopy experiment.
%
% The default parameters for this script are set to run the meridian
% mapping and spatial frequency blocks of the retinotopy experiments. In
% each block, one phase of each condition is presented for 20s, with no
% break in between. The stimuli for these trials are pulled from
% Stimuli/RetinotopyStimuli/ and Stimuli/RetinotopySF/
%
% DISCLAIMER, this is a frankenstein script and will likely be very hard to
% read. First it was written by two people (first Vikranth Bejjanki and
% then Cameron Ellis) and has become very convoluted. This is because this
% same script was adapted for different iterations of retinotopy
% experiments (some with infants, some with adults). Indeed, since much of
% the functionality of this script is legacy, many of the alternative
% parameters shouldn't expected to run because of missing files.
% Nonetheless it was included to ensure that the script made public is the
% same script that we used, in case there are any bugs (hope there is not!)
%
% This takes in a set of condition information and then selects the relevant
% conditions and executes it.
% This also takes in the window information, including the restricted
% presentation range, and it is assumed that the screen has already been
% set up when this is run
%
%V Bejjanki 2/12/16 Updated 05/11/16
%C Ellis 8/27/16 Added redundancy
%C Ellis 10/31/16 Changed the redundancy procedure to make it build in.
%C Ellis 7/27/17 Changed the response to KbQueue

function Data = Experiment_Retinotopy(varargin)

%Set variables
block=varargin{1};
wind=varargin{2};
gTrialConds=varargin{3};

type = gTrialConds.Parameters.BlockNames{block};
fprintf('\n\nRetinotopy. Block: %d, Block_Label: %s\n\n', block, type);

if gTrialConds.Parameters.TravellingWave~=1
    fprintf('Travelling wave is not being used\n\n');
end

rand_img_index = randi(32);   %Total of 32 images available to choose from
%PARAMETERS--------------------------------

% Set size of screen to display background images
% Leave to max if unsure - Better to scale wedge and ring stimuli directly
% below
stim_r = 'max';                % stimulus radius (deg), max for maximum screen size

% Stimulus Properties
rot_period =  gTrialConds.Parameters.rot_period;           % rotation period of wedge or ring
Redundancy =  gTrialConds.Parameters.Redundancy;           % How much extra time will you sample
FixationStimulus=gTrialConds.Parameters.FixationStimulus;  % What do you want as the fixation stimulus: 0) None, 1) Movie, 2) Faces
iswedge=gTrialConds.Parameters.iswedge;
AttentionTask=gTrialConds.Parameters.AttentionTask;        % Do you want there to be an attention task during the experiment
if FixationStimulus == 1
    MovieLength=gTrialConds.Parameters.MovieLength;            % How long is the movie
    MovieName=gTrialConds.Parameters.MovieName;                % What is the move name
end
ncycles =gTrialConds.Parameters.NumRepetitions;            % number of rotation cycles
motion_envelope=gTrialConds.Parameters.Fix_motion_envelope;% How much movement is there in the fixation dot attention task
motion_freq=gTrialConds.Parameters.Fix_motion_frequency;   % How much movement is there in the fixation dot attention task

fprintf('Redundancy set to %d seconds', Redundancy);

%change rot period to be a increment of your TR


color_check =  1;           % 0 for B&W, 1 for color
flicker_freq = 4;           % flicker frequency for full black-white cycle (hz)
flickstim =   0;           % Flicker Stimulus 0 for checks, 1 for black
min_switch =  5;           % minimum time between dimming events
max_switch =  15;           % max time between dimming events
%Extra Parameter - keep to 0 if unsure
checker_rot =    0;           % rotation period of in backgroud checks; 0 for no rotation (does not work on other stim)

DecayLapse = gTrialConds.Parameters.DecayLapse;            %blank time at end (sec)   -> 8 TRs @ 1.5s or 6 TRs @ 2s

%fixation mask
fmask_size = gTrialConds.Parameters.fmask_size;           % Radius of black mask around fixation in degrees
fp_size=0.2;                   % How many pixels in size is the fixation
fcolor= [255 255 255];       % fixation color
min_fix=2;                  % minimum time between fixation point dims
max_fix=5;                  % max time between fixation point dims

%Face image
fimg_baseDiam = 3.5;         % Maximum diameter of fixation image
fimg_smDiam = 1.0;           % Minimum diameter of fixation image


%Wedge Properties

wedge_size=   45;           % default size in degrees of a circle,

cut_out=      gTrialConds.Parameters.cut_out;           % cut out n deg (radius) of center
cut_in=       gTrialConds.Parameters.cut_in;           % cut in n deg (radius) from outer max; equals max eccen of wedge
start_angle=  90;           % right horizontal meridian (0 is top, going cw_out), where to start in degree

%Ring Properties
duty = .125;                % Set duty cycle .125 = 12.5%
r_outer_deg_max = 14;              % Set outer max (radius) for ring
r_inner_deg_min = 0;               % Set inner min (radius) for ring
scaling = 2;                % 1 for linear, 2 for logarithmic

% Attention task
dim_value = [137 137 137];  % dim color for attention task
dim_length=.7;            % amount dimmed for (in sec)
%if atten_task == 2
atten_ring =   3;           % atten ring duty cycle (width) when running polar angle
atten_wedge = 360;          % degress of atten wedge size when runing eccentricity

%Key Codes
KbName('UnifyKeyNames');
but1 = KbName({'1!', '2@', '3#', '4$', '1', '2', '3', '4'});        %Button box buttons

if ~any(strcmp(type, {'highlow'; 'lowhigh'}))
    stim  = 1;                  % 1 for checkerboard  - Future editions will use other sitmuli
else
    stim  = 0; % Don't show anything
end

%End of Parameters-------------------------------------------------------------------

w = wind.onScreen;
rect = wind.Rect;
if isfield(gTrialConds.Parameters, 'background')
    bcolor=gTrialConds.Parameters.background;
elseif FixationStimulus==2
    bcolor = wind.bcolor;
else
    bcolor = 0;
end

%find center of screen
xc = rect(3)/2;
yc = rect(4)/2;
max_viewing = round(sqrt((rect(4)^2)+(rect(3)^2)));          % maximum screen distance in radius (deg)

%Calculate pixels per degree.
ppd = wind.ppd;

% Get the fixation properties
fix_x = xc;
fix_y = yc;
fm_size=ppd*fmask_size;
fp_size=ppd*fp_size;

if stim_r == 'max'
    stim_r = min([xc yc])/ppd;
end

%Convert from ppd into pixels
StimSize=stim_r*2;
stim_r=stim_r*ppd;

cut_out=round(cut_out*ppd);
cut_in=round(cut_in*ppd);
redundancyEnd=[];

flick_dur = 1/flicker_freq/2;

%Read in background images

if color_check == 1
    
    % Either load the whole image or just the bowtie wedges
    if iswedge == 0
        checks1=imread([gTrialConds.Parameters.StimulusDirectory, 'background0.png']);
        checks2=imread([gTrialConds.Parameters.StimulusDirectory, 'background1.png']);
    else
        
        % Load in all of the data (using an alpha channel
        [checks1, ~, Alphachannel]=imread([gTrialConds.Parameters.StimulusDirectory, 'background0_V_wedge.png']);
        checks1(:, :, 4) = Alphachannel;
        [checks2, ~, Alphachannel]=imread([gTrialConds.Parameters.StimulusDirectory, 'background1_V_wedge.png']);
        checks2(:, :, 4) = Alphachannel;
        [checks3, ~, Alphachannel]=imread([gTrialConds.Parameters.StimulusDirectory, 'background0_H_wedge.png']);
        checks3(:, :, 4) = Alphachannel;
        [checks4, ~, Alphachannel]=imread([gTrialConds.Parameters.StimulusDirectory, 'background1_H_wedge.png']);
        checks4(:, :, 4) = Alphachannel;
        
    end
elseif color_check == 0
    checks1=imread([gTrialConds.Parameters.StimulusDirectory, 'background_bw_0.png']);
    checks2=imread([gTrialConds.Parameters.StimulusDirectory, 'background_bw_1.png']);
end

if flickstim
    checks1=checks1./checks1;
end

%Resize images
ImageSize=StimSize*ppd;

if FixationStimulus==2
    
    imStr = strcat(gTrialConds.Parameters.StimulusDirectory, 'baby_smile_', int2str(rand_img_index), '.png');
    babyBase = imread(imStr);
    babyimg_basesize = ppd * fimg_baseDiam;
    baby_scale = babyimg_basesize/length(babyBase);
    baby1 = imresize(babyBase,baby_scale);
    baby1_tex = Screen('MakeTexture', w, baby1);
end

%How big is the movie
MovieRad=fm_size / 2; %Half the estimate so that the size is correct
MovieRect=[xc-MovieRad, yc-MovieRad, xc+MovieRad, yc+MovieRad];

% Load all the stimuli
checks_tex(1)=Screen('MakeTexture', w, checks1);
checks_tex(2)=Screen('MakeTexture', w, checks2);

% Also add these checks if necessary
if iswedge == 1
    
    % Load all the stimuli
    checks_tex(2, 1)=Screen('MakeTexture', w, checks3);
    checks_tex(2, 2)=Screen('MakeTexture', w, checks4);
end

% Load all the SF stimuli
if any(strcmp(type, {'highlow'; 'lowhigh'}))
    
    texture_id = [];
    for cpd_counter = [1, size(gTrialConds.Stimuli.StimNames,2)]
    %for cpd_counter = 1:size(gTrialConds.Stimuli.StimNames,2)
        for Stim_counter = 1:size(gTrialConds.Stimuli.StimNames,1)
            %What is the stimulus name
            StimName=gTrialConds.Stimuli.StimNames{Stim_counter, cpd_counter};
            
            % What is the stim?
            Stim=imread([gTrialConds.Parameters.SFDirectory, StimName]);
            
            % Trim the stim
            Stim=Stim(1:480, 110:590, :);
            
            % Make a stim texture
            textures(Stim_counter)=Screen('MakeTexture', w, Stim);
        end
        
        % Increase the quantity and then shuffle order
        while 1
            temp=Shuffle(repmat(textures, [1,gTrialConds.Parameters.Stim_Repetitions]));
            
            % If there are no repeats then stop
            if ~any(diff(temp)==0)
                break
            end
        end
        
        texture_id(:, end + 1)=temp;
    end
    
    %If going low to high then flip this order
    if strcmp(type, {'lowhigh'})
        texture_id = fliplr(texture_id);
    end
end


% --------------------
% start experiment now: draw fixation point and text and wait for key press to begin
% --------------------

%HideCursor;	% Hide the mouse cursor
fprintf('\n\n-----------------------Start of Block--------------------------\n\n');

wind.EyeTracking = Utils_EyeTracker_Message(wind.EyeTracking, sprintf(['Start_of_Block__Time_' num2str(GetSecs)]));

% Make the fast fMRI if it is necessary
if gTrialConds.Parameters.TravellingWave==-1
    colors=[wind.black, bcolor, wind.white];
    rows=gTrialConds.Parameters.check_rows;
    wedges=gTrialConds.Parameters.check_wedges;
    
    % What cells are on this frame
    cells=rows * wedges;
    
    wedge_size= 360/wedges;
    
    % Use an exponential as the cortical magnification factor
    row_size=(1:rows).^2;
    row_size=fliplr((row_size/max(row_size)))*cut_in;
    
    % How many potential flashes are there
    Flash_Total=gTrialConds.Stimuli.flash_frequency(block) * (gTrialConds.Parameters.Redundancy + (gTrialConds.Parameters.rot_period * gTrialConds.Parameters.NumRepetitions));
    
    % Add some slop to make sure you dont run out
    Flash_Total = Flash_Total + 50;
    
    % Make matrix representing image onsets
    flash_sequence=randi([0,1],Flash_Total,cells);
    flash_sequence=(flash_sequence*2)-1; % Recalibrate the values
    
    % Set the sparsity of the matrix (turn the specified cells to zero)
    shuffled_cells=Shuffle(1:(Flash_Total * cells));
    cells_to_exclude=round((1-gTrialConds.Stimuli.Sparsity(block)) * Flash_Total * cells);
    flash_sequence(shuffled_cells(1:cells_to_exclude))=0;
    
    %What flash are you up to?
    flash_counter=1;
end

% Wait for the scanner

% If the redundancy is not set to zero then only wait for one TR so
% that your burn in
if Redundancy>0
    wind.BurnIn=1;
end

[Data.Timing.TR, quit]=Setup_WaitingForScanner(wind);

%Calculate when is the next TR expected
if ~isempty(Data.Timing.TR)
    NextTR=Data.Timing.TR(end)+wind.TR;
else
    NextTR=wind.NextTR;
end

if stim == 1
    current_stim=checks_tex;
elseif stim == 2
    current_stim=[Shuffle(bkimage_tex),Shuffle(bkimage_tex),Shuffle(bkimage_tex),Shuffle(bkimage_tex),Shuffle(bkimage_tex),Shuffle(bkimage_tex),Shuffle(bkimage_tex)];
end

%Start the cycle
Utils_EyeTracker_TrialStart(wind.EyeTracking); % Start the trial


%Prep oscillating baby face
if FixationStimulus==2
    babyimg_currsize = babyimg_basesize;
    shrink =0;
    grow =0;
    prevTime = GetSecs - start_time;
end

if FixationStimulus==1
    %When does the movie start
    Data.Timing.movieStartIndex = round(rand(1) * (MovieLength - (rot_period + Redundancy + 5))); % Add a bit of a buffer
    
    %If the movie is too short then reload the default one
    if sign(Data.Timing.movieStartIndex)==-1
        
        MovieName=gTrialConds.Parameters.MovieName;
        Data.Timing.movieStartIndex = round(rand(1) * (160 - (rot_period + Redundancy + 5))); %Approximately the length of the movie
        
        fprintf('%s was too short. Using %s instead\n\n', gTrialConds.Parameters.MovieName, MovieName);
    end
    
    %Set up video
    [movie] = Screen('OpenMovie', w, MovieName);
    
    Screen('SetMovieTimeIndex', movie, Data.Timing.movieStartIndex);
    
    % start movie
    Screen('PlayMovie', movie, 1); %Play the movie. The 1 represents the movie rate
end

% Initialize variables per run
Data.Timing.InitPulseTime=GetSecs;
Data.Timing.TestStart=Data.Timing.InitPulseTime;
fix_dimmed=0;
total_dim=0;
nextIncrement=0; % When does the stim counter tick up?
Stim_counter=0;
next_fix = GetSecs + min_fix + (max_fix-min_fix).*rand;
flash = 1;
count=1;
check_angle=0;
start_time = Data.Timing.TestStart + wind.frameTime;
flipTime = start_time; %Set as the starting value
flick_time=start_time+flick_dur;
next_switch = start_time+ min_switch + (max_switch-min_switch).*rand;
Data.Response.DimOnset=[];
Data.Response.RT=[];
Data.flash_Time=[];

while(flipTime-start_time < (((ncycles * (rot_period + Redundancy))) - (wind.frameTime*2))) && ~quit
    
    % Determine the flip time for
    flipTime_planned=GetSecs+wind.frameTime;
    
    if FixationStimulus==1
        
        % Wait for next movie frame, retrieve texture handle to it
        movietex = Screen('GetMovieImage', w, movie);
        
    elseif FixationStimulus==2
        cTime = (flipTime_planned-start_time);
        elapsTime =  cTime - prevTime;
        prevTime = cTime;
        
        %Update size of fixation image
        if babyimg_currsize >= babyimg_basesize
            shrink =1;
            grow =0;
            babyimg_currsize = babyimg_currsize - (ppd*(fimg_baseDiam-fimg_smDiam))*(elapsTime);
        else
            if babyimg_currsize <= ppd*fimg_smDiam
                grow=1;
                shrink=0;
                babyimg_currsize = babyimg_currsize + (ppd*(fimg_baseDiam-fimg_smDiam))*(elapsTime);
            else
                if shrink
                    babyimg_currsize = babyimg_currsize - (ppd*(fimg_baseDiam-fimg_smDiam))*(elapsTime);
                else
                    if grow
                        babyimg_currsize = babyimg_currsize + (ppd*(fimg_baseDiam-fimg_smDiam))*(elapsTime);
                    end
                end
            end
        end
        
        baby_scale = babyimg_currsize/length(babyBase);
        baby1 = imresize(babyBase,baby_scale);
        baby1_tex = Screen('MakeTexture', w, baby1);
        
    end
    
    %What proportion of the stimulus are you up to?
    
    if Redundancy == 0
        time_frac = (flipTime_planned - start_time)/rot_period; %fraction of cycle we've gone through
    else
        time_frac = (flipTime_planned - start_time)/rot_period - ((Redundancy - wind.frameTime * 2)/rot_period); %fraction of cycle we've gone through
    end
    time_frac(time_frac<0)=1+time_frac; %If it is less than zero then correct
    time_frac=time_frac-floor(time_frac); %If it is more than one then correct

    if gTrialConds.Parameters.TravellingWave==1
        
        %% Update Ring / Wedge
        
        % Report when the redundancy ended
        if Redundancy>0 && isempty(redundancyEnd) && (flipTime_planned - start_time)/rot_period - (Redundancy/rot_period)>0
            redundancyEnd=flipTime_planned;
            fprintf('Redundancy ended at %s', datestr(now));
            
            %Report
            wind.EyeTracking = Utils_EyeTracker_Message(wind.EyeTracking, sprintf(['RedundancyEnd__Time_' num2str(flipTime_planned)]));
            
        end
        
        if any(strcmp(type, {'ccw', 'in'}))
            time_frac = 1-time_frac; %reversing time for these conditions
        end
        
        if scaling == 1 %linear scaling
            [r_outer_deg r_inner_deg] = ring(r_outer_deg_max, r_inner_deg_min, time_frac, duty);
        elseif scaling == 2
            %First convert visual angle range to cortical distance range, only considering RF centers%
            r_outer_ctx_max = log(r_outer_deg_max+1); %maximum stimulation distance from foveal representation in cortex, in mm, only considering RF centers
            r_inner_ctx_min = log(r_inner_deg_min+1);
            
            %Then allow traveling wave to move linearly across cortex, only
            %considering RF centers.
            [r_outer_ctx r_inner_ctx] = ring(r_outer_ctx_max, r_inner_ctx_min, time_frac, duty);
            
            
            %then convert back to visual angle. Duty cycle is preserved.%
            r_outer_deg = exp(r_outer_ctx) - 1;
            r_inner_deg = exp(r_inner_ctx) - 1;
            
        else
            error('Not a valid type of scaling')
        end
        
        %now, regadless of scaling, convert visual angle to pixels
        r_outer_pix = r_outer_deg*ppd;
        r_inner_pix = r_inner_deg*ppd;
        
        %Wedge stuff
        cur_angle=(pi+ (2*pi*time_frac - pi))*(180/pi)+start_angle;
        if checker_rot
            check_angle=(pi+ (2*pi*mod(flipTime_planned-start_time, checker_rot)/checker_rot ))*(180/pi);
        end
        
    elseif any(strcmp(type, {'highlow'; 'lowhigh'}))
        
        % What stim are you showing on this part of the rotation
        Stim_counter = ceil(time_frac * numel(texture_id));
        
        % Check it doesn't go out of bounds
        Stim_counter(Stim_counter==0)=1;
        Stim_counter(Stim_counter>numel(texture_id))=numel(texture_id);
    end
    
    %% Check for flicker of stimulus
    if flipTime_planned > flick_time
        flick_time = flick_time + flick_dur;
        if stim ==1
            if flash==2
                flash=1;
            else
                flash=2;
            end
        elseif stim ==2
            if flash
                flash=0;
            else
                flash=1;
            end
        end
    end
    
    if stim ==2
        if flipTime_planned > next_switch
            next_switch = next_switch + (max_switch-min_switch).*rand;
            count=count+1;
        end
    end
    
    %% Code for dimming
    if ~fix_dimmed & GetSecs > next_fix % if not dimmed and time for next fixation dimming
        %dimm fixation cross
        fcolor=dim_value;
        
        fix_dimmed=1;
        fix_start=GetSecs;
        if (cut_in - cut_out) < atten_ring
            dim_outer = cut_in;
        else
            dim_outer=(cut_in-atten_ring-cut_out) * rand + (atten_ring+cut_out);
        end
        %When does the Dim start
        Data.Response.DimOnset(end+1)=GetSecs;
        
        total_dim=total_dim+1;
    end
    
    
    %% Listen to the keyboard
    [keyIsDown,keycode_onset] = KbQueueCheck(wind.KeyboardNum);
    
    %If they have pressed q then quit
    
    if keyIsDown && sum(keycode_onset>0)==1 && strcmp(KbName(keycode_onset>0), 'q')
        quit=1;
        fprintf('\nBlock Terminated\n');
        Data.Timing.TerminateTime = flipTime_planned;
        
    end
    
    %Check TR (or if you aren't listening for triggers, check the response
    %box alone)
    if wind.isfMRI==1
        [TRRecording, keycode_onset]=Utils_checkTrigger(NextTR, wind.ScannerNum); %Returns the time if a TR pulse happened recently
    else
        % The keycode_onset from above has the conte
        TRRecording=0;
    end
    
    %If there is a recording then update the next TR time and store
    %this pulse
    if any(TRRecording>0)
        Data.Timing.TR(end+1:end+length(TRRecording))=TRRecording;
        NextTR=max(TRRecording)+wind.TR;
    end
    
    % Record the response if there was one
    if length(keycode_onset)>length(but1) && any(keycode_onset(but1)>length(Data.Response.DimOnset)) && length(Data.Response.DimOnset)>length(Data.Response.RT) && AttentionTask==1
        
        %Record RT
        Data.Response.RT(length(Data.Response.DimOnset))=max(keycode_onset(but1))-Data.Response.DimOnset(end);
        
        %Report response
        fprintf('Response given. RT: %0.2f\n\n', max(keycode_onset(but1))-Data.Response.DimOnset(end));
        
        %Undim stimulus
        fix_dimmed=0;
        fcolor=[255 255 255];
        next_fix = GetSecs+ min_fix + (max_fix-min_fix).*rand;
        
    end
    
    %% Show Stimuli
    
    %Fill rect
    Screen('FillRect',w, bcolor);
    
    if FixationStimulus==1
        if iswedge == 1 && ~any(strcmp(type, {'highlow'; 'lowhigh'}))
            Screen('DrawTexture', w, movietex, [], MovieRect);
            Screen('Close', movietex);
        end
    end
    
    % Default to show horizontal but change this if you are in the
    % second half of a cycle for horizontal or first half of vertical
    is_first_half = time_frac < 0.5;
    ishorizontal=1;
    if strcmp(type, {'horizontal_first'}) && is_first_half==0
        ishorizontal=0;
    elseif strcmp(type, {'vertical_first'}) && is_first_half==1
        ishorizontal=0;
    end
    
    
    
    %Draw the wedge/ring (unless it is a block without wedge drawing
    if ~any(strcmp(type, {'highlow'; 'lowhigh'; 'radial_low_freq'; 'radial_high_freq'}))
        if stim ==1
            if iswedge == 1
                Screen('DrawTexture',w,current_stim(ishorizontal + 1, flash),[],[xc-cut_in/2, yc-cut_in/2, xc+cut_in/2, yc+cut_in/2],check_angle);
            else
                Screen('DrawTexture',w,current_stim(flash),[],[],check_angle);
            end
        elseif stim == 2
            Screen('DrawTexture',w,current_stim(count));
            if flash
                Screen('DrawTexture',w,checks_tex(1),[],[],[],[],flash);
            end
        end
    end
    
    %Draw the borders of the stimuli
    if any(strcmp(type, {'cw'; 'ccw'}))
        Screen('FillArc', w, bcolor, [xc-stim_r, yc-stim_r, xc+stim_r, yc+stim_r], cur_angle+(.5*wedge_size), 360-wedge_size);
        Screen('FrameArc',w, bcolor, [xc-max_viewing, yc-max_viewing, xc+max_viewing, yc+max_viewing],0,360,max_viewing-(cut_in),max_viewing-(cut_in));
        Screen('FillArc', w, bcolor, [xc-(cut_out), yc-(cut_out), xc+(cut_out), yc+(cut_out)], 0, 360);
    elseif any(strcmp(type, {'in'; 'out'}))
        Screen('FrameArc', w, bcolor, [xc-max_viewing, yc-max_viewing, xc+max_viewing, yc+max_viewing],0,360,max_viewing-r_outer_pix,max_viewing-r_outer_pix);
        Screen('FillOval', w, bcolor, [xc-r_inner_pix, yc-r_inner_pix, xc+r_inner_pix,yc+r_inner_pix]);
    elseif any(strcmp(type, {'highlow'; 'lowhigh'}))
        Screen('DrawTexture', w, texture_id(Stim_counter), [], [xc-cut_in/2, yc-cut_in/2, xc+cut_in/2, yc+cut_in/2]);
    elseif ~isempty(strfind(type, 'first')) && ishorizontal==1
        
        if iswedge == 0
            Screen('FillRect', w, bcolor, [xc-max_viewing, yc-max_viewing, xc+max_viewing, yc-MovieRad]);
            Screen('FillRect', w, bcolor, [xc-max_viewing, yc+MovieRad, xc+max_viewing, yc+max_viewing]);
        end
    elseif ~isempty(strfind(type, 'first')) && ishorizontal==0
        
        if iswedge == 0
            
            Screen('FillRect', w, bcolor, [xc-max_viewing, yc-max_viewing, xc-MovieRad, yc+max_viewing]);
            Screen('FillRect', w, bcolor, [xc+MovieRad, yc-max_viewing, xc+max_viewing, yc+max_viewing]);
        end
        
    elseif any(strcmp(type, {'radial_low_freq'; 'radial_high_freq'}))
        if size(flash_sequence,1) >= flash_counter
            % Make all of the wedges
            for row = 1:rows
                for wedge = 1:wedges
                    Screen('FillArc', w, colors(flash_sequence(flash_counter, (((row-1)*wedges + wedge)))+2), [xc-row_size(row), yc-row_size(row), xc+row_size(row), yc+row_size(row)], (wedge_size*(wedge-1)) + (.5*wedge_size), wedge_size);
                    
                    %                     % To show what wedge is which item, make the colors a
                    %                     % scale from black to white
                    %                     Screen('FillArc', w, ((row-1)*wedges + wedge)*21, [xc-row_size(row), yc-row_size(row), xc+row_size(row), yc+row_size(row)], (wedge_size*(wedge-1)) + (.5*wedge_size), wedge_size);
                    
                end
            end
            flash_counter=flash_counter+1;
            flipTime_planned= flipTime_planned + (((1/wind.frameTime)/ gTrialConds.Stimuli.flash_frequency(block)) * wind.frameTime) - wind.frameTime;
        else
            fprintf('Terminated flash sequence early. Ending block.\n');
            break;
        end
    end
    
    if gTrialConds.Parameters.TravellingWave==1
        Screen('FillOval',w, bcolor, [xc-fm_size; yc-fm_size; xc+fm_size; yc+fm_size]); %Draw the central circle
    end
    
    %Show either a movie or a baby (on top of image if iswedge)
    
    if FixationStimulus==1
        if iswedge == 0 || any(strcmp(type, {'highlow'; 'lowhigh'}))
            Screen('DrawTexture', w, movietex, [], MovieRect);
            Screen('Close', movietex);
        end
    elseif FixationStimulus==2
        Screen('DrawTexture',w,baby1_tex);
        Screen('Close',baby1_tex);
    end

    
    %Do this for the attention task
    if AttentionTask==1
        
        % Is the fixation moving
        if motion_envelope > 0
            
            % How far is the fix from the center at this moment
            deviation = sin((GetSecs - start_time) * 2 * pi * motion_freq) * motion_envelope * ppd;
            
            % Update the new center 
            if strcmp(type, {'horizontal_first'})
                fix_x = xc + deviation;
            elseif strcmp(type, {'vertical_first'})
                fix_y = yc + deviation;
            end
        end
        
        Screen('FillOval',w, fcolor, [fix_x-fp_size; fix_y-fp_size; fix_x+fp_size; fix_y+fp_size]); %Draw the central circle
    end
    
    Screen('DrawingFinished', w);
    
    %Flip
    flipTime=Screen('Flip', w, flipTime_planned);
    Data.flash_Time(end+1)=flipTime;
    
    % Record the time when the switch occurred
    if is_first_half == 0 && ~isfield(Data.Timing, 'Block_switch') && any(strcmp(type, {'highlow'; 'lowhigh';'horizontal_first'; 'vertical_first'}))
        Data.Timing.Block_switch = flipTime;
        fprintf('Switched %0.2fs after onset\n', flipTime-Data.flash_Time(1));
    end
    
end

%Stop the movie if it's playing
if FixationStimulus==1 || FixationStimulus==3
    Screen('CloseMovie', movie);
end

%Clear all textures
Screen('Close');
Screen('FillRect',w, bcolor);
flipTime=Screen('Flip', w);
Utils_EyeTracker_TrialEnd(wind.EyeTracking);

%Store some information
if FixationStimulus == 1
    Data.Stimuli.MovieName=MovieName;
end
Data.Timing.BlockEndTime = flipTime;
Data.Timing.redundancyEnd = redundancyEnd; %Save when the redundancy ends
Data.Timing.DecayLapse = DecayLapse + Data.Timing.BlockEndTime;
Data.Quit = quit;
Data.totalRunTime = Data.Timing.BlockEndTime-start_time;
Data.Timing.TestEnd = Data.Timing.BlockEndTime; %Redundant but needed for coding

if any(strcmp(type, {'radial_low_freq'; 'radial_high_freq'}))
    Data.Stimuli.flash_sequence=flash_sequence(1:flash_counter-1,:);
end

wind.EyeTracking = Utils_EyeTracker_Message(wind.EyeTracking, sprintf(['End_of_Block__Time_' num2str(GetSecs)]));

fprintf('\n\n -----------------------End of Block-------------------------- \n\n');




function [r_outer r_inner] = ring(r_outer_max, r_inner_min, time_frac, duty) %This generic function can be used to generate linearly scaled rings on screen or on cortex.
r_width = duty*(r_outer_max-r_inner_min)/(1-duty); %fixed width of ring; (can obtain by solving for r_width in duty = r_width/(r_outer_max+r_width-r_inner_min)
r_outer_max_NOBLOCK = r_outer_max + r_width; %how far outer ring would go if there was no blocking ("blocking" is stopping the movement of the outer ring near the end of the cycle)

r_outer = r_inner_min + time_frac*((r_outer_max_NOBLOCK)-r_inner_min);% provisionally placing outer ring somewhere between r_inner_min and the maximum possible value if no blocking was done
r_inner = r_outer - r_width; %provisionally making inner ring a fixed distance inside outer ring;

r_outer = min(r_outer, r_outer_max); %... but blocking outer ring from going past its maximum allowed value.
r_inner = max(r_inner, r_inner_min); %...and not letting inner ring go below an assigned minimum (usually zero).

