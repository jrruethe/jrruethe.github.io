#!/bin/bash
# Create a new blog post

rake _0.9.2.2_ new_post["$(echo $@)"]

