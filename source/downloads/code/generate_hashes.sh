#!/bin/sh

# Usage: ./generate_hashes.sh [directory]
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
HASH=sha256

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
