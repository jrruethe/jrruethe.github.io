---
layout: post
title: "Bitcoin Donations"
date: 2015-12-04 20:37:39 -0500
comments: true
toc: true
categories: 
 - Bitcoin
---

Its that time of year again, and I am reminded by the large banner at the top of Wikipedia. 
I have some spare change lying around, and I feel like showing my support to fellow programmers who maintain the software I use every day.

I am a strong supporter of Bitcoin and naturally I wanted to use it for donations. 
I have had my Bitcoin address posted on my blog, and have had a few donations from readers (thank you!). 
One of the best things about Bitcoin is that anyone can send and receive money without needing to sign up for anything. 
It is a great way to quickly and convieniently transfer cash, and you can be sure that your transaction reaches the intended person without needing to interact with any middleman.

{% more %}

First, I compiled a list of the major OSS software products I rely on, as well as projects I truely believe in, and found the donation pages for each. I discovered that many of them do provide a way to pay with Bitcoin; however, the methods, formats, and requirements varied greatly. This is a perfect opportunity to provide a review on how easy or difficult it is to donate Bitcoin to websites today. I took my list and trimmed it down to a small subset of different examples. This post will be reviewing the Bitcoin donation methods for the following sites:

 - [Armory](https://bitcoinarmory.com/contact/)
 - [Debian](http://www.debian.org/donations)
 - [Eclipse](https://www.eclipse.org/donate/)
 - [Electronic Frontier Foundation](https://supporters.eff.org/donate)
 - [Freedom of the Press Foundation](https://freedom.press/donate)
 - [Free Software Foundation](https://my.fsf.org/donate/)
 - [Mozilla](https://donate.mozilla.org/en-US/give-bitcoin/)
 - [Qubes](https://www.qubes-os.org/donate/)
 - [RiseUp](https://www.qubes-os.org/donate/)
 - [Veracrypt](https://veracrypt.codeplex.com/wikipage?title=Bitcoin%20Donation)
 - [Wikipedia](https://wikimediafoundation.org/wiki/Ways_to_Give#bitcoin)

---
# Doing it the right way

I must really commend the Free Software Foundation and Qubes. Of all the sites I reviewed, I feel these sites are the only ones who are doing it "right".

 - All additional information is optional
 - A static Bitcoin address is displayed on the main donation page
 - With a QR code for easy scanning
 - And a GPG signed statement verifying ownership of the address

{% img ./01.png Free Software Foundation %}

I want to bring special attention to this last point. Bitcoin addresses are almost impossible to remember and have no identifying features to link them to the owner. Hackers could exploit a website and change the address server-side, or a MitM attack could allow the address to be spoofed on the client side (the latter is especially true if using Tor, where the exit node can replace webpage content). For these reasons, Bitcoin addresses displayed on webpages should have an accompanying GPG signature to prove ownership and eliminate the risk of tampering.

A special mention to the folks at Armory. They have set up a [donation matching program](https://bitcoinarmory.com/donation-match-list/), where they provide [signed addresses](https://s3.amazonaws.com/bitcoinarmory-simulnotes/signed_donation_addresses.txt) and a method for [verifying the signatures](https://bitcoinarmory.com/donation-matching/#verify-donation-addresses). Curiously, they do not sign their [own address](https://bitcoinarmory.com/contact/) on their website (even though it can be obtained from their software).

Many sites had a static address displayed, but failed to provide a QR code for scanning. In fact, of all the I sites reviewed, only the following had QR codes for their static addreses:

 - Free Software Foundation
 - Qubes
 - Veracrypt

Many other sites use Bitpay or Coinbase to do dynamic addresses: temporary addresses that "timeout" after a short amount of time. Bitpay is an indespensible tool for merchants that also makes things very easy for the user; for example, on a webpage a user could specify how much they want to donate, and Bitpay will create a special QR code that tells Bitcoin clients to make a transaction for that amount. This interaction reduces the chance of mistyping an amount (remember, Bitcoin transactions cannot be revoked). Each transaction is isolated to a single address. Cycling addresses increases privacy for both the sender and receiver. It also makes creating a receipt easier, and helps clear up any confusion. In fact, the Bitcoin developers themselves discourage [address reuse](https://en.bitcoin.it/wiki/Address_reuse). Here is an example from the Freedom of the Press Foundation:

{% img ./02.png Freedom of the Press %}  
> Note, don't actually use that address, it is expired!

Bitpay's temporary addresses are a blessing and a curse; You cannot sign a temporary address. This also means I cannot share that address with anyone else if I want to promote that website or service; users are required to visit the page, fill out the form, and get their own temporary address to send to. I can't build up an "address book" of websites/services and their payment address.

RiseUp was the only site I could find that did dynamic addresses without using a 3rd party service like BitPay or Coinbase. Furthermore, they claim that they maintain the private key for the dynamically generated address, and that it doesn't expire. While the approach is novel, I think it leads to the worst of both worlds; they lost the ability to sign their addresses while at the same time didn't receive the other benefits of temporary addresses granted by a service like BitPay. Furthermore, anyone is able to cause RiseUp to generate a new address, but they must keep and manage each generated address, which could be troublesome. Finally, if you go with the "address-book" method, the dynamically generated addresses are *per-person*, which promotes tracking.

>
**Address Reuse**  
By now you may have noticed that I am making some contradictions. I labeled the display of a static address as the "right way", then immediately followed up with the Bitcoin Dev's recommendations against address reuse. Remember that this post is in the context of donations. I think the distinction here is that something like Bitpay is perfect (and correct) for sales transactions where I buy a product or service, and displaying a static address is better for donations where I want to ensure the correct recipient gets the money. If I am buying something online, I typically don't care where the money goes as long as I receive what I bought. For example, Amazon heavily utilizes 3rd party merchants, to the point where I rarely notice whether I am paying Amazon directly or some other store. With donations, I am not receiving anything in return other than the reassurance that I am supporting something I believe in, so it becomes more important to verify that the correct entity is receiving my donation. Signatures on static addresses solve this problem. I'm interested in hearing other arguments or solutions!

Of all the forms I came across, the one for Eclipse was the by far the mosts intuitive and clear:

{% img ./03.png Eclipse %}

The form is short and 100% optional. There is even a little checkbox to stay anonymous. Preselected donation amounts are available, as well as a box to specify your own number. I especially liked how I didn't have to scroll all over the page looking for the Bitcoin option; many of the sites I looked at hide the Bitcoin address at the bottom or side of their donation page instead of integrating that option in with the others. Well done Eclipse!

---
# Doing it the wrong way

Don't misunderstand, I am very happy that Bitcoin was an option for donations. However, I feel that some of these sites are missing the point; A Bitcoin transaction doesn't need any other information besides an address. If you want to receive a donation, you shouldn't need a name, address, email, phone number, etc required. Just take the money!

For example, the EFF requires my name, email, and *shipping address* to receive a Bitcoin donation:

{% img ./04.png Electronic Frontier Foundation %}

Wikipedia also requires a shipping address. Why is this information needed? What are they going to send me? Why can't I opt out?

{% img ./05.png Wikipedia %}

Even Mozilla won't let me send them a Bitcoin donation without an email address:

{% img ./06.png Mozilla %}

What could they need an email address for? A receipt? No need, the blockchain is a public ledger that replaces the need for a receipt. A thank you message? No need, afterall, I'm the one thanking *you* with my donation! Signing me up on an email list? Most likely, and I don't need more spam.

Sorry guys, but you are missing the point. This tells me you are more interested in my information than my support.

---
# Not doing it at all

Unfortunately, Bitcoin still hasn't hit critical mass. By now, many people have at least heard of it, but the average person doesn't understand how to use it, how it works, or its benefits. There are still many websites that do not have a Bitcoin donation option. Some of the programs I use every day did not accept Bitcoin, however they did take PayPal.

The surprising one here was Debian. Not only do they not take Bitcoin, they don't even take Paypal. Their [preferred methods](https://www.debian.org/donations) of payment are credit card or check. Look at how much stuff I need to fill out to donate:

{% img ./07.png Debian %}

This right here is a prime example of how amazingly simple Bitcoin is.

However, they do bring up some [very interesting points](https://lists.debian.org/debian-project/2014/08/msg00077.html) that offer a unique perspective on why accepting Bitcoin donations can be difficult, especially for a large organization:

 - Keep donations in Bitcoin or convert to USD?
 - If convert, using who? Need a reliable exchange
 - If convert, when? Immediately, or try to make profit? Bitcoin is volatile
 - Poor choices here can affect public perception
 - Regulations on Bitcoin are still not stable

---

As you can see, there is a huge disparity in how different websites accept Bitcoin donations. Hopefully this post can give you ideas on how to accept Bitcoin donations on your own website. As a final note, thank you to all my readers for their support, it is appreciated!

