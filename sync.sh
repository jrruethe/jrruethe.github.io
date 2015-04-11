#!/bin/bash
# Deploy Blog
# Make sure all posts have been added to git and committed first!

set -e

# Make sure master is synced
git checkout master
git pull
git push origin master

# Make sure source is synced
git checkout source
git pull
git push origin source

# Make sure deployment is synced
cd _deploy/
git pull
cd -

