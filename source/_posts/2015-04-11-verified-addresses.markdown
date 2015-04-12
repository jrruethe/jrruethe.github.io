---
layout: post
title: "Verified Addresses"
date: 2015-04-11 18:48:27 -0400
comments: true
categories: 
---

This is a curated list of important websites and services with verified certificates and onion addresses:

{% include_code lang:yaml verified_addresses.txt.asc %}

To extract all the GPG keys and import them:

    for i in `egrep -o '([0-F]{4} ){5} ([0-F]{4} ){4}[0-F]{4}' verified_addresses.txt.asc | tr -d ' '`;  
    do
       gpg --keyserver pool.sks-keyservers.net --recv-keys $i;

       # Sleep needed to prevent spamming the server, it will respond with "connection refused" otherwise       
       sleep 30;
    done;