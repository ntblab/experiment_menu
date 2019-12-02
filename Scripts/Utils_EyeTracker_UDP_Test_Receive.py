# Script for testing that you can receive UDP packets

# Import module
import socket
import select
import numpy as np


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

# Listen for incoming connections
#server.listen(5)
counter=0;
while inputs:

    # Wait for at least one of the sockets to be ready for processing
    if np.mod(counter, 100000) == 0:
        print(counter)
    
    # Detect if this serveris readable (there is a message there)
    readable, writable, exceptional = select.select(inputs, outputs, inputs, 0)
    
    # Check the socket as long as there is something readable
    while readable:

        data = server.recv(string_size)
        print(data)
        
        # Read it again, there may be more messages
        readable, writable, exceptional = select.select(inputs, outputs, inputs, 0)    
        
    counter += 1
    
    if counter == 10000000:
        inputs = [ ]

# Close the port
server.close()
