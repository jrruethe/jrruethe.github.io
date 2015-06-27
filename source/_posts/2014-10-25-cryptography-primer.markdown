---
layout: post
title: "Cryptography Primer"
date: 2014-10-25 14:48:28 -0400
comments: true
categories: 
---

Digital cryptography is used everywhere on your computer, both online and offline, to keep your secrets safe.
This is a simplified explanation of how cryptography accomplishes this task.

The three fundamental building blocks to modern cryptography are:

 - Symmetric Encryption
 - Asymmetric Encryption
 - Hashes

## Symmetric Encryption
Symmetric encryption is the most intuitive form of encryption. The basic analogy is a lock and key. Keys are used together with an encryption algorithm to encrypt, or lock, a file. The resulting file is unreadable, and indistinguishable from random garbage data. 

{% img center ./01.png %}[^1]

A key is just a long string of bits. Passwords supplied by a user are either used as a key directly, or are used to derive a key. With symmetric encryption, the same key is used to both encrypt and decrypt a file.

> All data is represented in binary, a string of 0's and 1's. Data alone is meaningless without structure; it all depends on how you interpret it. For example, the number `65` in binary can be represented like this: `01000001`, but if you interpret that value using the ASCII system, it becomes the letter `A`. The text `Hi` is encoded in ASCII as `0100100001101001`. If it were interpreted as two 8 bit numbers, it would be `(72, 105)`. If it were interpreted as one large number, it would be `18537`. Entire files containing text can also be interpreted as one very large number.

An example of a symmetric encryption algorithm is AES: Advanced Encryption Standard. It is certified by the US government to secure secret documents. 

Here is how symmetric encryption is performed via the GPG program on Linux, using a password of 'ABC':

    echo This is a secret | gpg --cipher-algo AES256 --symmetric | base64
    
    jA0ECQMCjJkl5YwkaXFg0kQBjrmXBnt3sajSix4eihU/l+273UBtRabS7LFZ7Ln3R8ux0wzU
    bm9IZUuAunUNnF2RYG3HC2qa7bNtlefb/Hbp+xtYjw==

To decrypt, simply repeat the same command, but backwards, using the same password of 'ABC':

    echo jA0ECQMCjJkl5YwkaXFg0kQBjrmXBnt3sajSix4eihU/l+273UBtRabS7LFZ7Ln3R8ux0wzU\
    bm9IZUuAunUNnF2RYG3HC2qa7bNtlefb/Hbp+xtYjw== | base64 -d | gpg --cipher-algo AES256
    
    gpg: AES256 encrypted data
    gpg: encrypted with 1 passphrase
    This is a secret

Symmetric encryption algorithms are fast and secure, even with a relatively small key size (128 - 256 bits). For this reason, they play an important role in secure communications. Their downfall, however, is key distribution; they are prone to a man-in-the-middle attack unless the keys are distributed on a separate medium.

## Man in the Middle attacks

A man in the middle attack occurs when someone is intercepting your communication line by placing themselves in between you and the other person. This is different than just sniffing or eavesdropping, because an attacker is able to tamper with the communication line without either party knowing. For example, if Eve was performing a man in the middle attack on a conversation between Alice and Bob, Eve would be able to impersonate Bob from Alice's point of view, and impersonate Alice from Bob's point of view. Neither Alice nor Bob would be aware that they are talking to Eve instead of the other person. Eve can effectively lie to both parties.

{% img center ./02.png %}[^2]

To combat this attack, encryption can be used. If Alice and Bob had the same key, they could communicate securely by encrypting their messages before sending them to the other, and decrypting them upon receipt. This prevents Eve from reading the actual message. However, in order to communicate, they need to have the same key. Either Alice or Bob can generate the key, but the difficulty is transferring the key to the other without Eve intercepting it. The only secure solution is for them to pre-share the key across some other medium, such as a phone call or in person. This exchange is cumbersome, as it must be done before each session. In addition, the key cannot be reused across different sessions; If Eve were to ever obtain the key to a single session, she could also infiltrate all the other sessions, including recordings of past sessions.

