#!/bin/bash
# Preview the blog at 127.0.0.1:4000

PATH=/home/user/Downloads/bin:$PATH

# Reset preview mode
rm -f .preview-mode
export OCTOPRESS_ENV='preview'

rake generate
rake preview

