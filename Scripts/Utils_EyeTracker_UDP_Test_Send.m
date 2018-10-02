%% Test a UDP connection
%Use this script to check that you can send UDP messages between the
%computers.
%
% First off to use this, connect the computers via ethernet. Second, run
% the function Utils_EyeTracker_Recieve_UDP.py on the eye tracker computer.
% This should print a number every second and then when it receives a
% message, print that. Finally, send a messae by running this script. If
% successful, it should print a message in the stream on the eye tracker
% computer.
%
% If this fails, first check the connections between computers. Second,
% check that the IP address for the eye tracking computer is correct in the
% variable 'server_IP'. If you aren't sure, run 'ipconfig' in the eye
% tracker terminal
%
% First created C Ellis 6/12/18

server_IP = '169.254.152.238'; %'169.254.37.123';%'169.254.152.238'; % Mac '172.28.97.210'; % % What is the IP address of the destination computer (Use ifconfig (mac) or ipconfig /all (windows) to find this out)
port=5005; % What port have you specified as containing information

fid=udp(server_IP, port); % Create the udp communication object

fopen(fid); % Initialize the communication

fprintf(fid, 'Initialized connection. Experiment computer time: %0.3f', GetSecs);  % Send the first message