#!/bin/sh

sudo apt-get install ruby bundler git ruby-gsl
sudo gem install rake --version 0.9.2.2
bundle install

rake _0.9.2.2_ setup_github_pages

cd _deploy/
git pull origin master
git add index.html
git commit -m 'Deployment'

