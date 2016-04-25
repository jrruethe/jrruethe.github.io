---
layout: post
title: "Generate Hashes"
date: 2015-04-19 14:51:57 -0400
comments: true
categories: 
 - Scripts
 - Cryptography
---

This is a handy script to recursively generate hashes for a folder tree, in a format that the standard unix tools can use for checking. 

{% more %}

{% include_code lang:bash generate_hashes.sh %}

The following will show how to use it. First, we need some files:

    $ ls
    generate_hashes.sh
    
    $ dd if=/dev/urandom bs=1024k count=1 > 1.txt
    1+0 records in
    1+0 records out
    1048576 bytes (1.0 MB) copied, 0.0787343 s, 13.3 MB/s
    
    $ dd if=/dev/urandom bs=1024k count=1 > 2.txt
    1+0 records in
    1+0 records out
    1048576 bytes (1.0 MB) copied, 0.0862146 s, 12.2 MB/s
    
    $ mkdir -p three/four
    
    $ dd if=/dev/urandom bs=1024k count=1 > three/3.txt
    1+0 records in
    1+0 records out
    1048576 bytes (1.0 MB) copied, 0.0854334 s, 12.3 MB/s
    
    $ dd if=/dev/urandom bs=1024k count=1 > three/four/4.txt
    1+0 records in
    1+0 records out
    1048576 bytes (1.0 MB) copied, 0.0783046 s, 13.4 MB/s
    
    $ ls *
    1.txt  2.txt  generate_hashes.sh
    
    three:
    3.txt  four
    
Calling the script without any arguments will generate the hashes in the current directory. The file is stored as hashes.hashtype, where hashtype defaults to sha256.
    
    $ ./generate_hashes.sh 
    $ ls
    1.txt  2.txt  generate_hashes.sh  hashes.sha256  three
    
    $ cat hashes.sha256 
    3f27f253e357143105f9a29193141db5ad833b56299a4c4e4a30a2d19f4732a8 1.txt
    9dee9ed8f2c7a8533e764bc6963615537524d54292875e9fd858e9e0cd9b93b1 2.txt
    20a1cbbf5a21773d673c79d4d8e58e31c3766f87c0299aa5a8c669015504c9f0 generate_hashes.sh
    a43be65323f68fc6354f34f8fc97efeb28f01b256d9918cecf9981a93eb59aca three/3.txt
    bc767948f782a92ebae7d217e04a160c74669dac838b2ccc33cc697e3ebd1ea2 three/four/4.txt
    
    $ sha256sum -c hashes.sha256 
    1.txt: OK
    2.txt: OK
    generate_hashes.sh: OK
    three/3.txt: OK
    three/four/4.txt: OK
    
The first optional argument is the directory to hash. `.` is allowed.
    
    $ rm hashes.sha256
    $ ls
    1.txt  2.txt  generate_hashes.sh  three
    $ ls three/
    3.txt  four
    
    $ ./generate_hashes.sh three/
    $ ls three/
    3.txt  four  hashes.sha256
    $ cat three/hashes.sha256 
    a43be65323f68fc6354f34f8fc97efeb28f01b256d9918cecf9981a93eb59aca 3.txt
    bc767948f782a92ebae7d217e04a160c74669dac838b2ccc33cc697e3ebd1ea2 four/4.txt
    
The second optional argument is the hash type to use:

 - sha1
 - sha224
 - sha256 (default)
 - sha384
 - sha512
 - md5
    
Example:
    
    $ ./generate_hashes.sh three/ sha1
    $ ls three/
    3.txt  four  hashes.sha1  hashes.sha256
    $ cat three/hashes.sha1
    fffdc438939ae0afa1f19569939dd3996a2d67bb 3.txt
    cec823c326525c23bba925d5d85b35a5ebbed62d four/4.txt
    deea8794a7aada412518d06df516c804389ef212 hashes.sha256
    
    $ cd three/
    $ sha1sum -c hashes.sha1
    3.txt: OK
    four/4.txt: OK
    hashes.sha256: OK

When distributing a large set of files or directory tree, it is best to generate the hashes in the root of the tree and sign the hashes.sha256 file with GPG.
