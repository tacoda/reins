require "erubis"
require "cgi"
require "reins/errors"
require "reins/routes/url_helpers"
require "reins/view/helpers"
require "reins/view/forms"

module Reins
  class View
    include Reins::Routes::UrlHelpers
    include Helpers
    include Forms

    DEFAULT_LAYOUT = "application".freeze
    VIEWS_ROOT = "app/views".freeze

    # rubocop:disable Naming/AccessorMethodName
    def set_vars(instance_vars)
      instance_vars.each do |name, value|
        instance_variable_set(name, value)
      end
    end
    # rubocop:enable Naming/AccessorMethodName

    def evaluate(template, locals = {}, &)
      eruby = Erubis::EscapedEruby.new(template)
      bind = binding
      locals.each { |k, v| bind.local_variable_set(k, v) }
      eval(eruby.src, bind) # rubocop:disable Security/Eval
    end

    def render_template(path, locals: {}, layout: :default)
      @sections ||= {}
      inner = evaluate(read_template(path), locals)
      layout_name = resolve_layout(layout)
      return inner unless layout_name

      evaluate(read_template("layouts/#{layout_name}"), locals) do |section = nil|
        section ? @sections[section.to_s] : inner
      end
    end

    def render(*args, **kwargs)
      partial_path, render_locals, collection = parse_render_args(args, kwargs)

      if collection
        collection.map { |item| render_partial(partial_path, single_local(partial_path, item)) }.join
      else
        render_partial(partial_path, render_locals)
      end
    end

    def content_for(name, value = nil, &block)
      @sections ||= {}
      @sections[name.to_s] = block ? block.call : value
      nil
    end

    def h(str)
      CGI.escapeHTML(str)
    end

    private

    def parse_render_args(args, kwargs)
      if kwargs[:partial] && kwargs[:collection]
        [kwargs[:partial], {}, kwargs[:collection]]
      elsif kwargs[:locals]
        [args.first, kwargs[:locals], nil]
      else
        [args.first, kwargs.except(:partial, :collection), nil]
      end
    end

    def render_partial(path, locals)
      dir, name = File.split(path)
      partial_path = File.join(dir, "_#{name}")
      evaluate(read_template(partial_path), locals)
    end

    def single_local(path, item)
      local_name = File.basename(path)
      { local_name.to_sym => item }
    end

    def resolve_layout(layout)
      case layout
      when false then nil
      when :default then default_layout_if_present
      else layout.to_s
      end
    end

    def default_layout_if_present
      File.exist?(template_filename("layouts/#{DEFAULT_LAYOUT}")) ? DEFAULT_LAYOUT : nil
    end

    def read_template(path)
      filename = template_filename(path)
      raise Reins::MissingTemplate, "missing template: #{filename}" unless File.exist?(filename)

      File.read(filename)
    end

    def template_filename(path)
      File.join(VIEWS_ROOT, "#{path}.html.erb")
    end
  end
end
