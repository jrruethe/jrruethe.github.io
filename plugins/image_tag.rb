# Title: Simple Image tag for Jekyll
# Authors: Brandon Mathis http://brandonmathis.com
#          Felix Schäfer, Frederic Hemberger
# Description: Easily output images with optional class names, width, height, title and alt attributes
#
# Syntax {% img [class name(s)] [http[s]:/]/path/to/image [width [height]] [title text | "title text" ["alt text"]] %}
#
# Examples:
# {% img /images/ninja.png Ninja Attack! %}
# {% img left half http://site.com/images/ninja.png Ninja Attack! %}
# {% img left half http://site.com/images/ninja.png 150 150 "Ninja Attack!" "Ninja in attack posture" %}
#
# Output:
# <img src="/images/ninja.png">
# <img class="left half" src="http://site.com/images/ninja.png" title="Ninja Attack!" alt="Ninja Attack!">
# <img class="left half" src="http://site.com/images/ninja.png" width="150" height="150" title="Ninja Attack!" alt="Ninja in attack posture">
#

module Jekyll

  class ImageTag < Liquid::Tag
    @img = nil

    def initialize(tag_name, markup, tokens)
      attributes = ['class', 'src', 'width', 'height', 'title']

      if markup =~ /(?<class>\S.*\s+)?(?<src>(?:https?:\/\/|\/|\S+\/)\S+)(?:\s+(?<width>\d+))?(?:\s+(?<height>\d+))?(?<title>\s+.+)?/i
        @img = attributes.reduce({}) { |img, attr| img[attr] = $~[attr].strip if $~[attr]; img }
        if /(?:"|')(?<title>[^"']+)?(?:"|')\s+(?:"|')(?<alt>[^"']+)?(?:"|')/ =~ @img['title']
          @img['title']  = title
          @img['alt']    = alt
        else
          @img['alt']    = @img['title'].gsub!(/"/, '&#34;') if @img['title']
        end
        @img['class'].gsub!(/"/, '') if @img['class']
        
        # Set width to 100% if not specified
        @img['width'] = '100%' unless @img['width']
        
        # Set a blank class if not specified
        @img['class'] = '' unless @img['class']
        
      end
      super
    end

    def render(context)
      if @img
        # If a title (caption) was given
        if @img['title']

          "<div class='img-outer-div'>" +
          "<div class='img-inner-div'>" +
          "<span class='caption-wrapper' style='width:#{@img['width']};'>" +
          "<a class='fancybox' rel='group' href='#{@img['src']}'>" +
          "<img class='caption' src='#{@img['src']}' width='#{@img['width']}' title='#{@img['title']}' alt='#{@img['alt']}'>" +
          "</a>" +
          "<span class='caption-text'>#{@img['title']}</span>" +
          "</span>" +
          "</div>" +
          "</div>"
          
        else
        
          # "<img #{@img.collect {|k,v| "#{k}=\"#{v}\"" if v}.join(" ")}>"
          "<div class='img-outer-div'>" +
          "<div class='img-inner-div'>" +
          "<a class='fancybox' rel='group' href='#{@img['src']}'>" +
          "<img class='#{@img['class']}' src='#{@img['src']}' width='#{@img['width']}' title='#{@img['title']}' alt='#{@img['alt']}'>" +
          "</a>" +
          "</div>" +
          "</div>"
          
        end
      else
        "Error processing input, expected syntax: {% img [class name(s)] [http[s]:/]/path/to/image [width [height]] [title text | \"title text\" [\"alt text\"]] %}"
      end
    end
  end
end

Liquid::Template.register_tag('img', Jekyll::ImageTag)
