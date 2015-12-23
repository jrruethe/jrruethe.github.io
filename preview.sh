#!/bin/bash
# Preview the blog at 127.0.0.1:4000

PATH=/home/user/Downloads/bin:$PATH

# Disable preview mode
rm -f .preview-mode

rake generate
rake preview

