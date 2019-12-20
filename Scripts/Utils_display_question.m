%Display the question and wait for an answer
function Output=Utils_display_question(Window, Question, Textwrap, Spacing, textColor, Linespacing)

    if nargin < 3
        Linespacing= 1.5; %How big are the spaces between the text
        Textwrap=75; %How many characters before starting a new line
        Spacing= 50; %How far below midline is the confidence judgement presented
        textColor=255; % What is the text color
    end

    Howmanylines= length(Question)/Textwrap;
    QuestionSpacing= (Window.centerY-((Spacing*Howmanylines)));
    AnswerSpacing= (Window.centerY+Spacing);
    KbQueueFlush(Window.KeyboardNum);
    
    DrawFormattedText(Window.onScreen, Question, 'center', QuestionSpacing, textColor, Textwrap, [], [], Linespacing);
    Screen('Flip', Window.onScreen);
    entered=0; %Has someone pressed enter
    Temptext = '';
    DisplayText='';
    last_resp='';
    Next_Prompt_Flash=GetSecs;
    while entered==0
        [~, ~, keyCode] = KbCheck(Window.KeyboardNum);
        resp_all = KbName(keyCode); % Find the character that was pressed
        
        % Put it in a cell for the following
        if isstr(resp_all)
            resp_all = {resp_all};
        end
        
        % Ignore from the list of responses the last response if there was
        % one
        resp_considered=1:length(resp_all);
        ignore_resp=[];
        for resp_counter = resp_considered
            ignore_resp(resp_counter)=any(strcmp(resp_all(resp_counter), last_resp));
        end
        last_resp = resp_all;
        
        % Ignore these responses because they were pressed last time
        resp_considered = resp_considered(ignore_resp==0);
        
        % If there is one response
        for resp_counter = resp_considered
            

            % Pull out this character
            resp=resp_all{resp_counter};
            is_shift=any(~cellfun(@isempty, strfind(resp_all, 'Shift')));
            if strcmp(resp, 'Return')
                if ~isempty(Temptext)
                    entered=1;
                    break;% Break the while loop
                end
            elseif strcmp(resp, 'DELETE') || strcmp(resp, 'BackSpace') %This is backspace so performs a loop to correct and update the list
                if ~isempty(Temptext)
                    Temptext = Temptext(1:length(Temptext)-1);
                end
                DrawFormattedText(Window.onScreen, Question, 'center', QuestionSpacing, textColor, Textwrap, [], [], Linespacing);
                DrawFormattedText(Window.onScreen, DisplayText, 'center', AnswerSpacing, textColor, Textwrap, [], [], Linespacing);
                Screen('Flip', Window.onScreen);
                
            elseif strcmp(resp, 'space')
                Temptext = [Temptext, ' '];
            
            elseif length(resp) == 2 % If there are two characters then opt to use either the first or second depending on whether one of the responses is shift
                
                % What character of the response do you want to use?
                if is_shift
                    char_idx=2;
                else
                    char_idx=1;
                end
                
                Temptext = [Temptext, resp(char_idx)];
                
            elseif length(resp) == 1 % Ignore all other keys like space or shift
                if is_shift
                    Temptext = [Temptext, upper(resp)];
                else
                    Temptext = [Temptext, resp];
                end
            end
        end
     
        % Update output
        Output = Temptext;
        
        %Add the flashing line to queue responding (alternate based on the
        %last state)
        if ~isempty(strfind(DisplayText, '|'))
            DisplayText = [Temptext, '|'];
        else
            DisplayText = [Temptext, ' '];
        end
        
        if Next_Prompt_Flash < GetSecs
            if isempty(strfind(DisplayText, '|'))
                DisplayText = [Temptext, '|'];
            else
                DisplayText = [Temptext, ' '];
            end
            
            Next_Prompt_Flash = GetSecs + 0.5;
        end
        
        DrawFormattedText(Window.onScreen, Question, 'center', QuestionSpacing, textColor, Textwrap, [], [], Linespacing);
        DrawFormattedText(Window.onScreen, DisplayText, 'center', AnswerSpacing, textColor, Textwrap, [], [], Linespacing);
        Screen('Flip', Window.onScreen);
        
%         % Wait until there are different key presses
%         [~, ~, resp_lapse] = KbCheck(Window.KeyboardNum);
%         while isempty(setdiff(KbName(resp_lapse), resp_all)) && isempty(setdiff(resp_all, KbName(resp_lapse))) 
%             [~, ~, resp_lapse] = KbCheck(Window.KeyboardNum);
%         end
        
    end
    
end