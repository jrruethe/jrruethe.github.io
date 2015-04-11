#!/bin/sh

sudo apt-get install ruby bundler git ruby-gsl
sudo gem install rake --version 0.9.2.2
bundle install
