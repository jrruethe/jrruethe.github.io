=begin
  Jekyll tag to include Markdown tables from post directory preprocessing with Liquid.
  Usage:
    {% table <filename> %}
  Dependency:
    - kramdown
=end
module Jekyll
  class TableTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      @text = text.strip
      super
    end
    
    require "kramdown"
    
    def render(context)
      me = context.registers[:site].me

      if me.url != "/atom.xml"
        @text.gsub!("./", "")
        filename = me.url[0..-2].gsub("/", "-").gsub("-blog-", "")
        filename = File.join Dir.pwd, "source/_posts", filename + "_" + @text
          
        @text = filename
      
        tmpl = File.read @text
        site = context.registers[:site]
        tmpl = (Liquid::Template.parse tmpl).render site.site_payload
        html = Kramdown::Document.new(tmpl).to_html
      else
        ""
      end
    end
  end
end
Liquid::Template.register_tag('table', Jekyll::TableTag)
