---
layout: post
title: "PDF Generation with Ruby and Pocket"
date: 2014-08-16 23:14:33 -0400
comments: true
categories: 
 - Ruby
 - Scripts
---

One thing I like to do when I'm browsing the internet is save each interesting page I come across. 
I do this by printing the page to a PDF. This is better than saving a bookmark because articles on the internet have a tendency to go down when you need them most. 
In addition, I use [Pocket](http://getpocket.com/a/queue/list/) to save articles while browsing with my phone or work computer, where I cannot print to PDF. 
It is easy to export your Pocket articles to an HTML file, and it is easy to parse that file to extract the links.

{% more %}

First, we need some things.

    sudo apt-get install ruby cups-pdf wkhtmltopdf xdg-utils pcmanfm recoll
    gem install pdfkit nokogiri
    
I use LXDE, and `xdg-open` forwards requests though `pcmanfm`, so it needs to be installed. For indexing the PDFs, `recoll` is very useful and allows for quickly searching for content.

I wrote a small ruby script to take a URL and generate a PDF. It uses PDFKit under the hood, which in turn uses `wkhtmltopdf` to do the PDF generation. `wkhtmltopdf` has a tendency to get hung up on some pages, especially if Java is involved, and the normal ruby call to PDFKit will freeze until `wkhtmltopdf` is killed. I found out the hard way that the standard `Timeout` module in ruby isn't enough; the `wkhtmltopdf` process needs to be killed directly. I do this by using a timer thread and a small `killall` function:

{% codeblock lang:ruby %}
    # Kill a process by name
    def killall(name)
    
       # For each process
       Dir['/proc/[0-9]*/cmdline'].each do |p|
       
          # Check to see if the command line invocation matches the given name
          if File.read(p).match name
          
             # Grab the PID
             pid = p.split('/')[2].to_i
             
             # Kill the process
             Process.kill("SIGKILL", pid)
          end
       end
    end
{% endcodeblock %}

Note that this will only work on Linux, since it is crawling the Kernel's `proc` filesystem.  
With that function available, here is a small PDF generation class as a wrapper around PDFKit:

{% codeblock lang:ruby %}
    require 'pdfkit'
    
    # A wrapper around PDFKit that generates PDFs from URLs
    # It uses wkhtmltopdf under the hood.
    # wkhtmltopdf can sometimes hang, this wrapper takes care of that
    # so PDF generation can be autmomated
    class PdfGenerator
       
       def initialize
          PDFKit.configure do |config|
             config.default_options[:load_error_handling] = 'ignore'
             config.default_options[:load_media_error_handling] = 'ignore'
          end
       end
       
       # Convert a webpage to a PDF file
       # Returns true if successful, false if there was an error or a timeout
       def from_url(url, output_filename)
          
          retval = true
          
          # Run the PDF generation in a thread
          # so we can kill it after some amount of time
          process_thread = Thread.new do
             begin
                puts "Processing " + url
                kit = PDFKit.new(url)
                kit.to_file(output_filename)
             rescue
                puts "Failed to process " + url
                retval = false
             end
          end
       
          # Start a timer to kill the process thread
          # if it takes too long
          timeout_thread = Thread.new do
             sleep 60
             if process_thread.alive?
                killall "wkhtmltopdf"
                process_thread.kill
                puts "Timed out"
                retval = false
             end
          end
          
          # Wait for the process thread to end
          process_thread.join
          timeout_thread.kill
          
          if retval
             puts "Successfully processed " + url
          end
          
          return retval
          
       end
       
    end
{% endcodeblock %}

The next step is to parse out the Pocket export file to get the title and links. Here is some code for that:

{% codeblock lang:ruby %}
    require 'nokogiri'
    
    # Create a PDF generator
    pdf_generator = PdfGenerator.new
    
    # Open the pocket export file
    page = Nokogiri::HTML(open("ril_export.html"))
    
    # Parse out the links
    links = page.css('a')
    
    # For each link
    links.each do |link|
    
       title = link.text
       url = link['href']
    
       # Sanitize the title to be a valid filename
       title.gsub!(/[^0-9A-Za-z.\-]/, '_')
       title.downcase!
       
       # Specify the output filename using the title
       output_filename = title + '.pdf'
        
       # Skip any files that have already been processed
       if File.exist?(output_filename)
          next
       end
        
       # Generate the PDF
       result = pdf_generator.from_url(url, output_filename)
        
    end
{% endcodeblock %}

The end result will be that all your Pocket articles will be printed to PDF! Very nice and easy to automate.

But what to do with all these PDFs? Recoll is a simple indexer that can quickly search them for the content you are looking for. After a large collection of links have been built up, you will have your own little offline internet database at your fingertips.
