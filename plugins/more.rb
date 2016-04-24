
module Jekyll
  class MoreTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
        "<!--more--><div class='more'></div>"
    end
    
  end
end
Liquid::Template.register_tag('more', Jekyll::MoreTag)
