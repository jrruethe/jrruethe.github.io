---
layout: post
title: "Blogging with Octopress"
date: 2014-07-05 20:51:27 -0400
comments: true
categories: 
---

### Before you continue

Grab all the dependencies:

    sudo apt-get install ruby bundler git  
    sudo gem install rake --version 0.9.2.2
    git clone git://github.com/imathis/octopress.git blog  
    cd blog  
    bundle install  

You may have a newer `rake` installed on your machine. Octopress requires version 0.9.2.2, so we need to make sure we use that version.

    alias rake="rake _0.9.2.2_"

---

### Starting Fresh

Use these instructions if you are creating a blog for the first time.

 1. Install the blog
 
        rake install  
 
 2. Create the Github repository
 
    Go to [Github](https://github.com/repositories/new), create a new repository of the format `username.github.io`
    
 3. Set up deployment to Github Pages
 
        rake setup_github_pages
        rake generate
        rake deploy
        
 4. Commit the source
 
        git add .
        git commit -m 'your message'
        git push origin source
        
 5. Add some customizations
 
    I personally use the following third party plugins:
    
    - [Bitcoin](https://github.com/PartTimeLegend/octopress-bitcoin-donation-aside) : Add a QR code for Bitcoin Donations
    - [File Binder](https://github.com/aycabta/octopress-file-binder) : Easily attach an image to a post
    - [QR Codes](https://github.com/sailor79/Octopress-dynamic-QR-Code-aside) : Add QR codes for mobile navigation and sharing
    - [Octolayer](https://github.com/mguentner/octolayer) : Embed maps into posts
    - [Responsive Video Embed](https://github.com/optikfluffel/octopress-responsive-video-embed) : Embed Youtube videos into posts  

 6. Sign up for [Disqus](https://disqus.com)
 
 7. Configure your _config.yml file
 
    Set the following options:
    
    - URL
    - Title
    - Subtitle
    - Author  
    
    Also scroll down to the bottom and set up the following sections:
    
    - Github
    - Twitter
    - Disqus  
    
 8. Ready to go. Jump down to "Creating a post"
        
---

### Continuing from an existing repository

Use these instructions if you are continuing a blog that has already been created.

 1. Install the dependencies
 
        sudo apt-get install ruby bundler git ruby-gsl
        sudo gem install rake --version 0.9.2.2

 1. Clone the repository
 
        git clone -b source git@github.com:username/username.github.io.git blog
    
 2. Install the octopress dependencies
 
        bundle install
        
 3. Set up Github Pages
 
        rake setup_github_pages
        
 4. Ready to go. Jump down to "Creating a post"
        
---
        
### Creating a post

To create a new post:

    rake new_post["title"]
    
Then you can preview your work:

    rake generate
    rake preview
    
Open your browser to `127.0.0.1:4000` and make sure your page looks the way you want.  
To finalize your changes:

    git add source/_posts/date-title.markdown
    git commit -m 'Message'
    git push origin source
    rake deploy
    
Next, you want to make sure that you re-pull after the deployment is complete, or you will run into problems when creating your next post:

    git pull
    cd _deploy/
    git pull
    cd -
    
Go to `username.github.com` and check out your page.
    
---

### Scripting the difficult pieces

If you look at the [source for my blog](), you will see a small number of scripts that make managing the blog even easier.

 - install.sh : Simply clone the repo and run this to get everything set up
 - sync.sh : Synchronizes the repository with Github if a change was made on a different machine
 - new.sh Post Title : Make a new post with the specified title
 - preview.sh : Auto generate and start the web server for 127.0.0.1:4000
 - deploy.sh : Deploy to Github Pages
    
---
    
### Embedding Content

#### Code

It is easy to embed any text file found in the source/downloads/code folder.  
Octopress even supports syntax highlighting, and a handy download link.
{% raw %}
    {% include_code lang:yaml filename.ext %}
{% endraw %}

lang can be any of the following:

 - ruby
 - yaml
 - bash
 - python

For example:
{% raw %}
    {% include_code lang:ruby address-to-hash.rb %}
{% endraw %}

Results in:
{% include_code lang:ruby address-to-hash.rb %}

#### Image

Images can be embedded into posts. The image file must be placed in the same directory as the post, and have the same filename prefix. For example, the name of this file is `2014-07-05-blogging-with-octopress.markdown`, and the image below has the filename `2014-07-05-blogging-with-octopress_01.png`. The image is refered to by the name after the trailing `_`. In this case, the name is `01.png`.

To embed this image, use the tag like this:
{% raw %}
    {% img center ./01.png %}
{% endraw %}

Which results in this:
{% img center ./01.png %}

#### Video

Embedding a youtube video can be done by grabbing the video id from the url:  
[https://www.youtube.com/watch?v=**dQw4w9WgXcQ**](https://www.youtube.com/watch?v=dQw4w9WgXcQ)

Use the following tag:
{% raw %}
    {% youtube dQw4w9WgXcQ %}
{% endraw %}

Here is the result:
{% youtube dQw4w9WgXcQ %}

#### Map

Embedding a map can be done with the following tag:
{% raw %}
    {% map lat lon zoomLevel "markerTitle" "description" %}
{% endraw %}
    
A simple example is shown here:
{% raw %}
    {% map 37.7577 -122.4376 13z "San Francisco" "Map Demo" %}
{% endraw %}

And here is the result:
{% map 37.7577 -122.4376 13z "San Francisco" "Map Demo" %}