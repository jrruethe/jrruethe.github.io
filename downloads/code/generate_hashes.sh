#!/bin/sh

# generate_hashes.rb
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

# Usage: ./generate_hashes.sh [directory] [hash]
# Check the result with sha256sum -c <result>

# See if a directory was defined
if [ $1 ]; then
   DIRECTORY=${1%/}
   REPLACE=${DIRECTORY}/
   
   if [ ! -d $DIRECTORY ]; then
      echo "Directory does not exist: $DIRECTORY"
      exit 1
   fi
else
   # Use the current directory
   DIRECTORY='.'
   REPLACE='\./'
fi

# Hash type to use
HASH=${2:-sha256}

# Generate the output filename
OUTPUT=hashes.$HASH

# Determine which program to use
HASHER=${HASH}sum

# Remove any existing hash file
rm -f $DIRECTORY/$OUTPUT

# Find all files in the directory
# that do not have the output filename
# and hash them. Store the output in the target directory
find $DIRECTORY -type f ! -name "$OUTPUT" -exec $HASHER {} \; >> $DIRECTORY/$OUTPUT

# Sort the output on the filename column
sort -u -k2 -o $DIRECTORY/$OUTPUT $DIRECTORY/$OUTPUT

# Remove the directory from the listings
sed -i "s@ $REPLACE@@g" $DIRECTORY/$OUTPUT