## Asymmetric Encryption

Asymmetric encryption is different from symmetric encryption in that it utilizes two keys; one key performs the encryption while the other performs the decryption. The key that performs the encryption cannot be used to perform the decryption; the paired key must be used. It is important to note that either key can perform the encryption step, and the other key will undo it.

This behavior has some very useful implications. One of the keys can be selected to be the `private` key, which must be kept secure such that no one else knows it. The remaining key will become the `public` key, which can be posted online, sent to others, etc. This method is known as `public key cryptography`, and it solves the key distribution problem encountered with symmetric encryption.

Alice will generate a key-pair and keep the private key to herself, while sending her public key to Bob. Likewise, Bob will generate his key-pair and send his public key to Alice while keeping his private key to himself. When Alice wants to talk to Bob, she can use Bob's public key to perform the encryption. Only Bob will be able to decrypt the message, since he is the only one who has the private key. Bob can then respond to Alice by using her public key to encrypt his response.

{% img center ./03.png %}[^3]

Asymmetric encryption algorithms, such as RSA, are slow and require much larger keys to achieve the same security that AES provides (2048 - 4096 bits). This means that using asymmetric encryption for an entire conversation is inefficient. For this reason, a hybrid approach is used. A user will generate a random symmetric key intended for one time use, called a session key, and encrypt it using the public asymmetric key of the recipient. The receiver will use their private asymmetric key to obtain the symmetric session key. Now that both users have the same symmetric key, they can use symmetric encryption to communicate.

But how does Bob know that the key actually came from Alice? What if Eve was the one who actually sent him the session key? After all, Bob's public key is public; anyone can use it. We need to introduce the 3rd fundamental technology first.

## Hashes

Unlike the other two, a hash is not an encryption method. Hashes are also known as message digests or fingerprints. They are one-way functions, meaning that they cannot be reversed or undone; given the output, it is impossible to derive the input.

Any two messages that contain the exact same data will produce the exact same hash, or fingerprint. Similarly, if even a single bit is different, the hash will be completely different. Hash algorithms employ an avalanche technique such that a small change to the input produces a large change in the output. Finally, hash algorithms always produce the same size output regardless of the size of the input.

{% img center ./04.png %}[^4]

Here are some examples, using the SHA-256 algorithm (Secure Hash Algorithm):

    echo This is a message | sha256sum

    6afa89a2ed3ff1f33150c8c897c3c49775b4fb91fa923b790533a0f26c956a88
    
    # Notice that a single letter difference completely changes the output
    echo This is b message | sha256sum
    
    0c9bf9d4f05d174783676acbdd50ffde59bffa5f17eaf0557500c3070678ff5b
    
Hashes are very useful. They are often used as checksums to ensure that a message was transferred without getting corrupted. For example, a website offering a download may also list its hash. After the user downloads the file, they can recalculate the hash. If their result matches the website's listing, they can be assured that they have the exact same file that the website served; there was no corruption during the download.

Hashes are also used to hide passwords. When you sign up for a website and enter a password, the website will take the hash of your password and store the hash. Later on when you want to log in, you enter your password again. The website takes the hash again and compares it to their stored hash. If the two hashes match, you are allowed to log in. If the website gets hacked and their database of hashes is retrieved, the attacker cannot get your password (because hashes cannot be reversed).

It is important to choose a strong password, however. Attackers can still attempt to retrieve your password by performing a dictionary attack. An attacker will take a large dictionary of words and calculate their hashes. They then compare their list of hashes to the list of hashes retrieved from the website. If they find a match, they can look back at their input list to determine which word produced the hash. This is a brute force method for obtaining your password. It is important to see that it isn't that the hash was reversed, rather that multiple inputs were tried until the desired output was found. There are protections against this type of attack, such as salting, but that is out of the scope of this primer.

