---
layout: post
title: "Temporary Security Mirror"
date: 2015-05-02 15:31:12 -0400
comments: true
categories: 
 - Scripts
---

Sometimes you need to perform a task in a secure way that leaves no trace on your computer. 
The traditional way of accomplishing this is to boot from a live CD like [Tails](https://tails.boum.org/). 
The problem with this is that you might need the software, drivers, or setup you have on your main operating system to accomplish the task. 
An example of this might be creating a Bitcoin Paper Wallet with a proprietary printer; it might be too difficult to set up the printer on a live CD for a one-off task.

{% more %}

Below is a script that help for these specialized cases. It creates a secure mirror of your system that never touches the disk; anything you do is wiped away on shutdown. Best part is, you can use this from an already running system. 

This script will:

 - Disable swap
 - Do a read only bind mount of root
 - Apply a tmpfs aufs layer over the read only root view
 - Start an X server and chroot into the root view

The end result is a temporary secure mirror of your running system.  
You need the following installed for this to work:

 - aufs-tools
 - Xephyr
 - fluxbox

Simply run `tsm.sh` and you will get a window of your running system, where anything you do is forgotten when closed. You will have access to all your files and devices. For more security, close any applications and disconnect your internet before running this script. When finished, close the window and restart your computer.

{% include_code lang:bash tsm.sh %}
