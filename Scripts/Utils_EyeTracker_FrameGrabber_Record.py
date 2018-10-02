#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Listen to and save frames coming in from an camera, as well as messages sent over UDP. 

This code uses openCV to record the video data coming from device labelled 1 (probably the camera but should check
It also monitors for UDP messages from the display computer. Make sure that you have set this up correctly. You can test this by using the Utils_EyeTracker_UDP_Test_Receive.py and Utils_EyeTracker_UDP_Test_Send.py receive functions.

"""

## Capture video using the MRC, epiphan system and receive triggers from matlab

# Import module
import cv2
import socket, select
import sys
import time
import os
import glob
import numpy as np
import shutil

# What is the output dir you want to create to put everything in
if len(sys.argv) == 1:
    output_dir = 'C:/Users/EyeLink/Documents/Turk-Browne_lab/Data/Pilot/'
else:
    output_dir = sys.argv[1]

print('Putting data in %s' % output_dir)

# Use jpg as your file codec
ext = '.jpg'

# Create a folder to put the images in
if os.path.isdir(output_dir) == 0:
    os.mkdir(output_dir)
    os.mkdir(output_dir + 'Frames/')
    numframe = 0
else:
    # If the file exists then start the frame counter from here
    try:
        numframe = len(glob.glob(output_dir + 'Frames/*' + ext)) # Start the counter where it was
    except:
        numframe = 0 # Preset the counter
    
## Set up the camera recording
cap = cv2.VideoCapture(0)  # Specify which device to record from
w=int(cap.get(cv2.CAP_PROP_FRAME_WIDTH ))
h=int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT ))
im_scale = 0.25  # How much would you like to scale the image by (1 means not at all)
recording_video = 0 # Preset recording to off

## Set up the message receiving
# How big is the string
string_size = 1024

# Specify the hostname of the computer
hostName = socket.gethostbyname('0.0.0.0')

# Specify the port that you will be looking for
UDP_PORT = 5005

# Create the socket object as a UDP
server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Set up to allow for non blocking
server.setblocking(0)

# Bind the host with the port
server.bind((hostName, UDP_PORT))

# Sockets from which we expect to read
inputs = [ server ]

# Sockets to which we expect to write
outputs = [ ]

# Create the timing file
f = open(output_dir + 'TimingFile.txt', 'a+')
f.write('Starting Session: ' + str(int(time.time() * 1000)) + '\n')

while True: 
    
    # Preset on every frame
    key = -1
    
    # Capture the image
    ret, frame = cap.read()
        
    # Display the image on the screen that is being recorded
    cv2.imshow('Press ''q'' to end recording', frame)
    
    # Get the time stamp in microseconds
    timestamp = str(int(time.time() * 1e6))
    
    # Is the recording turned on? If it isn't then you won't store the frames, onl
    if recording_video == 1:
        
        # Resize the image
        if im_scale != 1:
            frame = cv2.resize(frame, (0,0), fx=im_scale, fy=im_scale)
        
        # What is the file name to be saved? Based on the SMI nomenclature
        name = ('eye%05d_0_0_%d_%d_%s' % (numframe, frame.shape[0], frame.shape[1], timestamp))
        
        # What will this be saved as
        im_name = output_dir + 'Frames/' + name + ext
        
        # Save the images
        cv2.imwrite(im_name, frame)

        # Store the data based on the SMI nomenclature
        f.write('%s\tSMP\t1\t\n' % timestamp)
        
        # Increment the frame
        numframe += 1

    
    # Detect if this serveris readable (there is a message there)
    readable, writable, exceptional = select.select(inputs, outputs, inputs, 0)
    
    # Check the socket as long as there is something readable
    while readable:
        
        # Since there is readable data, pull the data and store it
        data = server.recv(string_size)
        
        # Convert the bytes of the message into a string
        msg = data.decode("utf-8") 
        
        # Write the message to both the command window and the timing file (using the SMI nomenclature)
        f.write('%s\tMSG\t1\t# Message: %s\n' % (timestamp, msg))

        
        # If the msg is special and contains a command then implement it
        if msg.find('!!-START_RECORDING-!!') == 0:
            key = ord('r') # Turn the recording on
        elif msg.find('!!-STOP_RECORDING-!!') == 0:
            key = ord('s') # Turn the recording on
        elif msg.find('!!-END_SESSION-!!') == 0:
            key = ord('q') # Turn the recording on
        else:
            print(msg + '\n')
        
        # Read it again, there may be more messages
        readable, writable, exceptional = select.select(inputs, outputs, inputs, 0)
    
    # Listen for keys if they haven't already been set
    if key == -1:
        key = cv2.waitKey(1)
        
    # Based on the key presses, decide whether to change recording or quit.    
    if key != -1:
        if key == ord('r'):
            recording_video = 1
            f.write('Starting recording: ' + str(int(time.time() * 1000)) + '\n')
            print('###########\n\nRECORDING\n')
        elif key == ord('s'):
            recording_video = 0
            f.write('Stop recording: ' + str(int(time.time() * 1000)) + '\n')
            print('- - - - - - - - - -')
        elif key == ord('q'):
            f.write('Ending session: ' + str(int(time.time() * 1000)) + '\n')
            break

# Close the windows and server
cv2.destroyAllWindows()  # Close windows
cap.release() # Stop controlling the camera
f.close() # Close the text document
server.close() # Close the server for udp

# To support the transferal of data from Windows, you will typically have to store the folder in 12000 frame chunks
# The following script creates directories with the nomenclature 'Frames_X' to duplicate and split the data

frame_list=glob.glob(output_dir + 'Frames/*' + ext)
numframe = len(frame_list)  #How many frames do you have?
total_folders = int(np.ceil(float(numframe) / 12000))

# Iterate through the folders
for folder_counter in range(1, total_folders + 1):
    
    # Make the folder
    if os.path.isdir((output_dir + 'Frames_%d/') % folder_counter) == 0:
        os.mkdir((output_dir + 'Frames_%d/') % folder_counter)
    
    # What frames should go into this folder
    min_idx = (folder_counter - 1) * 12000
    max_idx = ((folder_counter) * 12000) - 1
    if max_idx > numframe:
        max_idx = numframe
    
    print(('Folder %d with frames %d to %d' % (folder_counter, min_idx, max_idx)))
    
    for frame_counter in range(min_idx, max_idx):
        
        # Where does the file name start
        idx = frame_list[frame_counter].find('eye')
        
        # Copy the file over
        shutil.copyfile(frame_list[frame_counter], ((output_dir + 'Frames_%d/%s') % (folder_counter, frame_list[frame_counter][idx:])))
    

