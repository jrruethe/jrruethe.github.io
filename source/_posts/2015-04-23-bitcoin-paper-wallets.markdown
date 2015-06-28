---
published: true
layout: post
title: "Bitcoin Paper Wallets"
date: 2015-04-23 19:18:12 -0400
comments: true
categories: 
---

Paper wallets are a form of *cold storage*, meaning that the private key has never touched a computer with internet access. This is one of the most secure ways to store Bitcoins when done properly. You should never use a paper wallet you did not create yourself. For that reason, this is a tutorial to create a paper wallet in a secure fashion.

A repository of paper wallet generators can be found [here](https://github.com/jrruethe/paper_wallet). You can choose to use my repository directly if you wish, but I recommend going straight to the source.
There are many options with different formats and templates, however I highly recommend bitcoinpaperwallet.com.

*I am in no way affiliated with bitcoinpaperwallet.com, just a satisfied customer.*

---
### [BitcoinPaperWallet.com](https://bitcoinpaperwallet.com/) ([Github](https://github.com/cantonbecker/bitcoinpaperwallet))

{% img center ./01.jpg %}

This is the most secure and well thought out design I have seen. The author has done a great job addressing the various attack vectors. His website is easy to use and provides all the relevant information needed. Furthermore, the generator is based on the popular and trusted [bitaddress.org](https://www.bitaddress.org). This paper wallet is perfect for cold storage and archival, but it takes a little extra work and materials to secure it properly. Fortunately, everything required can be bought right from the website, and you can pay in Bitcoin!

Features:

 - "Butterfly" design secures the private key
 - Resistant to candling
 - Supports [BIP38](https://github.com/bitcoin/bips/blob/master/bip-0038.mediawiki) encryption
 - Private key encoded in [Wallet Import Format](https://en.bitcoin.it/wiki/Wallet_import_format)
 - Designed to be printed in landscape mode, but works in portrait mode as well
 - Double sided
 - 2x wallets per sheet
 - Notes section on the back
 - Public key visible when closed

Additional Options:

 - [Security Stickers](https://bitcoinpaperwallet.com/) 2in x .5in ([Alternative](http://www.amazon.com/gp/product/B00MWCCN7C))*
 - [Waterproof Bag](https://bitcoinpaperwallet.com/) 6in x 3in ([Alternative](http://www.amazon.com/Clear-Lock-Bags-Case-1000/dp/B0040003E4))
 - [Teslin Paper](http://www.amazon.com/dp/B004PX7ZTC) (Inkjet Printers)
 - [Revlar Paper](http://www.amazon.com/gp/product/B004UI335W/) (Laser Printers)
 - [Scratch Off Stickers](http://www.amazon.com/gp/product/B00ENI0NI4) 1in x 1in
 - [Laminating Pouches](http://www.amazon.com/gp/product/B00BWU3HNY) 8.9in x 11.4in
 - [Laminator](http://www.amazon.com/gp/product/B0010JEJPC)

>
*The official security stickers from bitcoinpaperwallet.com are serialized in pairs, meaning you get two of each number. This is best because each paper wallet requires two stickers, so the numbers match. The alternative link only provides one sticker for each number.

Dimensions:

 - Landscape: 5.5in x 2.5in (Slightly smaller than a dollar bill)
 - Portrait: 4in x 2in (Slightly bigger than a standard business card)
 - QR Codes: 1in x 1in (About the size of a quarter)

For additional artworks, check out [Liberty Paper Wallet](http://libertywallet.liberty.me/2015/03/18/liberty-wallet/) ([Github](https://github.com/SimonBelmond/libertypaperwallet)).

---
### Protecting your paper wallet

Paper wallets are extremely vulnerable to water.
Consider laminating your paper wallet for extra protection. An alternative could be to vaccuum seal it using a Foodsaver Vaccuum Sealer. At the very least, you should keep the paper wallet in a ziplock bag.

{% img center ./03.jpg %}

Paper wallets are also extremely vulnerable to fire.
However, there is not much you can do about this other than keeping multiple backups in different physical locations, such as a safety deposit box.

> 
Remember, if you lose your paper wallet, or it is damaged, you lose all the coins stored at that address!

---
### How to properly create a paper wallet

Paper wallets need to be created offline on a secure machine. For this tutorial, I will be using a [Tails](https://tails.boum.org/) Live CD. Grab the ISO and burn it to a disk. 

Save a [copy of bitcoinpaperwallet](https://github.com/cantonbecker/bitcoinpaperwallet/archive/master.zip) onto a USB drive.

 1. Shutdown your computer and boot from the CD. 
 2. When the Tails welcome box appears, select "More Options". 
 3. Enter an administrator password of your choice and login.
 4. Wait for tor to become ready.

>
For this tutorial, in order to get screenshots I am using a virtual machine. Do not use a virtual machine when doing this for real!

Before creating the paper wallet, you will want to ensure that your printer works correctly. You need a printer that is directly connected to your machine; don't use a network printer (you shouldn't be connected to any network). If possible, use a dumb printer, and try to ensure that your printer does not save a copy of printouts to internal memory. Use this time to get any drivers you need from the internet.

From the `Applications` menu, select `System Tools -> Administration -> Printing`. 

{% img center ./04.png %}

Add your printer. Open up Tor Browser and ensure that you can print a webpage.

{% img center ./05.png %}

Time to disconnect from the internet. Unplug the ethernet cord, turn off any wireless cards or routers as necessary. Verify that you are not online.

{% img center ./06.png %}

 1. Insert your usb drive
 2. Copy the github zip file to the `Tor Browser` folder on the filesystem
 3. Remove the usb drive
 4. Unpack the zip file

{% img center ./07.png %}

Open up the html file in Tor Browser. Follow the instructions to generate your paper wallet. You have the option of using the built-in random number generator, or supplying your own random numbers using dice or cards. For maximum security, you should use dice or cards. I found that taking a deck of cards, shuffling it seven times, and picking the first 32 cards off the top worked well. Remember to shuffle the cards again after you are done! "Brain wallets" may seem convenient, however you need to have a very strong passphrase for this to be secure; it is better to use random numbers.

{% img center ./08.png %}

>
**BIP38 Encryption?**  
There are pros and cons to encrypting your paper wallet. Encryption adds an extra layer of security by requiring a passphrase before being able to import the private key again, which is great if the paper wallet ever gets stolen. However if the passphrase is forgotten, the coins are lost forever. The passphrase is one more thing to remember / write down, which means it is one more thing to secure. In addition, some wallet software does not support BIP38, which may make reimporting difficult. Finally, it is important to realize that BIP38 encryption will NOT help if you chose an insecure passphrase for a brain wallet. In general, BIP38 encryption is recommended.

{% img center ./09.png %}

You will want to print two wallets by spinning the paper after each print. You will end up running the sheet of paper through the printer a total of 4 times.

{% img center ./10.jpg 400 600 %}

Now is your chance to verify the paper wallets. Make sure you can scan the QR codes, make sure the private key and public key match, etc.

{% img center ./11.png %}

Shutdown your Tails environment. It will wipe your ram for you.

Cut out each design by following the lines on the front. Fold the wallets and apply the stickers.

>
If you have a laser printer, you will want to include a small 1in x 1in square of paper between the private key and the candling pattern when folding the paper. Later on, we will be laminating the paper wallet, and the heat can cause the toner on each side of the fold to fuse together.

Sign the back and write the sticker numbers. This prevents someone from simply replacing the stickers or entire wallet without your knowledge.

{% img center ./12.jpg 400 600 %}

Put both paper wallets into a laminating pouch and run it through the laminator. Cut out each wallet, and store them in physically separate, secure locations.

{% img center ./13.jpg 400 600 %}

---
### How to properly use a paper wallet

You can scan the public key into Electrum or Mycelium as a watch-only wallet to keep track of your funds. Eventually you will want to spend the funds.

First, you need to delaminate the wallet. Cut a line along the edge closest to the paper where there is a tiny line of air, and peel away the laminate. A technique that worked for me was to cut along the "Private Key / Withdraw" line, then slide my knife underneath each sticker. Unfold the flap to access the private key. As you can see, it is still safe and legible, even after the lamination process.

{% img center ./14.jpg %}

Now comes the important part. The funds must be "swept" into an electronic wallet. You must take all the funds in one shot; do not attempt to partially spend the funds in a paper wallet. This is due to how Bitcoin Change works.

>
**Change?**  
When spending Bitcoins, *ALL* coins from that address are moved to new addresses.
The destination address will get the desired amount, and any remaining amount will be sent to a "change" address. If no "change" address is specified, the remaining amount will go to the miner that solves the block. Normally, an electronic wallet manages this for you behind the scenes, however when using a paper wallet directly, you will not have this control. This is why the entire balance of a paper wallet should be "swept" into an electronic wallet before spending.  
Read more about change [here](https://en.bitcoin.it/wiki/Change)

Once the paper wallet has been swept into the electronic wallet, it should be destroyed and never used again. Shred it or burn it.

{% img center ./15.jpg %}