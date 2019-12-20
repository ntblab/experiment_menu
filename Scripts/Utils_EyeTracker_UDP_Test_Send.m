%% Test a UDP connection
%Use this script to check that you can send UDP messages between experiment
%and eye tracker computers. This is necessary if you are going to do the
%'FrameGrabber option for eyetracking. If you are using no eye tracking,
%EyeLink or an alternative eye tracker software then this is not necessary
%
% In order to use this, computers must first be connected via ethernet.
% Then, run the function Utils_EyeTracker_Recieve_UDP.py (note that this is
% a python script. I recommend using Spyder to run it) on the eye tracker
% computer. This should print a number for approximately 30 seconds and
% then when it receives a message, it will print it. Hence, this script is
% meant to send a message to the computer. If the message is received it
% will be printed on the eye tracker computer. computer.
%
% If this fails, first check the ethernet connections between computers.
% Second, check that the IP address for the eye tracking computer is
% correct in the variable 'server_IP'. If you aren't sure, run 'ipconfig'
% in the eye tracker terminal to find the IP address for this script.
%
% First created C Ellis 6/12/18

server_IP = 'XXX.XXX.XXX.XXX'; % What is the IP address of the destination computer (Use ifconfig (mac) or ipconfig /all (windows) to find this out)
port=5005; % What port have you specified as containing information

fid=udp(server_IP, port); % Create the udp communication object

fopen(fid); % Initialize the communication

fprintf(fid, 'Initialized connection. Experiment computer time: %0.3f', GetSecs);  % Send the first message