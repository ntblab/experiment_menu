%% Print text either to the console window or the screen

% If the Window subfield print_screen exists and is set to 1 then the text
% will print to screen

function PrintText_List = Utils_PrintText(Window, PrintText_List, Message)

List_limit = 20;  % What is the maximum number of lines to print
Screen('TextSize',Window.onScreen, 12);
if isfield(Window, 'print_screen') && Window.print_screen == 1
    
    % Append to the list
    PrintText_List = [PrintText_List, Message];
    
    % If the message is greater than the limit then cut it off
    if length(PrintText_List) > List_limit
        PrintText_List = PrintText_List(2:end);
    end
    
    % Create the message to be printed by adding the 
    Message_print='';
    for List_Counter = 1:length(PrintText_List)
        Message_print = [Message_print, PrintText_List{List_Counter}, '\n'];
    end
    
    % Print text on screen
    DrawFormattedText(Window.onScreen, Message_print, [], [], uint8([255,255,255]));
    
    % Update text
    Screen('Flip',Window.onScreen);
    
end

% Still print screen so that you have the diary
fprintf(Message);

