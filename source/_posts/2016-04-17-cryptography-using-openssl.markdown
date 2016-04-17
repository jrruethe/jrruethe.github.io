---
layout: post
title: "Cryptography using OpenSSL"
date: 2016-04-17 13:21:05 -0400
comments: true
categories: 
---

PGP and GPG are commonly used to encrypt and sign messages for specified recipients, but OpenSSL is capable of performing the same cryptographic operations. The benefit is that more of the magic is exposed to the user, which can be useful for learning more about how cryptographic applications operate.

Below are three bash scripts that can perform the following:

 - Public / private key generation
 - Hybrid asymmetric encryption and signing
 - Hybrid asymmetric decryption and verification
 
These operations are a subset of the core functionality provided by GPG, and can be used to securely pass sensitive data between users. Unlike GPG, the user is responsible for managing trusted certificates.

## Generate

The first script is called `generate.sh`. It will generate a new public certificate and private key when given a name and optional email address. Run it like so:

    $ ./generate.sh 
    Usage: generate.sh <"name"> [email]
    
    $ ./generate.sh "Joe Ruether" jrruethe@gmail.com

{% img center ./01.png %}

As you can see, a certificate and private key were generated, with the proper permissions set. Both files are stored in base64 ASCII for easily sharing or backing them up.

You can also view the human readable output of the certificate with:

    openssl x509 -in Joe_Ruether.certificate -text -noout

{% img center ./02.png %}

The idea here is that two users would generate their own certificates and private keys, then keep the private keys for themselves while sharing the certificates with each other. The sharing of certificates should be done in a way that you can prove the certificate belongs to who you think it does, since anyone can generate a certificate with any name and email.

The script:

{% include_code lang:bash generate.sh %}

## Encrypt

The next script performs file encryption to a specified recipient certificate. It can optionally sign the file with your private key. The order of operations is as follows:

 1. The file is first compressed
 2. A random keyfile is generated
 3. The compressed file is symmetrically encrypted with the random keyfile using AES256
 4. The random key is asymmetrically encrypted with the certificate using RSA
 5. (optional) The file is signed using the private key of the sender, and the signature is encrypted symmetrically using the random key
 6. All output files are bundled together into a tarball

Run it like so:

    $ echo "This is a test" > test.txt
    $ ./encrypt.sh 
    Usage: encrypt.sh <file> <recipient_certificate> [sender_private_key] [sender_certificate]
    
    $ ./encrypt.sh test.txt Alice.certificate
    Encryption Successful

Optionally the file can be signed by also providing your private key:

    $ ./encrypt.sh test.txt Alice.certificate Bob.secret
    Encryption Successful

In this case, the file `test.txt` was encrypted to Alice and signed by Bob.

Here is the output:

{% img center ./03.png %}
{% img center ./04.png %}

The produced tarball can be safely shared over an insecure channel; only the intended recipient is able to decrypt it.

The tarball will always contain the recipient metadata extracted from the recipient's public certificate. This is so it is easy to identify who is able to decrypt the file. Optionally, the sender can include their certificate metadata when signing a file, to make it easy to determine which certificate is needed to verify the signature. The metadata files contain nothing more than the sha1 fingerprints of the respective certificates:

{% img center ./05.png %}

The script:

{% include_code lang:bash encrypt.sh %}

## Decrypt

The final script is intended to decrypt bundles created by the above encryption script. It will:

 1. Extract the encrypted symmetric key
 2. Decrypt the symmetric key using the given secret key
 3. Extract the encrypted compressed file
 4. Use the decrypted symmetric key to decrypt the compressed file
 5. Decompress the file
 6. (optional) Extract and verify the signature using the supplied certificate

Run it like so:

    $ ./decrypt.sh 
    Usage: decrypt.sh <file> <recipient_private_key> [sender_certificate]
    
    $ ./decrypt.sh test.txt.tar Alice.secret Bob.certificate 
    Verified OK
    Decryption Successful

In this case, the file was decrypted by Alice, and verified to be sent by Bob.

Here is the output:

{% img center ./06.png %}

The script:

{% include_code lang:bash decrypt.sh %}
