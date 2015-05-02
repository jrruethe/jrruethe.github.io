#!/bin/bash

# Stop on any error
set -e

# Declare an array of tasks to perform on exit
declare -a on_exit_items

# This function is run on exit
function on_exit()
{
    for i in "${on_exit_items[@]}"
    do
        eval $i
    done
}

# Add to the list of tasks to run on exit
function add_on_exit_reverse()
{
    on_exit_items=("$*" "${on_exit_items[@]}")
    if [[ $n -eq 0 ]]; then
        trap on_exit EXIT
    fi
}

# Check to make sure we are running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Define variables
insecure_root=insecure_root
tmpfs_redirect=tmpfs_redirect
secure_root=secure_root

# Disable Swap
swapoff -a

# Create the mount points
mkdir -p $insecure_root
mkdir -p $tmpfs_redirect
mkdir -p $secure_root

# Clean up the mount points
add_on_exit_reverse rmdir $insecure_root
add_on_exit_reverse rmdir $tmpfs_redirect
add_on_exit_reverse rmdir $secure_root

# Bind mount the root directory
mount --bind / $insecure_root
add_on_exit_reverse umount $insecure_root || umount -lf $insecure_root

# Remount the root directory as read only
mount -o remount,ro,bind $insecure_root

# Create a tmpfs filesystem
mount -t tmpfs tmpfs $tmpfs_redirect
add_on_exit_reverse umount $tmpfs_redirect || umount -lf $tmpfs_redirect

# Aufs mount to redirect all 
mount -t aufs -o br=$tmpfs_redirect=rw:$insecure_root=ro none $secure_root
add_on_exit_reverse umount $secure_root || umount -lf $secure_root

# Mount the necessary filesystems in the chroot
mount --bind /dev $secure_root/dev
mount -t proc none $secure_root/proc
mount -t sysfs none $secure_root/sys
mount -t devpts none $secure_root/dev/pts

add_on_exit_reverse umount $secure_root/dev || umount -lf $secure_root/dev
add_on_exit_reverse umount $secure_root/proc || umount -lf $secure_root/proc
add_on_exit_reverse umount $secure_root/sys || umount -lf $secure_root/sys
add_on_exit_reverse umount $secure_root/dev/pts || umount -lf $secure_root/dev/pts

# Everything is set up, enter the chroot
set +e

# Start the nested X server
Xephyr -screen 1024x768 -name "Temporary Security Mirror" -title "Temporary Security Mirror" :1 &

# Wait for the X server to start
sleep 5

# Chroot in and startx
chroot $secure_root env DISPLAY=localhost:1 /usr/bin/fluxbox 

# Wait for things to settle down
sleep 5