## Digital Signatures

Now, back to our previous question; How can Bob be assured that a message came from Alice? Because of the way asymmetric encryption works, Alice can also encrypt a message using her own private key. The resulting cyphertext can be decrypted by anyone, since the corresponding public key is publicly available. However, the cyphertext could only have been created by Alice, because she is the only one who has the private key. This is called a digital signature; Alice *signs* a message by encrypting it with her private key.

{% img center ./05.png %}[^5]

Because asymmetric encryption keys are so large (which causes the resulting cyphertext to be large), it is not practical to encrypt an entire message, especially if that message is large. Instead, the hash of the message is encrypted, and the message itself is sent in plaintext (unencrypted). Anyone can read the message and compute it's hash. Then, they use Alice's public key to decrypt the signature connected to the message to obtain the hash that Alice encrypted. If the two hashes match, then the message was not tampered with, and the user can be certain that the message originated from Alice.

## Secure Communication
Putting these concepts together, here is how secure communication can be established:

Alice and Bob each generate asymmetric key pairs. They take a hash of their public key and encrypt it with their private key. They then attach the result to the public key itself. This is called self-signing their public key.

Alice and Bob share their public keys with each other. One of them generates a random session key and encrypts it with their private key. They take the result and encrypt it with the public key of the recipient.

The receiver uses their private key to decrypt the message, and use the sender's public key to decrypt the result to obtain the random session key. The sender is assured that only the intended receiver is able to obtain the key, and the receiver is assured that only the expected sender could have sent it. From here, they can establish a secure channel using symmetric encryption with the session key. Any eavesdropper on the exchange would not be able to gain access to the session key, and thus could not listen in on the secure channel.

{% img center ./06.png %}[^6]

However, there is still one thing missing which makes this communication vulnerable to a man in the middle attack. If Eve is able to tamper with the initial handshake, where the public keys are exchanged, she could pass fake public keys to each side. Alice would think that she received Bob's public key, when in fact she received Eve's public key. Her entire communication would be with Eve directly, who is impersonating Bob, but is also passing the messages to Bob after reading them. Neither is aware that this is happening.

In other words, you can securely communicate with someone and be assured that no one else can eavesdrop, but you cannot be certain about who you are actually communicating with.

The signatures on the keys don't give any additional information on their own; they only claim that the holder of the private key trusts the public key. The missing piece to the security is linking an identity to the public key, so you know which key belongs to who. Once you can trust that you are securely communicating with the correct person, you win!

## Digital Certificates

A digital certificate is an identity linked to a public key, and signed by someone trustworthy. An identity in this case can be something as simple as a name or email address, or it can be as complicated as a photo of a license / passport or fingerprints. It is a means of uniquely identifying and verifying an individual or organization.

A digital certificate links an identity to a public key. Certificates can be signed with many different signatures, as well as a self-signature (the owner of the public key). Certificates play an important role in creating a network of trust. Remember, anyone can create an identity and public key, and they can sign their own certificate. This means that while the link between the public key and identity is real, the identity itself could be fabricated. Trust in a certificate is established by obtaining signatures from trustworthy entities.

{% img center ./07.png %}[^7]

There are currently two models for establishing trust in digital certificates. One of them is a hierarchial centralized method which uses a `root certificate authority` that must be completely trusted, while the other is a decentralized `web of trust` that gives each person full control of their trust.

## Root Certificate Authority
This is a centralized system that focuses completely around the root authority. The root authority is responsible for performing background checks to verify an identity, and signs off on the certificate if the identity is legitimate. Root authorities can sign the certificates of sub-authorities, which in turn are granted the same responsibilities and signing powers. Anyone can request that an authority sign their certificate, which usually involves payment of a fee, to grant the trust of the root authority to their certificate.

If you can find a chain of signatures from a certificate back to the root authority, and you trust the root authority, then you can trust the certificate. This trust model is all or nothing, meaning that as long as the root authority is trusted, every chain originating at the root authority is trusted regardless of the number of links.

