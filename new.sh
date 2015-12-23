#!/bin/bash
# Create a new blog post

PATH=/home/user/Downloads/bin:$PATH

rake new_post["$(echo $@)"]

