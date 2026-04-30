require "cgi"

module Reins
  class View
    module Forms
      def form_with(url:, method: :post, **attrs)
        format_open_tag(:form, action: url, method: method.to_s, **attrs)
      end

      def text_field(name, **attrs)
        format_self_close_tag(:input, type: "text", name: name.to_s, **attrs)
      end

      def text_area(name, value: "", **attrs)
        body = CGI.escapeHTML(value.to_s)
        format_open_tag(:textarea, name: name.to_s, **attrs).sub(/>\z/, ">#{body}</textarea>")
      end

      def submit(value = "Save", **attrs)
        format_self_close_tag(:input, type: "submit", value: value.to_s, **attrs)
      end

      def hidden_field(name, value:, **attrs)
        format_self_close_tag(:input, type: "hidden", name: name.to_s, value: value.to_s, **attrs)
      end

      def label(name, text = nil, **attrs)
        text ||= humanize(name.to_s)
        "<label for=\"#{name}\"#{format_form_attrs(attrs)}>#{text}</label>"
      end

      private

      def format_open_tag(tag, **attrs)
        "<#{tag}#{format_form_attrs(attrs)}>"
      end

      def format_self_close_tag(tag, **attrs)
        "<#{tag}#{format_form_attrs(attrs)}>"
      end

      def format_form_attrs(attrs)
        return "" if attrs.empty?

        " #{attrs.map { |k, v| %(#{k}="#{CGI.escapeHTML(v.to_s)}") }.join(' ')}"
      end

      def humanize(str)
        str.tr("_", " ").split.map(&:capitalize).join(" ")
      end
    end
  end
end
