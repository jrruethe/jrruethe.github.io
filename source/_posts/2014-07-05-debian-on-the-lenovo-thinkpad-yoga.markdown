---
layout: post
title: "Debian on the Lenovo Thinkpad Yoga"
date: 2014-07-05 20:03:39 -0400
comments: true
categories: 
---

Many of the features of the Lenovo Thinkpad Yoga work out of the box with a fresh install of Debian Testing.
Here is the status of each hardware component and any steps I had to take to get it to work.
Keep in mind that I am using Kernel 3.14.1-amd64.

{% more %}

### Wireless

Wireless does work well, but you need to install the firmware package from the repositories.  
    apt-get install firmware-iwlwifi
Getting this was tricky, because there are no ethernet ports on the system, and the wireless is not recognised at install time.  
I had to use a usb-ethernet adapter and plug it into my router.  
After installing the package and rebooting, wireless works great.

### Touchscreen

Touchscreen works out of the box for left clicking and dragging.  
Multitouch does not seem to work out of the box, I am unable to two-finger-scroll nor pinch-zoom in Chromium.
Also, holding down your finger for right click does not work.

### Wacom Stylus

The stylus works out of the box, including clicking and dragging. There is a little button on the stylus, and if you hold it down while you touch the screen it does a right-click.  
By installing `gnome-control-center` you can calibrate the touchscreen with the stylus.

### Touchpad

The Synaptics Touchpad works out of the box for the most part. However, tap-to-click doesn't work.
Clicking the entire touchpad down with one finger is a left-click, while clicking the entire touchpad down with two fingers is a right click.  
Dragging while holding the touchpad down works for multiple selection and moving files around.  
Two-finger scroll works out of the box.  
I haven't figured out how to do a middle-click.

I tried using `gnome-control-center` to enable tap-to-click, but was unsuccessful. I don't think the lack of this feature hinders usability in any way.

Also, the little red pointer nub works as well. You need to click the touchpad with your thumb, and there is no real way to do a right click while using the red pointer nub.

### Sound

Sound works out of the box, however it is muted at installation.  
I found the easiest way to fix this is to install PulseAudio Volume Control (`pavucontrol`) and unmute the speakers.

### Bluetooth

Bluetooth seemed to work out of the box as well. I did install the `bluetooth` and `blueman` packages to use it.

### Webcam

The webcam works out of the box.

### Function Keys

The brightness keys (F5 / F6) work out of the box, but there is no OSD / HUD.  
The wireless key (F8) also works without any configuration needed.  

The webcam buttom (F7) seems to work, but there is a caveat:

 1. Start webcam with QtQr
 2. See webcam active
 3. Press F7
 4. See webcam get immediately disabled
 5. Without pressing F7 again, start the webcam
 6. The webcam is active again
 
So the button can "kill" an active webcam, but it cannot prevent the webcam from activating again.

The sound control buttons (F1 / F2 / F3) do not seem to do anything out of the box.
Likewise, F9-F12 didn't seem to do anything either.

