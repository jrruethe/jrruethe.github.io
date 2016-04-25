---
layout: post
title: "Open Terminator from Nautilus"
date: 2014-07-06 14:22:25 -0400
comments: true
categories: 
---

This is just a little trick to get the ability to open a Terminator terminal at any location from Nautilus by right clicking on a folder.

{% more %}

First install the dependencies:

    sudo apt-get install nautilus-open-terminal terminator
    
Next, *uninstall* `gnome-terminal`:

    sudo apt-get remove gnome-terminal
    
Finally, create a symlink to `terminator` from `gnome-terminal`:

    sudo ln -s /usr/bin/terminator /usr/bin/gnome-terminal
    
All done! Now you can right click on any folder in Nautilus and open a terminator window.  
The reason the symlink is needed is because `nautilus-open-terminal` is hardcoded to use `gnome-terminal` by default, but `terminator` is much better.
