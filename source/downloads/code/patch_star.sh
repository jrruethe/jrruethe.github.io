#!/bin/bash

# Mounts a squashed truecrypt archive

# $1 = Star to mount

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

# Make sure enough arguments were specified
if [ -z $1 ]; then
   echo "Usage: $0 <base *.star> <patch *.star>"
   exit 1
fi

# Make sure the first argument is an existing file
if [ ! -f $1 ]; then
   echo "File does not exist: $1"
   exit 1
fi

# Make sure the second argument is an existing file
if [ ! -f $2 ]; then
   echo "File does not exist: $2"
   exit 1
fi

# Save some variables
base_star=$1
base_name=${base_star%.star}

# Patch directory will be hidden
patch_star=$2
patch_name=.${patch_star%.star}

# Get the passwords
echo -n "Enter the password for $1 :"
read -s base_password
echo
echo -n "Enter the password for $2 :"
read -s patch_password
echo

# Make the directories
mkdir -p $base_name
add_on_exit_reverse rmdir $base_name

mkdir -p $patch_name
add_on_exit_reverse rmdir $patch_name

# Mount the base
sudo truecrypt -t --non-interactive --password=$base_password $base_star $base_name
add_on_exit_reverse sudo truecrypt -t --non-interactive -d $base_name > /dev/null 2>&1

# Mount the patch
sudo truecrypt -t --non-interactive --password=$patch_password $patch_star $patch_name
add_on_exit_reverse sudo truecrypt -t --non-interactive -d $patch_name > /dev/null 2>&1

# Apply the patch
sudo mount -t aufs -o dirs=$patch_name=ro:$base_name=ro aufs $base_name
add_on_exit_reverse sudo umount -lf $base_name

# Wait for user to continue
echo "Star is now mounted and patched. Press Enter to unmount and exit"
read

