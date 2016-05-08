#!/bin/bash

# connect.sh
# Copyright (C) 2016 Joe Ruether jrruethe@gmail.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

# Connect to a wireless network secured with WPA2
# Usage: connect.sh <SSID>
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
