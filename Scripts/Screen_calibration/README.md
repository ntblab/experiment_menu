# Steps to undistort a display
If you have a display that has any of the following distortions: keystoning (more than what can be solved optically), stretching or curvature distortion, then this README can help. If you don't have this because you have a standard experiment setup (e.g., extended display monitor or rear projection mirror system) then this setup is unnecessary and simply change the screen size and viewing distance variables in `./Scripts/Setup_Display.m`

If you do have an atypical display then read the following. The assumed use case for this script is when projecting on to the ceiling of the bore. When projecting an image on to the surface of the bore from a rear projector, several factors interact to distort the image. However, if you are doing another kind of stimulus presentation that has only one of these types of distortions (e.g., projecting on to a screen from an angle makes a key stoning artefact) then you can still use this script .  

The way this procedure works is that you manually create a remapping of output pixels, which default as rectangular, on to a new shape, such as trapezoidal for keystoning. This then creates a file with this distortion stored that can be reloaded to recreate that distortion any time that is necessary.

Most apparent is a curvature distortion that is elliptical. This means that the light has to travel further for the middle of the image rather than the sides. This distortion is not consistent across the height of the image: the curvature is more severe at the bottom of the image than the top.  
A related distortion is keystoning, in which the lowest part of the image (i.e. the part of the image that is furtherest from the projector) is wider than the top part. Before pursuing digital steps for fixing this (in this script), you should use the optical option if your projector has one. The criteria for success is that the chord (distance between two points along the arc of a circle) of the top and the bottom of the image are equivalent.  
Another distortion is stretching. Light must travel further for the lower parts of the image than the top parts and hence the image must compress these low parts and stretch the upper parts to compensate.  

Once you have made sure the image is optically optimal (centered, un-keystoned as much as possible) then run the `WarpingUndistortionDemo.m` script in this folder. This script guides through the undistortion process. If it is your first time running this then it will open the 'DisplayUndistortionBVL' function which is the backbone of this process. Basically this script allows you to change the pixel assignment of video outputs by setting up a grid of anchor pixels that can be moved to warp pixels around it. When you first open this, don't change anything, just exit: we need the general structure of these scripts but we don't need to manually reassign every anchor pixel to correct our distortion. Instead, the position of these anchor pixels is parameterized in the code according to the three types of distortion above. The user can then manually alter these parameter values to recreate a new distortion map that attempts to fix the distortion. 

Use the response keys to adjust the checkerboard until the checks are square (you can measure them with a tape measure pressed against the display). When you quit out of this script, you will save a calibration file to this folder ('./Scripts/Screen_calibration/') that will be found by the `Menu.m` code and used to make a screen with the distortion that is desired.

The keys to change the calibration are as follows
Increase vertical elipsis distance = 'UpArrow'
Decrease vertical elipsis distance = 'DownArrow’
Increase horizontal elipsis distance = 'RightArrow'
Increase horizontal elipsis distance = 'LeftArrow'
Double the step size = 'd'
Halve the step size = 'h' 
Save and quit = 'q'

To change the stretching or keystone, do so manually in the script (this is because these values need less adjusting)
