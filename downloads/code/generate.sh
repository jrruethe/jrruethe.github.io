#!/bin/bash

# generate.sh
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

# Generates a certificate and private key
# generate.sh <"name"> [email]
# 1) (Required) Name of user
# 2) (Optional) Email of user

# Stop on any error
set -e

if [ "$#" -lt 1 ]; then
   echo "Usage: generate.sh <\"name\"> [email]"
   exit 1
fi

NAME=$1
EMAIL=$2

# Replace spaces with underscores
FILE=${NAME// /_}
KEY=${FILE}.secret
CERTIFICATE=${FILE}.certificate

# Create a certificate and key pair for the given name and email
echo -e "NA\nNA\nNA\nNA\nNA\n${NAME}\n${EMAIL}" | openssl req -new -x509 -sha256 -newkey rsa:2048 -nodes -keyout ${KEY} -out ${CERTIFICATE}  > /dev/null 2>&1	

# Change permissions
chmod 400 ${KEY}
chmod 444 ${CERTIFICATE}

