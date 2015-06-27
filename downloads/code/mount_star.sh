#!/bin/bash

# mount_star.sh
# Copyright (C) 2015 Joe Ruether jrruethe@gmail.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

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
   echo "Usage: $0 <*.star>"
   exit 1
fi

# Make sure the first argument is an existing file
if [ ! -f $1 ]; then
   echo "File does not exist: $1"
   exit 1
fi

# Save some variables
star_file=$1
star_name=${star_file%.star}
star_old=${star_name}_old
star_changes=${star_name}_changes
star_new=${star_name}_new

# Get the password
echo -n 'Enter the password:'
read -s password
echo

# Make the directories
mkdir -p $star_old
add_on_exit_reverse rmdir $star_old

mkdir -p $star_changes
add_on_exit_reverse rmdir $star_changes

mkdir -p $star_new
add_on_exit_reverse rmdir $star_new

# Mount the star file
sudo truecrypt -t --non-interactive --password=$password $star_file $star_old
add_on_exit_reverse sudo truecrypt -t --non-interactive -d $star_old > /dev/null 2>&1

# Mount the tmpfs
sudo mount -t tmpfs tmpfs $star_changes
add_on_exit_reverse sudo umount -lf $star_changes

# Mount the aufs
sudo mount -t aufs -o dirs=$star_changes=rw:$star_old=ro aufs $star_new
add_on_exit_reverse sudo umount -lf $star_new

# Wait for user to continue
echo "Star is now mounted. Press Enter to unmount and exit"
read

