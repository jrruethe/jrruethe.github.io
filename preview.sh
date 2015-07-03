#!/bin/bash
# Preview the blog at 127.0.0.1:4000

# Disable preview mode
rm -f .preview-mode

rake _0.9.2.2_ generate
rake _0.9.2.2_ preview

