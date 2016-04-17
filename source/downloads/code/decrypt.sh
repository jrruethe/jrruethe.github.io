#!/bin/bash

# decrypt.sh
# Copyright (C) 2016 Joe Ruether jrruethe@gmail.com
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

# Decrypts a file
# decrypt.sh <file> <recipient_private_key> [sender_certificate]
# 1) (Required) File to decrypt
# 2) (Required) Private key of the recipient
# 3) (Optional) Certificate of the sender

# Stop on any error
# set -e

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
function add_on_exit()
{
    local n=${#on_exit_items[*]}
    on_exit_items[$n]="$*"
    if [[ $n -eq 0 ]]; then
        trap on_exit EXIT
    fi
}

if [ "$#" -lt 2 ]; then
   echo "Usage: decrypt.sh <file> <recipient_private_key> [sender_certificate]"
   exit 1
fi

FILE=$1
RECIPIENT_PRIVATE_KEY=$2
SENDER_CERTIFICATE=$3

OUTPUT=${FILE//.tar/}
COMPRESSED_FILE=${OUTPUT}.bz2
ENCRYPTED_FILE=${COMPRESSED_FILE}.encrypted
SYMMETRIC_KEY=symmetric_key.bin
ENCRYPTED_KEY=${SYMMETRIC_KEY}.encrypted

SENDER_PUBLIC_KEY=${SENDER_CERTIFICATE//certificate/public}
SIGNATURE=${OUTPUT}.signature
ENCRYPTED_SIGNATURE=${SIGNATURE}.encrypted

# Unpack the encrypted key
tar xf ${FILE} ${ENCRYPTED_KEY} > /dev/null 2>&1
SUCCESS=$?
add_on_exit rm -f ${ENCRYPTED_KEY}

if [ ${SUCCESS} -ne 0 ]; then
   echo "Not a valid encrypted file"
   exit 1
fi

# Decrypt the symmetric key
openssl rsautl -decrypt -inkey ${RECIPIENT_PRIVATE_KEY} -in ${ENCRYPTED_KEY} -out ${SYMMETRIC_KEY} > /dev/null 2>&1
SUCCESS=$?

if [ ${SUCCESS} -ne 0 ]; then
   add_on_exit rm -f ${SYMMETRIC_KEY}
   echo "Unable to decrypt: Incorrect key"
   exit 1
else
   add_on_exit shred ${SYMMETRIC_KEY}
   add_on_exit rm -f ${SYMMETRIC_KEY}
fi

# Unpack the encrypted file
tar xf ${FILE} ${ENCRYPTED_FILE} > /dev/null 2>&1
SUCCESS=$?
add_on_exit rm -f ${ENCRYPTED_FILE}

if [ ${SUCCESS} -ne 0 ]; then
   echo "Not a valid encrypted file"
   exit 1
fi

# Decrypt the file
openssl enc -d -aes-256-cbc -in ${ENCRYPTED_FILE} -out ${COMPRESSED_FILE} -pass file:${SYMMETRIC_KEY}

# Decompress the file
bunzip2 -f ${COMPRESSED_FILE} > /dev/null 2>&1

# If the file is being verified
if [ ! -z ${SENDER_CERTIFICATE} ]; then

   # Unpack the signature
   tar xf ${FILE} ${ENCRYPTED_SIGNATURE} > /dev/null 2>&1
   SUCCESS=$?
   add_on_exit rm -f ${ENCRYPTED_SIGNATURE}

   if [ ${SUCCESS} -ne 0 ]; then
      echo "File is not signed"
   else
      # Get the public key
      add_on_exit rm -f ${SENDER_PUBLIC_KEY}
      openssl x509 -in ${SENDER_CERTIFICATE} -pubkey -noout > ${SENDER_PUBLIC_KEY}

      # Decrypt the signature
      openssl enc -d -aes-256-cbc -in ${ENCRYPTED_SIGNATURE} -out ${SIGNATURE} -pass file:${SYMMETRIC_KEY}
      add_on_exit shred ${SIGNATURE}
      add_on_exit rm -f ${SIGNATURE}

      # Verify the signature
      openssl dgst -sha256 -verify ${SENDER_PUBLIC_KEY} -signature ${SIGNATURE} ${OUTPUT}
      add_on_exit rm -f ${SIGNATURE}
   fi
fi

echo "Decryption Successful"
