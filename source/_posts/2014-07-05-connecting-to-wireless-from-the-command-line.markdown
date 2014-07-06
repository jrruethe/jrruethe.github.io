---
layout: post
title: "Connecting to wireless from the command line"
date: 2014-07-05 20:22:15 -0400
comments: true
categories: 
---

It can be tricky to figure out how to connect to a wireless network via the command line.  
However, the steps are simple. Below is a script to do all the work for you.

    #!/bin/bash
    # Connect to a wireless network secured with WPA2
    # Usage: ./connect.sh <SSID>
    # Run this as root

    # Parse command line arguments
    SSID=$1

    # Ensure the interface is up
    ifconfig wlan0 up

    # Create a configuration file
    echo Enter the passphrase for $SSID:
    wpa_passphrase $SSID > ./wpa.conf

    # Connect to the access point
    wpa_supplicant -Dwext -iwlan0 -c./wpa.conf -B

    # Obtain an IP address
    dhclient -r
    dhclient wlan0

    # Test the connection
    ping -c 1 www.google.com