---
layout: post
title: "Squashed Truecrypt Archive"
date: 2015-03-30 20:32:22 -0400
comments: true
categories: 
---

This post presents a script that can create a squashfs filesystem inside of a truecrypt container.  
This has many benefits over encrypted zip files as well as normal truecrypt containers:

- Resulting file can be mounted and accessed directly
    - No need to "unzip" to the hard drive
    - No chance for leaking unencrypted data to the hard drive
 - Achieve both good compression as well as strong encryption
    - Better compression ratio than NTFS, BTRFS, GZIP, BZIP2
 - Truecrypt container is only as large as it needs to be
    - No need to guess the approximate size of the compressed result before compressing
 - Resulting file is immutable
    - Making changes is still possible with an easy workaround, described below

First, the script. It is named `star`, for "**S**quashed **T**ruecrypt **AR**chive". You will need the following to run it:

 - squashfs-tools
 - truecrypt
 - aufs-tools

{% include_code lang:bash star %}

Here is an example of how to use it:

    $ mkdir secret_stuff
    $ dd if=/dev/urandom bs=1MB count=10 > secret_stuff/secret_data.bin
    10+0 records in
    10+0 records out
    10000000 bytes (10 MB) copied, 0.741577 s, 13.5 MB/s
    
    $ ls
    secret_stuff  star
    
    $ ./star 
    Usage: ./star <directory> [name]
    
    $ ./star secret_stuff
    Enter the password to use:
    Repeat the password:
    Success
    
    $ ls
    secret_stuff  secret_stuff.star  star
    
    $ mkdir mnt
    $ sudo truecrypt -t secret_stuff.star 
    Enter mount directory [default]: mnt
    Enter password for /home/joe/Downloads/temp/secret_stuff.star: 
    Enter keyfile [none]: 
    Protect hidden volume (if any)? (y=Yes/n=No) [No]: 
    
    $ ls mnt/
    secret_data.bin
    
    $ sha256sum secret_stuff/secret_data.bin 
    5342d4e85a221df35c5beda80e7b93b609fca732b908b6fd43febfcc89c324ea  secret_stuff/secret_data.bin
    $ sha256sum mnt/secret_data.bin 
    5342d4e85a221df35c5beda80e7b93b609fca732b908b6fd43febfcc89c324ea  mnt/secret_data.bin

The resulting file is immutable. This may seem like a downside at first, but it can be beneficial. For example, it can be mounted by multiple users simultaneously when shared via Dropbox or Bittorrent Sync, and it is easy to version control.

Making secure modifications to the archive is possible because the archive allows direct access via mounting. This is something that cannot be easily done with a normal zip file or tarball. By using a tmpfs filesystem as a writable aufs layer on top of the archive, edits can be made in memory that never touch the hard drive, so your encrypted data stays secure. Then, a new archive can be created from that tmpfs layer.

Layers can be kept separate and treated as diffs (similar to how Docker containers operate), or they can be "resquashed" together for maximum compression. It all depends on the user's needs.

Here is a script that mounts a tmpfs aufs layer on top of the archive to allow edits.

{% include_code lang:bash mount_star.sh %}
    
Use it like so:

    $ ./mount_star.sh 
    Usage: ./mount_star.sh <*.star>

    $ ./mount_star.sh ./secret_stuff.star 
    Enter the password:
    Star is now mounted. Press Enter to unmount and exit
    
Now in another terminal, you can interact with the mounted volumes:

    $ ls
    mount_star.sh  secret_stuff_changes  secret_stuff_old  starsecret_stuff_new  secret_stuff.star
    
    $ touch secret_stuff_old/lala
    touch: cannot touch ‘secret_stuff_old/lala’: Read-only file system
    
    $ touch secret_stuff_new/lala
    
    $ ls secret_stuff_new
    lala  secret_data.bin
    
    $ ls secret_stuff_changes/
    lala

Creating a new archive is as simple as star'ing the name_new branch. Creating a "patch" is as simple as star'ing the name_changes branch:

    $ dd if=/dev/urandom bs=1MB count=10 > secret_stuff_new/new_secret_data.bin10+0 records in
    10+0 records out
    10000000 bytes (10 MB) copied, 0.756202 s, 13.2 MB/s
    $ ls secret_stuff*
    secret_stuff.star
    
    secret_stuff_changes:
    lala  new_secret_data.bin
    
    secret_stuff_new:
    lala  new_secret_data.bin  secret_data.bin
    
    secret_stuff_old:
    secret_data.bin

    $ ./star secret_stuff_changes/
    Enter the password to use:
    Repeat the password:
    Success
    
    $ ls
    mount_star.sh  secret_stuff_changes.star  secret_stuff.star  star
    
Patch archives can be applied using aufs layers with the following script:

{% include_code lang:bash patch_star.sh %}
    
Here is how it works:
    
    $ ./patch_star.sh 
    Usage: ./patch_star.sh <base *.star> <patch *.star>
    
    $ ./patch_star.sh secret_stuff.star secret_stuff_changes.star 
    Enter the password for secret_stuff.star :
    Enter the password for secret_stuff_changes.star :
    Star is now mounted and patched. Press Enter to unmount and exit

    ls
    mount_star.sh  patch_star.sh  secret_stuff  secret_stuff_changes.star  secret_stuff.star  star
    $ ls secret_stuff
    lala  new_secret_data.bin  secret_data.bin
    
This can be very handy for transferring small edits to a large archive across the network in a secure manner, without needing to retransfer the whole archive. The layering effect also acts as a poor man's version control. In the future, I would like to expand on this idea and write a script to manage the layers more convieniently and effectively, perhaps in a manner similar to Git or Docker.
