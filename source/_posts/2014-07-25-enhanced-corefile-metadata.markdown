---
layout: post
title: "Enhanced Corefile Metadata"
date: 2014-07-25 22:26:50 -0400
comments: true
categories: 
---

At the following Github repository you will find a ruby script to produce enhanced corefile metadata upon a core dump.   
It hooks into the kernel's corepattern mechanism to accept the core dump via stdin and extract information from the process before it is killed. It then runs GDB to produce a backtrace and grab the register contents.

[Enhanced Corefile Metadata](https://github.com/jrruethe/corefile)

Here is a list of metadata that is written out on every core dump:

 - Binary that crashed
 - Corefile from the crash
 - Signal causing the crash
 - Original filepath
 - Original file size
 - MD5 checksum of the binary
 - MD5 checksum of the corefile
 - Creation, modification, and access times of the binary
 - Hostname and PID of the crashed process
 - User, group, and permissions of the crashed process
 - The setuid bit
 - Working directory of the process
 - Invoked command line parameters
 - Stack trace
 - Memory Map
 - Environment variables
 - Frame information
 - Register states

This script is very useful for bug reports as well as devloping buffer overflow exploits.
To install, save `corefile.rb` somewhere. Edit `/etc/sysctl.conf` and set the `kernel.core_pattern` parameter as follows:

    kernel.core_pattern=|/path/to/corefile.rb %e %p %u %g %h %s
    
*Take note of the pipe character!*

If you want to test it out, simply crash something.  
Make sure you use `ulimit -c unlimited` or have corefiles enabled in `sysctl.conf`.
