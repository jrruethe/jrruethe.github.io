---
layout: post
title: "Running Docker in Qubes"
date: 2016-04-15 18:09:15 -0400
comments: true
categories: 
---

This is a quick post describing how to run Docker inside of a Qubes Appvm.

## Create a new template

I chose to clone my existing Debian template. This tutorial assumes the template is Debian-based. Ideally your template would be very minimal, only requiring basic packages such as the following:

 - git
 - gedit
 
If you are also planning on using the dockerfile generator, you will need the following:

 - ruby
 - ruby-dev
 - gcc
 - make
 - fpm (`sudo gem install fpm`)

Here is my template:

{% img center ./01.png %}

Make sure that the update proxy is disabled in the firewall settings:

{% img center ./02.png %}

## Install Docker to the template[^1]

Run the following commands in the terminal:

    sudo apt-get update
    sudo apt-get install curl
    curl -fsSL https://get.docker.com/ | sh
      
Next, enable the default user to use Docker:
   
    sudo usermod -aG docker user
   
## Change the default directory[^2]

    sudo vim /etc/systemd/system/docker.service

Add the following to the file:

    [Service]
    ExecStart=
    ExecStart=/usr/bin/docker daemon -H fd:// -g /home/user/docker

Finally, run the following command to apply the configuration:

    sudo systemctl daemon-reload

## Create an Appvm

First, poweroff the template. Then create an Appvm based on the template. Increase the available disk space, since the docker images are being stored in the persistent private storage.

{% img center ./03.png %}

## Test it out

Run the following command in the Appvm as the normal user:

    docker run -it --rm hello-world
   
You should see the following:

{% img center ./04.png %}

[^1]: [https://docs.docker.com/linux/step_one/](https://docs.docker.com/linux/step_one/)
[^2]: [https://docs.docker.com/engine/admin/systemd/](https://docs.docker.com/engine/admin/systemd/)

