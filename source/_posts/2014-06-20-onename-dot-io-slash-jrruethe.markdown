---
layout: post
title: "onename.io/jrruethe"
date: 2014-06-20 21:58:58 -0400
comments: true
categories: 
---

Onename.io is a decentralized identity system that allows someone to:

 - Claim a unique, global username
 - Unify your online presence with one username and profile
 - Own your online identity & data
 - Store your profile in the blockchain
 - Allow anyone to easily look up your PGP public key
 - Share Bitcoin QR codes
 
It uses Namecoin under the hood. Namecoin is a key-value store that utilizes the blockchain as a decentralized database. All authorization is done via public key cryptography, so an individual is in 100% control of their data in the database.

I am a huge fan of decentralized systems, such as:

 - Bitcoin
 - Namecoin / Onename
 - Git
 - GPG
 
Onename.io gives me a way to link all this together into my own little decentralized profile:

{% img center ./01.png %}

Of course, each of those entities also have their own links, many pointing back at Onename.io for verification. So the web really looks more like this:

{% img center ./02.png %}

The following is proof that I am the owner of my [Onename.io](https://onename.io/jrruethe) account:

{% include_code lang:yaml verifymyonename.txt.asc %}
