---
layout: post
title: "Debian Expert Install"
date: 2014-07-04 19:54:30 -0400
comments: true
categories: 
---

When I do a new installation of Debian, I always choose to do an expert install.  
This gives me finer control of how the system turns out.  

The goals of this are simple:

 - Minimal base image to build off of
 - Full disk encryption with LUKS + LVM

So lets begin!

*TODO: Add pictures of each step. I'll do this next time I install on a Virtual Machine*

### Step 1

Download the latest stable Debian Netinst ISO.  
Either burn it to a disk or load it into a VM.  
Getting the ISO to boot is out of the scope of this document.

### Step 2

At the boot screen, scroll down to "Advanced Options".  
On the following menu, select "54 bit expert install".

### Step 3

Get through all the language questions and keyboard layout.  
Select English for everything.  
Make sure the CD gets detected and mounted.

### Step 4

Next you will be given the option to load installer components from the CD.  
On this screen, enable "crypto-dm-modules".

### Step 5

Next we need to connect to the network.  
I usually end up installing over wireless so these instructions will do just that.  
Select "Detect network hardware" followed by "Configure the network".  
Then, select "wlan0" from the list of network interfaces.  

Select the SSID of your network, the encryption type (WPA2 PSK) and enter the passphrase.  
Let it auto-configure using DHCP.

### Step 6

Select a hostname. I try to stick to names that describe what the system will be used for.  
Leave the domain name blank.

### Step 7

When setting up users and passwords, be sure to enable shadow passwords.  
Also, disallow login as root. To gain root access you will need to use `sudo su` from your user account.  
Enter your full name, followed by your username.  
Finally, choose a strong password. This will be the password for your user account, and also the password you need to access the root account.  
It will NOT be the password you use to mount the encrypted volume at boot time.  

### Step 8

Configure the clock for NTP using the default server.  
Then select your time zone.

### Step 9

Next, you will detect disks, and partition them.  
For this step, we are going to select "Guided - use entire disk and set up encrypted LVM"  
Be very sure to select the correct disk!  
Choose to keep "/home" on a separate partition.  
Review the information and if everything looks good, commit it to the disk.  
Erasing the disk and setting up the partitions will take some time, so just wait it out.

---

### Step 10

You will be asked for an encryption passphrase. Be sure to choose a long one, and don't forget it!  
Without this key, your files are gone forever.

### Step 11

Set the name of your LVM volume group, I usually set it the same as the hostname.  
It will ask you to verify the LVM volumes, after which it will perform the partitioning.

### Step 12

You are finally ready to install the base system.  
The core packages will be downloaded. Sit back and wait.  
You will be asked to select a kernel, choose the generic one without a version number.

---

### Step 13

Next, you will be asked which drivers to include in the initramfs.  
Be sure to choose generic here, it will come in handy later.

### Step 14

Now you get to configure the package mananger.  
Be sure to enable the network mirror to get the most up to date packages.  
Select the default mirror.  
When asked, enable non-free software if you wish.  
Finally, enable the two update options from the security and release repositories.  
There will be a long wait while the installer prepares to initate the base system.

---

### Step 15

When asked, choose to opt out of package statistics.  
Also, choose to disable man page setuid.

### Step 16

It is time to install the software.  
We are going to do the minimal installation, so uncheck all the boxes.  
Select the bottom option: "Standard system utilities".  
Also select "Laptop" if applicable.  
There will be another long wait while the base system is set up.

---

### Step 17

Install the Grub bootloader onto the MBR of the disk.

### Step 18

Set the clock to UTC time  
Finish the installation and reboot.  
Enter your LUKS password and enjoy your new minimal Debian installation!
