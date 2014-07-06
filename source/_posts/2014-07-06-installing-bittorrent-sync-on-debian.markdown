---
layout: post
title: "Installing Bittorrent Sync on Debian"
date: 2014-07-06 14:51:39 -0400
comments: true
categories: 
---

Bittorrent Sync is an awesome folder synchronization tool that uses the Bittorrent protocol. It is simple and fast alternative to Dropbox. Best of all, the files are only ever stored on machines *you* choose; there is no "cloud" or third party servers.  

I use Bittorrent Sync to keep all my machines up to date with eachother, share files, and perform backups. It works on Windows, Linux, and Android. Unfortunately, it is not open source, however I am still a fan of this software.

There is no official installer for Bittorrent Sync on Debian, but the steps to get it working are pretty simple.  
First you need to go get the software: 

 - [32 Bit](http://www.bittorrent.com/sync/downloads/complete/os/i386)
 - [64 Bit](http://www.bittorrent.com/sync/downloads/complete/os/x64)
 
I suggest unpacking it to /opt/btsync:

    mkdir /opt/btsync
    mv btsync_x64.tar.gz /opt/btsync
    cd /opt/btsync
    tar xzvf ./btsync_x64.tar.gz
    
Next, create a configuration file:

    ./btsync --dump-sample-config > btsync.conf
    
You need to make one change to the config file, and that is the storage path.  
Look for where it says `/home/user/.sync` and change `user` to your username.  
You might be interested in adding a password to the Web UI, which is where you will do all your folder management from. You can find thhat setting near the bottom of the config file.

Next, you want to create an init script. Copy the following to `/etc/init.d/btsync`:

    #! /bin/sh
    # /etc/init.d/btsync
    #
    
    # Carry out specific functions when asked to by the system
    case "$1" in
    start)
        /opt/btsync/btsync --config /opt/btsync/btsync.conf
        ;;
    stop)
        killall btsync
        ;;
    *)
        echo "Usage: /etc/init.d/btsync {start|stop}"
        exit 1
        ;;
    esac
    
    exit 0
    
Finally, run the following commands to finish the installation:

    chmod 755 /etc/init.d/btsync
    update-rc.d btsync defaults
    mkdir ~/.sync
    /etc/init.d/btsync start
    
Thats it! Bittorrent Sync is installed, and will automatically run every time your machine boots.  
You can access the Web UI at 127.0.0.1:8888