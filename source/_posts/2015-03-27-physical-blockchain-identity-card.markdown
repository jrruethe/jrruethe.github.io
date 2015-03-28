---
layout: post
title: "Physical Blockchain Identity Card"
date: 2015-03-27 18:28:47 -0400
comments: true
categories: 
---

In a [previous post](http://jrruethe.github.io/blog/2015/02/28/blockchain-identity/), I walked through the steps to create a digitial Blockchain Identity. Now, it is time to turn that into an physical identity card.

You will need the following:

 - [Laminator](http://www.amazon.com/gp/product/B0010JEJPC/ref=od_aui_detailpages00?ie=UTF8&psc=1)
 - [10 mil Teslin Paper](http://www.amazon.com/gp/product/B004XJC1UQ/ref=od_aui_detailpages00?ie=UTF8&psc=1)
 - [10 mil Butterfly Pouch Laminates](http://www.amazon.com/gp/product/B004UJC730/ref=ox_sc_act_title_2?ie=UTF8&psc=1&smid=A1GYMVIZIMSYWM)
 - A color inkjet printer

You will also need the following software:

 - Inkscape
 - QtQr
 - gLabels

There is no standard template for your ID card; you can design it however you wish. The general idea is that it displays the necessary information to be a link between your government issued identification document and your GPG key. It is also a convienient place to put some contact information.

The most important item it must contain is the QR code containing your key.json.asc information. Remember, only the hash of this file is stored in the blockchain, so you need to make the data available for verification. For this reason, it is also recommended to include the hash and the Bitcoin transaction ID on your card. Finally, a link to your Keybase.io account is recommended.

To prove your identity, one would scan the QR code containing your key.json.asc information to obtain the ASCII text, and use your Keybase.io account to verify it's authenticity. Then, the hash of that data can be calculated and compared against the Bitcoin transaction. All the information needed (besides keybase.io and blockchain.info) are stored on your physical card; no need for your personal computer. Furthermore, the information can be validated with a smart phone; no full PC is needed.

Below you will find the template I designed using Inkscape. It isn't very flashy, but it does it's job well. 

{% img center ./01.png %}

Do note that I let the edges overlap a little bit to ensure the color covers the entire border.  
Here is the back, and containing the most important part of the document:

{% img center ./02.png %}

Scanning that will reveal the key.json.asc data.

Next, this card needs to be layed out on the Teslin paper properly. For this, I used gLabels and created a custom template. It took some trial and error to get everything lined up correctly, but here are the settings I ended up using:

 1. Width: 87.6 mm
 2. Height: 56.0 mm
 3. Round: 3.0 mm
 4. Horizontal Waste: 1.0 mm
 5. Vertical Waste: 1.0 mm
 6. Margin: 1.0 mm

and:

 - nx: 2
 - ny: 4
 - x0: 15.9 mm
 - y0: 15.9 mm
 - dx: 97.0 mm
 - dy: 64.0 mm

Here are the steps:

 1. Once you create your card in Inkscape, export it to a png. 
 2. Open gLabels and use your png to create a card. 
 3. Print it onto the Teslin paper at the highest quality your printer allows. 
 4. Let it dry, then pop the card out and place it inside of a butterfly pouch. 
    - Do note that the glossy side goes out, the matte side is glue that should be up against the Teslin paper. 
    - Also, the folded edge should be at the bottom of the card. 
    - Be careful not to get fingerprints on the inside of the pouch. 
 5. Warm up the laminator and feed the butterfly pouch containing the card folded edge first into the laminator. 
 6. When it comes out, flip it over and run it through again (on the other side). 
    - You may need to run it through each side twice, for a total of four times. 
 7. Let it cool, and enjoy your finished product! 

The result will look and feel like a real ID card. Below is an image of mine, with some stuff blurred out.

{% img center ./03.jpg %}