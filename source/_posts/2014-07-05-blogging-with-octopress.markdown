---
layout: post
title: "Blogging with Octopress"
image: true
date: 2014-07-05 20:51:27 -0400
comments: true
toc: true
categories: 
 - Octopress
---

Octopress is an excellent blogging platform that is very easy to maintain and customize. 
My particular repository has a lot of customizations, and this post is mainly intended to help me remember how to use the various features. 
However, it may be beneficial to others if they clone my repository or simply want to see what is possible.

{% more %}

# Dependencies

Grab all the dependencies:

    sudo apt-get install ruby bundler git  
    sudo gem install rake --version 0.9.2.2
    git clone git://github.com/imathis/octopress.git blog  
    cd blog  
    bundle install  

You may have a newer `rake` installed on your machine. Octopress requires version 0.9.2.2, so we need to make sure we use that version.

    alias rake="rake _0.9.2.2_"

---

# Starting Fresh

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
    - [Table of Contents](http://brizzled.clapper.org/blog/2012/02/04/generating-a-table-of-contents-in-octopress/) : List a table of contents at the top of each post
    - [Fancybox](https://www.ewal.net/2012/09/08/octopress-customizations/) : Enhance user experience when dealing with images
    
    And a few others that are listed below.

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

# Continuing from an existing repository

Use these instructions if you are continuing a blog that has already been created.

 1. Install the dependencies
 
        sudo apt-get install ruby bundler git ruby-gsl zlib1g-dev

 1. Clone the repository
 
        git clone -b source git@github.com:username/username.github.io.git blog
    
 2. Install the octopress dependencies
 
        bundle install
        
 3. Set up Github Pages
 
        rake setup_github_pages
        
 4. Sync the deployment
 
        $ cd _deploy/
        $ git pull origin master
        $ git add index.html
        $ git commit -m 'Deployment'
 
 5. Ready to go. Jump down to "Creating a post"
        
---
        
# Creating a post

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

# Scripting the difficult pieces

If you look at the [source for my blog](), you will see a small number of scripts that make managing the blog even easier.

 - install.sh : Simply clone the repo and run this to get everything set up
 - sync.sh : Synchronizes the repository with Github if a change was made on a different machine
 - new.sh Post Title : Make a new post with the specified title
 - preview.sh : Auto generate and start the web server for 127.0.0.1:4000
 - deploy.sh : Deploy to Github Pages
    
---
    
# Embedding Content

## Code

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
 - json
 - c++

For example:
{% raw %}
    {% include_code lang:ruby address-to-hash.rb %}
{% endraw %}

Results in:
{% include_code lang:ruby address-to-hash.rb %}

You can also embed code content directly into a markdown file by enclosing it with codeblocks:
{% raw %}
    {% codeblock lang:json %}
    
    {
       "one" : "1",
       "two" : "2"
    }
    
    {% endcodeblock %}	
{% endraw %}

Results in:
{% codeblock lang:json %}

{
   "one" : "1",
   "two" : "2"
}

{% endcodeblock %}	

A shortcut for this is to use 3 backticks followed by the language. Titles can also be added. In addition, both `codeblock` and backticks support highlighting line numbers with `mark`:
{% raw %}
    ``` json "This is my json" mark:1,3-4
    
    {
       "one" : "1",
       "two" : "2"
    }
    
    ```
{% endraw %}

Results in:

``` json "This is my json" mark:1,3-4

{
   "one" : "1",
   "two" : "2"
}

```

This is better than the normal 4-space indent. Compare:

    {
       "one" : "1",
       "two" : "2"
    }

---
## Image

Images can be embedded into posts. The image file must be placed in the same directory as the post, and have the same filename prefix. 
For example, the name of this file is `2014-07-05-blogging-with-octopress.markdown`, and the image below has the filename `2014-07-05-blogging-with-octopress_01.png`. 
The image is refered to by the name after the trailing `_`. In this case, the name is `01.png`.

To embed this image, use the tag like this:

{% raw %}
    {% img ./01.png [width] [caption] %}
    {% img ./01.png 150 Avatar %}
{% endraw %}

Which results in this:

{% img ./01.png 150 Avatar %}

> Caption is optional

If you have an image with a transparent background, you can embed it without the shadow border:

{% raw %}
    {% img borderless ./01.png 150 %}
{% endraw %}

{% img borderless ./01.png 150 %}

> Credits to [aycabta](https://github.com/aycabta/octopress-file-binder), [sheva-serg](http://deadunicornz.org/blog/2014/12/27/octopress-image-caption-plugin/), [Charles Beynon](https://eulerpi.io/2014/11/28/the-imgcaption-tag/), and [Erv Walter](https://www.ewal.net/2012/09/08/octopress-customizations/)

---
## Tweet

It is easy to add a tweet to a post using the Twitter API.

{% raw %}
    {% twitter oembed https://twitter.com/jrruethe/status/687108060612030465 align='center' %}
{% endraw %}

Results in:

{% twitter oembed https://twitter.com/jrruethe/status/687108060612030465 align='center' %}

**Note**  
You need to have a file named "twitter_credentials.sh" in the root to hold the Twitter API credentials. 
*Do not check this file into git!*
It should have the following contents:

    export TWITTER_CONSUMER_KEY=
    export TWITTER_CONSUMER_SECRET=
    export TWITTER_ACCESS_TOKEN=
    export TWITTER_ACCESS_TOKEN_SECRET=

> Credits to [Rob Murray](https://github.com/rob-murray/jekyll-twitter-plugin)

---
## Table

Tables can also be embedded into posts. Tables are written in markdown format and saved in an external file in the same directory as the post with the same filename prefix.
For example, the name of this file is `2014-07-05-blogging-with-octopress.markdown`, and the table below has the filename `2014-07-05-blogging-with-octopress_table.markdown`. 
The table is refered to by the name after the trailing `_`. In this case, the name is `table.markdown`.

The contents of the file look like this:

    | Key      | Value                                                                                    |
    | -------- | ---------------------------------------------------------------------------------------- |
    | Name:    | Joe Ruether                                                                              |
    | Email:   | [jrruethe@gmail.com](mailto:jrruethe@gmail.com)                                          |
    | Website: | [jrruethe.github.io](http://jrruethe.github.io/)                                         |
    | Twitter: | [@jrruethe](https://twitter.com/jrruethe)                                                |
    | Github:  | [jrruethe](https://github.com/jrruethe)                                                  |
    | Keybase: | [jrruethe](https://keybase.io/jrruethe)                                                  |
    | GPG:     | [4F40 99F8 276B DBA5 475A](http://jrruethe.github.io/downloads/code/jrruethe-public.asc) |
    |          | [8446 4630 BEDC 40B9 35FE](http://jrruethe.github.io/downloads/code/jrruethe-public.asc) |

To embed the table, use the tag like this:

{% raw %}
    {% table ./table.markdown %}
{% endraw %}

Which results in this:

{% table ./table.markdown %}

> 
Note:  
RSS feeds will not have rendered tables

---
## Table of Contents

You may have noticed the table of contents at the top of this page. 
This can be enabled by adding the following to the yaml at the top of any post:

    toc: true

The table of contents is automatically generated via javascript and will follow the headings indicated by `#`.

### More

I added a custom plugin called `more` designated by `{% raw %}{% more %}{% endraw %}`.
This tag should be put in each post after a brief description about the post.
The description will appear on the index page, with a little "Read More" button that links to the full page.
modified the original table of contents javascript to cause the table of contents to always be placed below the `more` tag.

> Credits to [Brian Clapper](http://brizzled.clapper.org/blog/2012/02/04/generating-a-table-of-contents-in-octopress/)

---
## Github

Github repository cards can be embedded into posts to allow easy access to open source software.

{% raw %}
    {% githubrepo jrruethe/dockerfile %}
{% endraw %}

Results in:

{% githubrepo jrruethe/dockerfile %}

---
## Video

Embedding a youtube video can be done by grabbing the video id from the url:  
[https://www.youtube.com/watch?v=**dQw4w9WgXcQ**](https://www.youtube.com/watch?v=dQw4w9WgXcQ)

Use the following tag:
{% raw %}
    {% youtube dQw4w9WgXcQ %}
{% endraw %}

Here is the result:
{% youtube dQw4w9WgXcQ %}

> Credits to [Udo Kramer](https://github.com/optikfluffel/octopress-responsive-video-embed)

---
## Map

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

> Credits to [Maximilian Güntner](https://github.com/mguentner/octolayer)

---
## Footnotes

Footnotes are good for attributing content made by other people. Simply place an anchor `[^1]` where you want the link to the footnote to appear.[^1]
Then, at the bottom of the page, put the actual footnote: `[^1]: This is a footnote`. The line above the footnotes is created automatically.

[^1]: This is a footnote
