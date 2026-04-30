require "cgi"

module Reins
  class View
    module Helpers
      VOID_ELEMENTS = %i[area base br col embed hr img input link meta source track wbr].freeze

      def link_to(text, url, **attrs)
        tag(:a, text, href: url, **attrs)
      end

      def tag(name, content = nil, **attrs)
        if VOID_ELEMENTS.include?(name)
          "<#{name}#{format_attrs(attrs)}>"
        else
          "<#{name}#{format_attrs(attrs)}>#{content}</#{name}>"
        end
      end

      def image_tag(src, **attrs)
        tag(:img, src: "/#{src}", **attrs)
      end

      def url_for(path, **query)
        return path if query.empty?

        "#{path}?#{query.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')}"
      end

      def stylesheet_link_tag(name)
        tag(:link, rel: "stylesheet", href: "/css/#{name}.css")
      end

      def javascript_include_tag(name)
        tag(:script, "", src: "/js/#{name}.js")
      end

      private

      def format_attrs(attrs)
        return "" if attrs.empty?

        " #{attrs.map { |k, v| %(#{k}="#{CGI.escapeHTML(v.to_s)}") }.join(' ')}"
      end
    end
  end
end
