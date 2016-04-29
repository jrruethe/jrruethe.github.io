---
layout: post
title: "Setting up Qubes"
date: 2015-09-12 11:35:50 -0400
comments: true
toc: true
categories: 
 - Qubes
---

I have recently switched to Qubes OS and I really like it. It has some very handy tools that make working with a secure system seamless. 
I decided I wanted to write about my setup and how to fix the minor problems I encountered. 
As a test, this entire post was written using Qubes, as a way for me to prove to myself that I could still be productive and have an easy-to-use system while remaining secure.

{% more %}

# Understanding Qubes

Qubes is not a distribution of Linux. Rather, it is a set of tools built on top of the Xen hypervisor, allowing you to interoperate between multiple isolated virtual machines. Each virtual machine is "paravirtualized", meaning they all share a common Linux kernel but have separated filesystems, devices, etc. Furthermore, the filesystems are layered such that multiple separate VMs can share a common underlying template to save storage space. In my mind, this is similar in concept to how Docker works. Unlike Docker, which utilizes Linux kernel namespaces, Qubes utilizes hardware enforced isolation via virtualization capabilities in the CPU, so it is much more secure.

The main interface is called `dom0`, and acts as an administration panel for Xen, allowing the user to easily manage and manipulate the various virtual machines. Each virtual machine is given a color so the user can visually assess which security domain they are working in at all times. The Qubes tools allow for secure file/clipboard copying between VMs, controlled networking, and seamless application interaction; You will barely even notice that you are working with a series of virtual machines under the hood.

{% img ./01.png Qubes Example Desktop %}

It is important to understand that Qubes grants the ability to easily create a secure computing environment, but it relies heavily on the user to utilize best practices; it will not prevent foolish mistakes. The user must be mindful about keeping data and connections isolated; Qubes helps you do it effectively.

