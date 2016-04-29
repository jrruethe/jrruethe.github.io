---
layout: post
title: "Blockchain Identity"
date: 2015-02-28 15:24:25 -0500
comments: true
toc: true
categories: 
 - Bitcoin
 - Identity
---

I stumbled upon Christopher Ellis' ["World Citizenship" Blockchain ID](https://github.com/MrChrisJ/World-Citizenship) concept and was immediately intrigued. 
His idea is to create proof of an individual's existence by storing their PGP identity in the blockchain.

The trick is that the blockchain acts as an immutable database that includes full history tracking, meaning that a record can be proven to exist in some state at some time. These services are similar to this concept:

 - [Proof of Existence](http://www.proofofexistence.com/about)
 - [Cryptograffiti](http://www.cryptograffiti.info/)
 - [BTProof](https://www.btproof.com/)

This post will detail how to create a Blockchain Identity. 

{% more %}

# Requirements

To begin, you will need:

 - GPG key with signing abilities
 - Bitcoin wallet with a small balance
 - Keybase.io account

Keybase.io is currently alpha, and you need an invite to get an account, but you can probably snag an invite from Reddit (that's where I got mine).

I will be using Debian Linux for this tutorial. I recommend the following packages:

 - gpg : For signing files
 - electrum : For managing bitcoins
 - ruby : For running the scripts below

First you need to create a GPG key and an Electrum Bitcoin wallet. I won't dive into the details of how to create these in this post. The reason we are using Electrum is because it has the ability to choose the address to send funds from, unlike some other wallets. We will need to know this sending address later. 

You also need to get a small amount of Bitcoin into your Electrum wallet (at least 0.0003 BTC)

# Gathering the Data

Time to collect the data. Open up a text editor and create a Yaml file named key.yml

First, lets get the GPG key details. Run the following, substituting your UID:

    gpg --fingerprint jrruethe
    pub   4096R/40B935FE 2014-06-14 [expires: 2015-06-14]
          Key fingerprint = 4F40 99F8 276B DBA5 475A  8446 4630 BEDC 40B9 35FE
    uid                  Joseph Ruether <jrruethe@gmail.com>
    
Fill out your key.yml file like so:

    Name: Joseph Ruether
    Email: jrruethe@gmail.com
    Type: RSA
    Size: 4096
    Created: 2014-06-14
    Fingerprint: 4F40 99F8 276B DBA5 475A 8446 4630 BEDC 40B9 35FE

Next, go to your Electrum wallet and pick an address that contains a small amount of funds. You will need at least 0.0003 BTC. Add this address to your yaml file:

    Address: 1LXWthRW8aqQSBddifWxwTDGPycT6Lom2Q
    
Go to [Blockchain.info](https://blockchain.info) and find the latest block that has been added to the main chain. Add the block number and Merkle Root to your yaml file:

    Block: 345546
    Merkle Root: ea31869aa04e3608450b45068b257ee396a6d2f6724f96593cd8d2c7f30a39d9
    
At this point, your yaml file has all of your GPG key metadata, the address you will use to store the data in the blockchain, and a random number that proves this entry could not have been created earlier in time.

# Preparing the Data

Now we need to put this data into a standard, machine readable format and sign it. First, use the following script to convert your yaml file into a normalized json file:

{% include_code lang:ruby yaml-to-normalized-json.rb %}

Run it like so:

    ./yaml-to-normalized-json.rb key.yml > key.json
    
Then use GPG to clearsign this file:

    gpg --clearsign key.json

The result should look something like this:

{% include_code lang:yaml key.json.asc %}

# Sending the Data to the Blockchain

Now that we have our signed data file, we want to send it to the blockchain. It is important to note that the blockchain will only contain the sha256 hash of your key.json.asc, therefore you need to keep the original data around for validation. Later on, we will create an identification card with a QR code containing the original data.

There is a clever trick we are going to use. If you look at the [Technical Background of Bitcoin Addresses](https://en.bitcoin.it/wiki/Technical_background_of_Bitcoin_addresses), you will see that the address is generated from the hash of the public key. We can replace that hash (at step 3) with the hash of our file before continuing to generate the address. By sending Bitcoins to the address we create, we store the file's hash in the blockchain. Of course, those coins will be lost forever, because the private key for that address does not exist. That is why we only send a small amount.

Now, use the following script to obtain the Bitcoin address that is associated with the hash of your signed key.json:

{% include_code lang:ruby file-to-address.rb %}

Run it like this:

    ./file-to-address.rb key.json.asc
    1BESV3iP1x1HAMDGhsYiQE3do6aiywGZ3K

For some basic sanity checks, visit this website: [Base58 Decoder](http://lenschulwitz.com/base58)  
Here you can validate that the Bitcoin address is legitimate, as well as decode the address to hex. Here is what I get:

    00703BF01D7DF0A110C9B2CE1E8984F545831BFFAA5556057E
    
Next, get the sha256 hash of key.json.asc:

    sha256sum key.json.asc 
    703bf01d7df0a110c9b2ce1e8984f545831bffaa08042e78b470b3b1464faada  key.json.asc
    
Compare the two outputs to make sure they match:

    00 703BF01D7DF0A110C9B2CE1E8984F545831BFFAA 5556057E
       703bf01d7df0a110c9b2ce1e8984f545831bffaa 08042e78b470b3b1464faada

All that is left to do is send some bitcoin to that address. Use [Blockchain.info](https://blockchain.info/) to capture the transaction details as proof of the file's existence:

[Transaction: 68cbd46b5b1b5ac4ce3369c04a0366da733182b6a7b329317aa1c87feb46f96d](https://blockchain.info/tx/68cbd46b5b1b5ac4ce3369c04a0366da733182b6a7b329317aa1c87feb46f96d)
