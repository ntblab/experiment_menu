#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Listen to and save frames coming in from an camera, as well as messages sent over UDP. 

This code uses openCV to record the video data coming from device labelled 1 (probably the camera but should check
It also monitors for UDP messages from the display computer. Make sure that you have set this up correctly. You can test this by using the Utils_EyeTracker_UDP_Test_Receive.py and Utils_EyeTracker_UDP_Test_Send.py receive functions.

Based on code from RW
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
from threading import Thread
from queue import Queue

# See https://www.pyimagesearch.com/2017/02/06/faster-video-file-fps-with-cv2-videocapture-and-opencv/
# Slightly modified, including returning a timestamp for each frame

# What is the output dir you want to create to put everything in
if len(sys.argv) == 1:
    output_dir = 'C:/Users/FAS BIC/Documents/ntblab/experiment_menu_private/Data/Pilot/'
else:
    output_dir = sys.argv[1]


class FileVideoStream:
    def __init__(self, path, queueSize=3000):
        # initialize the file video stream along with the boolean
        # used to indicate if the thread should be stopped or not
        self.stream = cv2.VideoCapture(path)
        self.stopped = False
        
        # Determine whether you should be recording the frame from this queue or not
        self.is_record = False
        
        # initialize the queue used to store frames read from
        # the video file
        self.Q = Queue(maxsize=queueSize)

    def start(self):
        # start a thread to read frames from the file video stream
        t = Thread(target=self.update, args=())
        t.daemon = True
        t.start()
        return self

    def update(self):
        # keep looping infinitely
        while True:
            # if the thread indicator variable is set, stop the
            # thread
            if self.stopped:
                return
 
            # otherwise, ensure the queue has room in it
            if not self.Q.full():
                # read the next frame from the file
                (grabbed, frame) = self.stream.read()
  
            # add the frame, time stamp, and a flag about whether to record this frame (which is time point specific)
            self.Q.put({'frame': frame,
                        'time': time.time() * 1e6,
                        'is_record': self.is_record,
                        })

    def read(self):
        # return next frame in the queue
        return self.Q.get()

    def more(self):
        # return True if there are still frames in the queue
        return self.Q.qsize() > 0

    def stop(self):
        # indicate that the thread should be stopped
        self.stopped = True

    def stream(self):
        return self.stream



# start the file video stream thread and allow the buffer to
# start to fill
print("[INFO] starting video file thread...")
fvs = FileVideoStream(0).start()

cap = fvs.stream

# Check if camera opened successfully
if (cap.isOpened() == False): 
  print("Unable to read camera feed")

print('Putting data in %s' % output_dir)

# %TODO Make it count the number of frames if the ppt has already been started 

# Create a folder to put the images in
if os.path.isdir(output_dir) == 0:
    os.mkdir(output_dir)

numframe = 0 # Preset the counter

# What video extension do you want to use
ext = '.avi'

# What is the file name you will use for this movie you are saving
startTime = time.time()
datetime = time.strftime("%m%d%Y-%H%M%S", time.localtime(startTime))
output_name = output_dir + '/' + datetime + ext

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
#f = open(output_dir + 'TimingFile.txt', 'a+')
file_text = ['Starting Session: ' + str(int(time.time() * 1000)) + '\n']

print('CAP_PROP_FRAME_WIDTH  ', cap.get(cv2.CAP_PROP_FRAME_WIDTH))
print('CAP_PROP_FRAME_HEIGHT ', cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
print('CAP_PROP_FPS          ', cap.get(cv2.CAP_PROP_FPS))

im_FPS = cap.get(cv2.CAP_PROP_FPS)
im_rotate = 270
im_scale = 0.5

frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) // (1 / im_scale))
frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) // (1 / im_scale))


numframe = 0 


if im_rotate == 270:
    out = cv2.VideoWriter(output_name, cv2.VideoWriter_fourcc('M','J','P','G'), im_FPS, (frame_height,frame_width))
else:
    out = cv2.VideoWriter(output_name, cv2.VideoWriter_fourcc('M','J','P','G'), im_FPS, (frame_width,frame_height))

# In case there is a crash this will gracefully exit to avoid your RAM being filled by the queue
try:
    
    # loop over frames from the video file stream
    while True:
        
        key = -1
        
        if fvs.more():
            # grab the frame from the threaded video file stream, resize
            # it, and convert it to grayscale (while still retaining 3
            # channels)
            frameDict = fvs.read()
            frame = frameDict['frame']
    
            ## Deal with messages coming from the ethernet cable
            
            # Get the time stamp in microseconds
            timestamp = str(int(time.time() * 1e6))
            
            # Detect if this serveris readable (there is a message there)
            readable, writable, exceptional = select.select(inputs, outputs, inputs, 0)
            
            # Check the socket as long as there is something readable
            while readable:
                
                # Since there is readable data, pull the data and store it
                data = server.recv(string_size)
                
                # Convert the bytes of the message into a string
                msg = data.decode("utf-8") 
                
                # Write the message to both the command window and the timing file (using the SMI nomenclature)
                file_text += ['%s\tMSG\t1\t# Message: %s\n' % (timestamp, msg)]
        
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
            
    
            ## Display the image
            
            # display the size of the queue on the frame
            if frameDict['is_record'] == False:
                cv2.putText(frame, "Queue Size: {0}, Frame {1}, Time {2:.1f}".format(fvs.Q.qsize(), numframe,time.time()-startTime),
                           (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)	
              
            # Resize the image
            if im_scale != 1:
                frame = cv2.resize(frame, (0,0), fx=im_scale, fy=im_scale)
                
            # Rotate the image
            if im_rotate != 0:
                frame = np.rot90(frame, np.round(im_rotate / 90)) #'ROTATE_180')
        
            if frameDict['is_record'] == True:
    
                if np.mod(numframe, 10) == 0:
                    frame[0,0,0] =255
                    
                out.write(frame)
                
                file_text += ['%d\tSMP\t1\t\n' % frameDict['time']]
                
                numframe += 1
    
            # show the frame
            cv2.imshow("Frame", frame)
            
        # Listen for keys if they haven't already been set
        if key == -1:
            key = cv2.waitKey(1)  & 0xFF
            
        # Based on the key presses, decide whether to change recording or quit.    
        if key != -1:
            if key == ord('r'):
                fvs.is_record = True
                file_text += ['Starting recording: ' + str(int(time.time() * 1000)) + '\n']
                print('###########\n\nRECORDING\n')
                      
            elif key == ord('s'):
                fvs.is_record = False
                file_text += ['Stop recording: ' + str(int(time.time() * 1000)) + '\n']
                print('- - - - - - - - - -')
                
            elif key == ord('q'):
                file_text += ['Ending session: ' + str(int(time.time() * 1000)) + '\n']
                break    
            
    # do a bit of cleanup
    cv2.destroyAllWindows()
    fvs.stop()
    out.release()

except:
    
    print('Error, aborting')
    
    # do a bit of cleanup
    cv2.destroyAllWindows()
    fvs.stop()
    out.release()

# Write timestamps to a file
with open(output_dir + 'TimingFile.txt', 'a+') as f:
    for line in file_text:
        f.write(line)
        
