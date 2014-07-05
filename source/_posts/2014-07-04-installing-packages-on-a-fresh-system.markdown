---
layout: post
title: "Installing Packages on a Fresh System"
date: 2014-07-04 22:49:53 -0400
comments: true
categories: 
---

When I do a fresh Debian installation, I always have a set number of packages I use for various tasks.  
This post is more of a reminder to myself for when I need a package list for a task. It also means I don't have to remember the name of that one package I needed to make something work.

These lists are useful for creating a single purpose system:

 - Bare Metal machines
 - Virtual machines
 - Docker containers

Typically for a development machine I install all the packages in my list.  
But it is very easy to comment out a line to prevent the installation of a group.  
Since some groups might be enabled while others are disabled, there are some duplicate packages across groups.
This can be useful for creating minimal systems, coldboot machines, backup machines, or development machines.

The script is organized into the following package groups, designed to handle specific tasks:

 - Common CLI packages
 - Minimal Desktop Environment
 - LVM / LUKS support
 - System Optimization
 - Networking
 - Printing
 - Audio
 - Bluetooth
 - Virtual Machines
 - Development
 - Documents
 - Ruby
 - Java
 - Blogging
 - Dropbox
 - GPG
 - Yubikey
 - Tor
 - Bitcoin
 - Python
 
As my workflow evolves, this script will be updated with additional packages and groups.
 
The script can be found [here](https://github.com/jrruethe/install-packages).