#!/bin/bash

# encrypt.sh
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

# Encrypts a file
# encrypt.sh <file> <recipient_certificate> [sender_private_key] [sender_certificate]
# 1) (Required) File to encrypt
# 2) (Required) Certificate of the recipient
# 3) (Optional) Private key of the sender
# 4) (Optional) Certificate of the sender

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
   echo "Usage: encrypt.sh <file> <recipient_certificate> [sender_private_key] [sender_certificate]"
   exit 1
fi

FILE=$1
RECIPIENT_CERTIFICATE=$2
SIGNING_KEY=$3
SENDER_CERTIFICATE=$4

COMPRESSED_FILE=${FILE}.bz2
ENCRYPTED_FILE=${COMPRESSED_FILE}.encrypted
SYMMETRIC_KEY=symmetric_key.bin
ENCRYPTED_KEY=${SYMMETRIC_KEY}.encrypted

RECIPIENT_PUBLIC_KEY=${RECIPIENT_CERTIFICATE//certificate/public}
RECIPIENT_METADATA=recipient.txt
SENDER_METADATA=sender.txt

SIGNATURE=${FILE}.signature
ENCRYPTED_SIGNATURE=${SIGNATURE}.encrypted
OUTPUT=${FILE}.tar

# Get the public key from the certificate
openssl x509 -in ${RECIPIENT_CERTIFICATE} -pubkey -noout > ${RECIPIENT_PUBLIC_KEY} 2>/dev/null
SUCCESS=$?
add_on_exit rm -f ${RECIPIENT_PUBLIC_KEY}

if [ ${SUCCESS} -ne 0 ]; then
   echo "Invalid recipient certificate"
   exit 1
fi

# Get the recipient fingerprint metadata
openssl x509 -in ${RECIPIENT_CERTIFICATE} -noout -fingerprint | awk -F "=" '{print $2}' > ${RECIPIENT_METADATA}
add_on_exit rm -f ${RECIPIENT_METADATA}

# Compress the file
bzip2 -9 -k ${FILE}
add_on_exit rm -f ${COMPRESSED_FILE}

# Generate a random key
openssl rand -base64 128 -out ${SYMMETRIC_KEY}
add_on_exit shred ${SYMMETRIC_KEY}
add_on_exit rm -f ${SYMMETRIC_KEY}

# Encrypt the file symmetrically using the random key
openssl enc -aes-256-cbc -salt -in ${COMPRESSED_FILE} -out ${ENCRYPTED_FILE} -pass file:${SYMMETRIC_KEY}
add_on_exit rm -f ${ENCRYPTED_FILE}

# Encrypt the symmetric key with the public key of the recipient
openssl rsautl -encrypt -inkey ${RECIPIENT_PUBLIC_KEY} -pubin -in ${SYMMETRIC_KEY} -out ${ENCRYPTED_KEY}
add_on_exit rm -f ${ENCRYPTED_KEY}

# If the file is being signed by the sender
if [ ! -z ${SIGNING_KEY} ]; then

   # Sign the file
   openssl dgst -sha256 -sign ${SIGNING_KEY} -out ${SIGNATURE} ${FILE} > /dev/null 2>&1
   SUCCESS=$?
   add_on_exit shred ${SIGNATURE}
   add_on_exit rm -f ${SIGNATURE}
   
   if [ ${SUCCESS} -ne 0 ]; then
      echo "Invalid sender private key"
      exit 1
   fi
   
   # Encrypt the signature symmetrically using the random key
   openssl enc -aes-256-cbc -salt -in ${SIGNATURE} -out ${ENCRYPTED_SIGNATURE} -pass file:${SYMMETRIC_KEY}
   add_on_exit rm -f ${ENCRYPTED_SIGNATURE}
   
else
   # Clear the variables for the tar command
   ENCRYPTED_SIGNATURE=
fi

# If a sender is being specified
if [ ! -z ${SENDER_CERTIFICATE} ]; then

   # Get the sender fingerprint metadata
   openssl x509 -in ${SENDER_CERTIFICATE} -noout -fingerprint 2>/dev/null | awk -F "=" '{print $2}' > ${SENDER_METADATA}
   SUCCESS=${PIPESTATUS[0]}
   add_on_exit rm -f ${SENDER_METADATA}
      
   if [ ${SUCCESS} -ne 0 ]; then
      echo "Invalid sender certificate"
      exit 1
   fi

else
   # Clear the variable for the tar command
   SENDER_METADATA=
fi

# Bundle the output files together
tar cf ${OUTPUT} ${ENCRYPTED_FILE} ${ENCRYPTED_KEY} ${RECIPIENT_METADATA} ${ENCRYPTED_SIGNATURE} ${SENDER_METADATA}

echo "Encryption Successful"
