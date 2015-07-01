#!/bin/bash
# Deploy Blog
# Make sure all posts have been added to git and committed first!

set -e

# Disable preview mode
rm -f .preview-mode

# Deploy
rake _0.9.2.2_ generate
rake _0.9.2.2_ deploy

# Resync to prevent problems later
./sync.sh
