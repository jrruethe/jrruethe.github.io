---
published: false
layout: post
title: "Docker Templates"
date: 2015-06-28 16:59:31 -0400
comments: true
categories: 
---

This post is about how to take an application and package it as a Docker image.

There are many times when I want to run an application, but I don't want to dirty my system up with all the dependencies. Sometimes an application is packaged for Ubuntu, but not for Debian, and I would rather not mix in the necessary repositories. Finally, there are cases where I would rather have the software compiled automatically without me needing to install a bunch of development tools and libraries. For these cases, Docker is very handy.

I am aware that the "proper" way to handle persistent data in Docker is to use data-container volumes. However, I rarely do this in practice; many times I want an application to interact with data on my host machine while still allowing the host to access it as well. For example, Owncloud, Bittorrent Sync, and Crashplan are all applications that I run from containers, yet share data with the host.

I have found that I tend to use the same general layout for my Dockerfiles, build scripts, and run scripts, such that I have tried to make them as template-like as I can. This makes it easy for me to begin working on Dockerizing an application with little effort. I've also picked up a few tricks along the way that might be useful to you.

>
**Security**  
Please be aware that some of the things discussed below are considered insecure, such as using insecure SSH keys, X forwarding, using the root user, and opening ports. The use case is oriented towards using Docker as a portable application on a personal computer, not for hosting a service on the internet. Please use caution!

---
## The Run Command

Each command in Docker adds another layer to the image. Layers all get squashed together when a container is run from an image, so you only see the cumulation of changes as the final result. It is important to understand that deleting something in an upper layer will hide the data at that layer, but it will still be present in a lower layer. This means the image as a collection of layers will not decrease in size. For this reason, it is important to consolidate the run commands and clean up after yourself before committing a layer. Of course, this causes run commands to be multi-line, separated with `&&` and ending with multiple `\` characters. 

#### Comments

Something I immediately didn't like about this was the lack of comment support, until I stumbled on this cool trick:

    RUN `# Do something`      && \
         command-one          && \
        `# Do something else` && \
         command-two
    
Anything inside the backticks get executed by the shell, except that the execution is a comment. This pattern allows you to interleave comments inside of a multi-line run command, which I find very handy for complicated commands.

#### Software Installation and Cleanup

Typically you only want to install the base minimum dependencies when creating a Docker image, in order to keep the file size down. Disable recommends when installing packages to prevent bloat from creeping in.

I generally do not do an `apt-get upgrade` when creating a Docker image. Any software I am trying to Dockerize will update whatever packages it needs naturally. This way I can stay close to the original base image and keep the file size down.

Lastly, clean up after an installation, before all that garbage gets committed to a layer. This includes the package lists themselves, as they are no use once the image is created.

#### Apt-cacher-ng

#### Adding repositories

If you are adding a repository by echoing it into sources.list, you are also going to need the repository key. This generally means you need to install `wget` and `ssl-cert` first. Example:

    apt-get update && apt-get -y install --no-install-recommends wget ssl-cert                                                              && \
    wget -O - http://download.opensuse.org/repositories/isv:ownCloud:community/xUbuntu_14.04/Release.key | apt-key add -                    && \
    echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/community/xUbuntu_14.04/ /' >> /etc/apt/sources.list.d/owncloud.list && \
    apt-get update && apt-get -y install --no-install-recommends owncloud

If you are adding a PPA, you won't need `wget` or `ssl-cert`, but you do need to make sure that the PPA is added before an apt-cacher-ng proxy is in place. Example:

    add-apt-repository -y ppa:bitcoin/bitcoin                                                 && \
    echo 'Acquire::http { Proxy "http://172.17.42.1:3142"; };' >> /etc/apt/apt.conf.d/01proxy && \
    apt-get update && apt-get -y install --no-install-recommends bitcoind

#### Installing *.deb packages

Installing a *.deb package using `dpkg` will not autoresolve dependencies, and will usually error out. You can account for this by short-circuiting it with `true`. Then, simply issue an `apt-get -f install` to have the dependencies automatically installed. Example:

    (dpkg -i armory_0.93.2_ubuntu-64bit.deb || true) && \
    apt-get -y -f install --no-install-recommends    

---
## Phusion's Base Image

An important thing to remember is that the entry point should always be:

    ENTRYPOINT ["/sbin/my_init"]

#### Enabling SSH

#### Enabling Services

#### Adding a new user

Explain uid 1000

When developing a Docker image, you need to rebuild often, and it doesn't make sense to redownload all those packages over and over again.

## Dockerfile

The easiest way to determine what needs to go in your Dockerfile is to boot up the baseimage and try out the commands you need in order to achieve the outcome you desire. Record each command you type in sequence. Keep in mind that the Dockerfile is not interactive, so you need to account for this by passing in switches like `-f`, `-y`, or `-q` to commands. Sometimes, you may even need to `echo yes | command`.

Your sequence of commands becomes the basis for the `RUN` command in the Dockerfile.

#### Experimenting

#### Port Forwarding

#### Dockerfile Template

---
## Build Script

#### Apt-cacher-ng

Because our image supports the apt-cacher-ng http proxy, we need to make sure it is running before we begin building our image.

#### Saving the generated image

Like it or not, most images rely on internet access. There will be software updates, version changes, and broken links. It sucks when you get an image to build and run correctly, only to find that some time in the future it no longer builds when you need it. Therefore, it is always a good idea to save a copy of a successfully built image.

#### Loading a pre-built image

If an image has already been built, there isn't much of a reason to rebuild it, unless you are specifically trying to update software versions. For that reason, it makes more sense to load a pre-built image if it is available.

#### Build Script Template

---
## Run Script

#### Naming Containers

#### Sharing Volumes

#### Sharing X Server

This method works well for most GTK applications. However, it doesn't seem to work for QT applications. For QT apps, you should stick to X forwarding using SSH.

#### SSH X Forwarding

The SSH server in the image takes a small amount of time to start up, therefore you may need to try connecting a few times to ensure success.

#### Sharing Audio

#### Container Management

#### Run Script Template

---
## Example

See the following repositories for some Docker images that use the techniques described above:


