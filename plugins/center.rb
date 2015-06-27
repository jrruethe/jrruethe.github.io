=begin
  Jekyll tag to include Markdown text from _includes directory preprocessing with Liquid.
  Usage:
    {% markdown <filename> %}
  Dependency:
    - kramdown
=end
module Jekyll
  class CenterTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text.strip
    end
    require "kramdown"
    def render(context)
      center = "style=\"text-align: center;\""
      format = "\n{: #{center}}"
      html = Kramdown::Document.new(@text + format).to_html
    end
  end
end
Liquid::Template.register_tag('center', Jekyll::CenterTag)
