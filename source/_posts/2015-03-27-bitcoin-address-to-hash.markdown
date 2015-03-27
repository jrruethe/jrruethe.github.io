---
layout: post
title: "Bitcoin Address to Hash"
date: 2015-03-27 13:40:20 -0400
comments: true
categories: 
---

In the [previous post](http://jrruethe.github.io/blog/2015/02/28/blockchain-identity/), I walked through how to store a hash in the Bitcoin blockchain, by converting the hash to a valid Bitcoin address and sending a small amount of bitcoin to it. I neglected to include a script that goes the other way.

Below is a script that will take a valid Bitcoin address and convert it back to the hash it came from. This can be used to validate Blockchain Identities.

{% include_code lang:ruby address-to-hash.rb %}

Grab the sending address from the [transaction](https://blockchain.info/tx/68cbd46b5b1b5ac4ce3369c04a0366da733182b6a7b329317aa1c87feb46f96d):

    1BESV3iP1x1HAMDGhsYiQE3do6aiywGZ3K
    
Run the script using this address:

    ./address-to-hash.rb 1BESV3iP1x1HAMDGhsYiQE3do6aiywGZ3K 
    703bf01d7df0a110c9b2ce1e8984f545831bffaa
    
As you can see, the resulting hash matches the sha256 hash of key.json.asc generated in the previous post.