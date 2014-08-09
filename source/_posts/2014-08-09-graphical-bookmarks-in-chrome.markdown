---
layout: post
title: "Graphical Bookmarks in Chrome"
date: 2014-08-09 18:25:50 -0400
comments: true
categories: 
---

I have a large amount of bookmarks, and I find that even with good organization, I tend to lose them in the bookmark bar. For me it is much easier to find that bookmark I am looking for if I can see a thumbnail of the page. These graphical bookmarks are known as "speed dials", and there is a Chrome extension that implements it very well: Speed Dial 2

One of the things I did not like about Speed Dial 2 was manually entering each bookmark, then selecting a thumbnail for it. The import / export format was very confusing to figure out, and I decided that automating the whole thing would be a big timesaver in the end. So I wrote a Ruby script to do just that.

Requirements:

 - Google Chrome / Chromium
 - Ruby
 - Speed Dial 2 extension [here](https://chrome.google.com/webstore/detail/speed-dial-2/jpfpebmajhhopeonhlcgidhclcccjcik) 
 - Speed Dial conversion script [here](https://github.com/jrruethe/speeddial) 
 - A bookmarks.yml file, as described below
  
The format of the file is pretty simple. There can be multiple groups that represent tabs on the Chrome home screen. Each group can have multiple bookmarks that represent dials on the home screen. The dial thumbnail will be automatically generated from a screenshot of that URL, but it can be manually changed later. It should be noted that whichever group appears first in the file will be the default group that is selected when a new Chrome home page is opened.
    
    ---
    Group:
     - Title : URL
     - Title : URL
    ...
        
Included in the repository is my bookmarks.yml file, which includes multiple useful bookmarks for various tasks.

Put it all together
-------------------
 
Run the conversion script: 
 
    ./speeddial.rb --input bookmarks.yml --output bookmarks.json
        
On the Chrome home page, which is now Speed Dial 2, select Options -> More Options -> Import / Export -> Import Settings. Copy the contents of `bookmarks.json` and paste it into the box. Click "Import these settings" and save. The initial load will take a moment, and you will see an error like the following:
 
    Something unexpected happened: could not execute statement due to a constraint failure (19 constraint failed)
    
The error can be safely ignored (it may appear a few times). Once the initial load is complete (you may need to refresh), subsequent loads will be much faster, and will not throw errors.

Sometimes the thumbnails are not generated correctly. For those, you can simply right click and edit to change the thumbnail. If you see "Generating thumbnail...", then simply refresh the screen at a later time. The thumbnail generation is done using a third-party web service, which queues up requests, so thumbnails should appear at a later time.