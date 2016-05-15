#!/bin/bash
# Deploy Blog
# Make sure all posts have been added to git and committed first!

set -e

PATH=/home/user/Downloads/bin:$PATH

# Disable preview mode
rm -f .preview-mode

# Load Twitter Credentials
if [ -e twitter_credentials.sh ]; then
    . twitter_credentials.sh
fi

# Deploy
rake generate
rake deploy

# Resync to prevent problems later
./sync.sh