{% img center ./08.png %}[^8]

Most of the internet works using this model. Your web browser comes with preinstalled certificates for the major root authorities, which sign the certificates of all the websites you interact with. There are flaws with this model, however. Security is a "weakest link" type of problem; A chain ending at the root authority doesn't mean that the entire chain is solid. It could be that a sub-authority does not properly perform its background checks, resulting in that sub-authority being the weakest link. If that sub-authority signs a fabricated certificate, there is no way for you to know not to trust it. The owner of the certificate could masquerade as their false identity and impersonate a target.

In addition to this, well funded organizations such as the NSA can take control of a root authority and sign whichever certificates they want, essentially breaking the entire model.

## Web of Trust
To avoid the single point of failure present in the centralized hierarchial model, a different model known as the `web of trust` was created. This model is decentralized and gives the control back to the individuals. The web of trust involves each person performing their own level of identity checking before signing off on a certificate. In effect, they become their own root authority for themselves. If you are able to verify an identity one time and sign off on it, you can trust that identity from that point forward. This method involves more manual work, making it a little less convenient. It is also more probabilistic than the black/white hierarchial model, in that trust is measured in the quantity of signatures rather then the presence of a single signature. The upside is that the only single point of failure is yourself, as you get to define the trust levels of each certificate you interact with.

{% img center ./09.png %}[^9]

In the web of trust model, you are responsible for verifying that the identity of the certificate matches the identity of the certificate holder. This is typically done in person or over some other medium besides the one being used with the certificate (such as the phone). You would ask the person to present their certificate as well as some reputable identification, such as a passport or drivers license, and sign the certificate if the identities match. Chains are formed transitively by signing a certificate when someone has signed your own certificate. 

For example, if Alice signs Bob's certificate, and Bob sign's Carol's certificate, then Alice can reasonably trust that Carol's certificate is authentic. Even though she hasn't necessarily met Carol, Alice trusts that Bob performed the necessary identity checks. Alice's trust in Carol can be increased if there are other chains that link the two together. If Alice also signed Dave's certificate, and Dave also signed Carol's certificate, then Carol has two signatures from people that Alice trusts, further increasing the odds that Carol really is who she says she is (from Alice's point of view). 

It is important to note that it isn't the number of signatures that determines trust, it is the number of chains. For example, Eve can create 100 fake identities and have them all sign her certificate, but that doesn't mean that Eve can be trusted.

In this model, each additional link degrades trust; A certificate 2 steps away can typically be trusted more than a certificate 5 steps away. If everyone is creating chains from themselves to everyone else, a web of trust is formed, hence the name. 

## Trust

Secure communication is possible if you can establish trust in the other person's identity. How does one go about establishing this trust? I will cover this in a future post.

[^1]: https://msdn.microsoft.com/en-us/library/ff647097.aspx 
[^2]: http://www.cs.ucla.edu/classes/winter13/cs111/scribe/17b/ (http://fearlessweb.trendmicro.com/2012/tips-and-tricks/what-are-man-in-the-middle-attacks-and-how-can-i-protect-myself-from-them/)
[^3]: https://msdn.microsoft.com/en-us/library/ff647097.aspx
[^4]: http://computersecuritypsh.wikia.com/wiki/File:Hash_Function.png
[^5]: http://oz.stern.nyu.edu/fall99/readings/security/
[^6]: http://www.embedded.com/design/safety-and-security/4230829/2/Securing-your-apps-with-Public-Key-Cryptography---Digital-Signature
[^7]: https://commons.wikimedia.org/wiki/File:Digital_Signature_diagram.svg
[^8]: http://www.hill2dot0.com/wiki/index.php?title=Image:G1662_CA-Hierarchies-and-Cr.jpg
[^9]: http://books.gigatux.nl/mirror/securitytools/ddu/ch09lev1sec1.html