Read more about Qubes [here](https://www.qubes-os.org/doc/SimpleIntro/).

# Considerations before migrating to Qubes

Qubes 3.0 works very well and is very usable. Its VM management and interaction tool are well done, easy to use, and non-intrusive. However, using Qubes comes with a significant drawback:

 - No non-mass-storage USB devices in VMs

Do not misunderstand; Mass storage devices such as flash drives and external hard drives (block devices) work flawlessly and can be assigned to any VM very easily. However, devices such as USB network cards or Yubikey smartcards do not work in the VMs.

The USB devices do work in `dom0`, meaning that USB keyboards and mice are fine. It would be dangerous to connect a USB network card to `dom0`, because `dom0` should be airgapped. 

>
**Airgapped**  
Airgapping means the machine is never connected to the internet. It is completely isolated, as in "separated by a gap of air". Most of the time, airgapping refers to two physically separated machines, however in the case of Qubes it refers a virtual machine separated from the network. Ideally, files are only ever copied *into* the airgapped machine, never out of it.

There are various hints on the forums that people have gotten this to work, but it seems to be hardware dependent. My laptop has two USB controllers; one dedicated to the touchscreen (which also works flawlessly, by the way), the other dedicated to the external ports. This means that if I assign my USB controller to a VM, *only* that VM has access to those devices. This interferes with my USB wireless mouse. In theory, this should be OK. In practice, I haven't been able to get my VMs to boot when they have the USB controller assigned to them, and I don't seem to be able to reassign the USB controller back to `dom0` easily.

However, these issues are fairly easy for me to work around. If I need 3G/4G modem, I use a mobile wireless hotspot and just connect to the Wifi. Similarily, my printer is network enabled, so I don't need to connect it via USB. As for Yubikeys, the "keyboard" capabilities work out of the box, and Qubes' Split-GPG functionality can substitute the smartcard functionality of the Yubikey.

Read more about these considerations [here](https://www.qubes-os.org/doc/UserFaq/).

# Getting Qubes

Simply download `Qubes-R3.0-rc2-x86_64-DVD.iso` from [here](https://www.qubes-os.org/doc/QubesDownloads/). Be sure to also grab the signature file. Before attempting to burn / install Qubes, you should [verify the signatures](https://www.qubes-os.org/doc/VerifyingSignatures/).

# Installing Qubes

The installer is pretty straightforward. I chose to do manual partitioning, with a `boot` drive of 2GB using `ext4` and a `root` drive taking the remaining space using `btrfs` and `luks` encryption. My plan in the future is to have a Tails iso available for booting from the `boot` drive. My disk has limited space, so I chose `btrfs` for its compression abilities. Finally, be sure to also install the `fedora-21` and `debian-8` templates.

# Creating Domains

The first thing I do is clone the standard `fedora-21` and `debian-8` templates, such that I always have a fresh working fallback in case something goes wrong when modifying them. I typically use two separate `debian-8` templates; one for a minimal image that won't change often, and one for an "experimental" image that I install various software to.

{% img ./02.png Qubes VM Manager %}

I like to have a few primary domains:

 - Personal (Yellow): My configured browser, email, instant messaging, and blogging setup.
 - Work (Orange): Stuff I am working on, experiments, etc.
 - Vault (Green): Passwords, keys, sensitive files.

Qubes is all about isolation. My sensitive files are isolated away to the Vault, which has no network access and never touches a USB drive. I use Qubes' secure file copying from another trusted VM to put things into the Vault.

Other secondary domains include the system proxies, Whonix, and a VM dedicated to Tor:

 - sys-net (Red): Manages the network devices, has direct internet access
 - sys-firewall (Green): A trusted firewall that grants other VMs internet access
 - sys-tor (Green): A Tor proxy that grants other VMs Tor access
 - sys-gpg (Green): A special domain for GPG subkey storage
 - sys-whonix (Violet): The Whonix gateway
 - Tor (Orange): Special domain containing only a web browser configured to use Tor
 - Whonix (Violet): The Whonix workstation

Here is a diagram of how the VM "inheritance" is set up:

{% img ./03.png VM Inheritance %}

As you can see, I have multiple domains that I use at a "personal" level, so they share the same template, which I try to keep minimal and stable. Separate from that is my "testing" template that I do my work in. This typically involves installing experimental software, or development tools / libraries that I don't want cluttering up my personal domain.

Here is a diagram of how the VM networking is set up:

{% img ./04.png VM Networking %}

There are a couple things to note here:

 - All domains get network access from the firewall. This isolates the system from the internet as much as possible.
 - Sensitive VMs such as `sys-gpg` and the `Vault` do not (and will never have) network access. This keeps them airgapped.
 - The Whonix templates must access the internet through the Whonix gateway, otherwise they won't be able to update.

# Fixes

For the most part, Qubes works great out of the box, however there are a few things that need small fixes, especially after performing the first software update in `dom0` and the template VMs.

## Fixing Nautilus in Debian [^1]

After updating, Nautilus won't open due to a dbus error. 
To fix this, replace the contents of `/usr/bin/qubes-desktop-run` in your Debian templates with the following:

{% codeblock lang:python %}
#!/usr/bin/python

from gi.repository import Gio
import sys
import dbus

def main(myname, desktop, *files):

    launcher = Gio.DesktopAppInfo.new_from_filename(desktop)
    activatable = launcher.get_boolean('DBusActivatable')
    if activatable:
        bus = dbus.SessionBus()
        id = launcher.get_id()
        id = id[:-8]
        bus.start_service_by_name(id)
    launcher.launch(files, None)

if __name__ == "__main__":
    main(*sys.argv) 
{% endcodeblock %}

Note that this has already been fixed in the upstream repo, and may not be needed in the future.

## Fixing Terminal in Debian [^2]

After upgrading, the locale's might get messed up, causing `gnome-terminal` to not load.
Run the following commands as root in your Debian templates:

    localedef -f UTF-8 -i en_US -c en_US.UTF-8
    update-locale LC_ALL=en_US.UTF-8
    
## Fixing Copy To VM [^3]

The secure copy-to-vm scripts require the Python GTK bindings, but they are not installed by default.
Install `python-gtk2` in all your Debian templates:

    apt-get install python-gtk2

## Fixing Copy / Paste [^4]

In the terminal, `Ctrl-Shift-c` and `Ctrl-Shift-v` are mapped to copy and paste.
However, in Qubes, these are mapped to the global cross-vm copy-paste commands.
Lets change the Qubes shortcut keys to use the little "Windows" key next to the Alt key.

In `dom0`, edit `/etc/qubes/guid.conf` to uncomment and set the following lines:

    secure_copy_sequence = "Mod4-c";
    secure_paste_sequence = "Mod4-v";

# Installing Tor [^5]

The instructions from the Qubes website are pretty straightforward, but I will replicate them here by using the GUI instead of the command line.

First create a copy of the standard `fedora-21` template:

{% img ./05.png Clone Template %}

Next, create a `sys-tor` proxy VM from that template:

{% img ./06.png ProxyVM %}

In a `dom0` terminal, enter the following commands:

    qvm-service sys-tor -d qubes-netwatcher
    qvm-service sys-tor -d qubes-firewall
    qvm-service sys-tor -e qubes-tor

Fire up the `fedora-21-tor` template and install Tor:

    sudo yum install qubes-tor-repo
    sudo yum install qubes-tor
    
Now all you need to do is make a normal VM and use `sys-tor` as your network:

{% img ./07.png Tor Network %}

Note that while this gives you access to Tor, it isn't necessarily optimized for privacy. For that you will want Whonix.

# Installing Whonix [^6]

The Whonix developers have done a great job making Whonix templates that are super easy to install. Simply run the following in a `dom0` terminal:

    sudo qubes-dom0-update --enablerepo=qubes-templates-community qubes-template-whonix-gw qubes-template-whonix-ws

Once that command completes, you will have two new templates available: `whonix-gw` and `whonix-ws`, for the gateway and workstation respectively.

This is where things get slightly confusing. You need to create a VM that uses the gateway template, and use *that* as the network for the template itself in order to update it. Set up a VM like this:

{% img ./08.png Whonix Gateway %}
{% img ./09.png Whonix Gateway Firewall %}

Then, set up your `whonix-gw` template like this:

{% img ./10.png Whonix Gateway Template %}
{% img ./11.png Whonix Gateway Template Firewall %}

Finally, set up your `whonix-ws` template like this:

{% img ./12.png Whonix Workstation Template %}
{% img ./13.png Whonix Workstation Template Firewall %}

After that, you can shutdown those three VMs and create the workstation VM:

{% img ./14.png Whonix Workstation %}
{% img ./15.png Whonix Workstation Firewall %}

Fire it up and it will automatically start the gateway. Both VMs will do their thing and synchronize to the network.

[^1]: [https://groups.google.com/forum/#!searchin/qubes-users/nautilus/qubes-users/cUTu9xQGvI0/OiT8t8BcCgAJ](https://groups.google.com/forum/#!searchin/qubes-users/nautilus/qubes-users/cUTu9xQGvI0/OiT8t8BcCgAJ)
[^2]: [https://groups.google.com/forum/#!topic/qubes-users/CuC-El1qoss](https://groups.google.com/forum/#!topic/qubes-users/CuC-El1qoss)
[^3]: [https://groups.google.com/forum/#!topic/qubes-users/say__leey3o](https://groups.google.com/forum/#!topic/qubes-users/say__leey3o)
[^4]: [https://github.com/QubesOS/qubes-gui-daemon/blob/master/gui-daemon/xside.c](https://github.com/QubesOS/qubes-gui-daemon/blob/master/gui-daemon/xside.c)
[^5]: [https://www.qubes-os.org/doc/UserDoc/TorVM/](https://www.qubes-os.org/doc/UserDoc/TorVM/)
[^6]: [https://www.whonix.org/wiki/Qubes/Binary_Install](https://www.whonix.org/wiki/Qubes/Binary_Install)

