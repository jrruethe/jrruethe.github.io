---
layout: post
title: "Hex to Mnemonics"
date: 2015-03-27 17:03:46 -0400
comments: true
categories: 
---

Hex values are the common representation for things like hashes, fingerprints, and uuids. They are great for machines,  but clumsy for humans. In this post, you will find two scripts used to convert a hex string to english words. This is useful for memorization or sharing by voice.

The first script comes straight from the Electrum Bitcoin wallet source code. I heard about this idea [here](http://www.reddit.com/r/Bitcoin/comments/2xggow/where_can_i_turn_my_random_phrase_into_a_12_word/). It is used to store the random seed that unlocks a deterministic Bitcoin wallet. Of course, it works nicely for any hex string as well.

{% include_code lang:python mnemonic.py %}

The script supports encoding and decoding. Run it like this:

    ./mnemonic.py a1b2c3d4
    shield doom swallow
        
    ./mnemonic.py shield doom swallow
    a1b2c3d4

The second script generates words using the official [PGP Wordlist](http://en.wikipedia.org/wiki/PGP_word_list) and all of its rules. This is commonly used to communicate a PGP key fingerprint over a voice channel, and is set up such that even bytes are two syllable words, while odd bytes are three syllable words. Again, this can be used for more than just PGP keys.

{% include_code lang:python pgp-words.py %}

This script only supports encoding. Typically, this method is used for verification purposes, as opposed to transferring data or memorization, as PGP key fingerprints are designed to be public. Both sides would generate the words from the fingerprint, then a voice channel is used to verify that the words match.

Run it like this:

    ./pgp-words.py a1b2c3d4
    ratchet
    pioneer
    snowcap
    souvenir
