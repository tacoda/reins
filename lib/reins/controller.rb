require "rack"
require "json"
require "reins/view"
require "reins/errors"
require "reins/parameters"
require "reins/flash"
require "reins/routes/url_helpers"

module Reins
  class Controller
    include Reins::Routes::UrlHelpers
    include Reins::View::Helpers
    include Reins::View::Forms

    class << self
      def before_action(name, only: nil, except: nil)
        own_filters[:before] << build_filter(name, only, except)
      end

      def after_action(name, only: nil, except: nil)
        own_filters[:after] << build_filter(name, only, except)
      end

      def around_action(name, only: nil, except: nil)
        own_filters[:around] << build_filter(name, only, except)
      end

      def layout(name, only: nil, except: nil)
        own_layouts << { name: name, only: array_or_nil(only), except: array_or_nil(except) }
      end

      def layout_for(action)
        controller_ancestors.each do |a|
          a.own_layouts.each do |entry|
            return entry[:name] if filter_applies?(entry, action)
          end
        end
        :default
      end

      def own_layouts
        @own_layouts ||= []
      end

      def filters_for(kind, action)
        all_filters(kind).select { |f| filter_applies?(f, action) }
      end

      def own_filters
        @own_filters ||= { before: [], after: [], around: [] }
      end

      def all_filters(kind)
        controller_ancestors.flat_map { |a| a.own_filters[kind] }
      end

      def action(act, routing_params = {})
        proc { |env| new(env).dispatch(act, routing_params) }
      end

      private

      def build_filter(name, only, except)
        { name: name.to_sym, only: array_or_nil(only), except: array_or_nil(except) }
      end

      def array_or_nil(value)
        return nil if value.nil?

        Array(value).map(&:to_sym)
      end

      def filter_applies?(filter, action)
        action_sym = action.to_sym
        if filter[:only]
          filter[:only].include?(action_sym)
        elsif filter[:except]
          !filter[:except].include?(action_sym)
        else
          true
        end
      end

      def controller_ancestors
        ancestors
          .select { |a| a.is_a?(Class) && (a == Reins::Controller || a < Reins::Controller) }
          .reverse
      end
    end

    attr_reader :env

    def initialize(env)
      @env = env
      @routing_params = {}
    end

    def dispatch(action, routing_params = {})
      @routing_params = routing_params
      @action = action.to_sym

      around_filters = self.class.filters_for(:around, @action)
      run_around(around_filters) do
        run_before
        if @response.nil?
          send(@action)
          run_after
        end
      end

      auto_render if @response.nil?
      sweep_flash
      rack_tuple
    end

    def request
      @request ||= Rack::Request.new(@env)
    end

    def params
      @params ||= Reins::Parameters.new(request.params.merge(@routing_params))
    end

    def session
      unless @env["rack.session"]
        raise Reins::SessionMiddlewareMissing,
              'Rack session middleware is required. Add `use Rack::Session::Cookie, secret: ...` to config.ru.'
      end

      @env["rack.session"]
    end

    def reset_session
      session.clear
    end

    def flash
      @flash ||= Reins::Flash.new(session)
    end

    def render(view = nil, plain: nil, html: nil, json: nil, template: nil, status: nil, locals: {},
               layout: :inherit)
      ensure_no_response!
      layout_choice = layout == :inherit ? self.class.layout_for(@action) : layout
      body, content_type = render_body_and_type(view, plain: plain, html: html, json: json,
                                                      template: template, locals: locals,
                                                      layout: layout_choice)
      build_response(status_code(status || 200), body, "content-type" => content_type)
    end

    def redirect_to(url, status: 302)
      ensure_no_response!
      build_response(status_code(status), "", "location" => url.to_s)
    end

    def head(status, **headers)
      ensure_no_response!
      hdrs = { "content-type" => "text/html" }
      headers.each { |k, v| hdrs[k.to_s.tr("_", "-")] = v.to_s }
      build_response(status_code(status), "", hdrs)
    end

    def respond_to(&block)
      collector = FormatCollector.new
      block.call(collector)

      format = pick_format(@env["HTTP_ACCEPT"], collector)
      if format
        invoke_format_handler(collector, format)
      else
        head 406
      end
    end

    def response(text, status = 200, headers = {})
      ensure_no_response!
      build_response(status, [text].flatten, headers)
    end

    def controller_name
      Reins.to_underscore(self.class.to_s.gsub(/Controller$/, ""))
    end

    private

    def run_before
      self.class.filters_for(:before, @action).each do |f|
        send(f[:name])
        break if @response
      end
    end

    def run_after
      self.class.filters_for(:after, @action).each { |f| send(f[:name]) }
    end

    def run_around(filters, &final)
      if filters.empty?
        final.call
      else
        head, *rest = filters
        send(head[:name]) { run_around(rest, &final) }
      end
    end

    def render_body_and_type(view, plain:, html:, json:, template:, locals:, layout:)
      return [plain.to_s,         "text/plain"]       if plain
      return [html.to_s,          "text/html"]        if html
      return [JSON.dump(json),    "application/json"] if json
      return [render_template(template, locals, layout), "text/html"] if template
      return [render_template("#{controller_name}/#{view}", locals, layout), "text/html"] if view

      raise ArgumentError, "render: nothing to render"
    end

    def render_template(path, locals, layout)
      view = View.new
      view.set_vars(instance_hash)
      view.render_template(path, locals: locals, layout: layout)
    end

    def auto_render
      send(:render, @action)
    end

    def instance_hash
      instance_variables.to_h { |name| [name, instance_variable_get(name)] }
    end

    def build_response(status, body, headers)
      @response = Rack::Response.new([body].flatten, status, headers)
    end

    def ensure_no_response!
      raise Reins::DoubleResponse, "render or redirect_to was already called" if @response
    end

    def status_code(value)
      return value if value.is_a?(Integer)

      Rack::Utils::SYMBOL_TO_STATUS_CODE.fetch(value) do
        raise ArgumentError, "unknown status: #{value.inspect}"
      end
    end

    def sweep_flash
      @flash&.sweep!
    end

    def rack_tuple
      [@response.status, @response.headers, [@response.body].flatten]
    end

    def invoke_format_handler(collector, format)
      handler = collector.handlers[format]
      handler[:block] ? handler[:block].call : render(@action)
    end

    def pick_format(accept, collector)
      return collector.ordered_formats.first if accept.nil? || accept.strip.empty?

      parse_accept(accept).each do |mime|
        return collector.ordered_formats.first if mime == "*/*" && !collector.ordered_formats.empty?
        return :html if mime == "text/html" && collector.ordered_formats.include?(:html)
        return :json if mime == "application/json" && collector.ordered_formats.include?(:json)
      end
      nil
    end

    def parse_accept(accept)
      accept.split(",").map { |part| part.split(";").first.strip }
    end

    class FormatCollector
      attr_reader :ordered_formats, :handlers

      def initialize
        @ordered_formats = []
        @handlers = {}
      end

      def html(&block) = register(:html, "text/html", block)
      def json(&block) = register(:json, "application/json", block)

      def register(name, mime, block)
        @ordered_formats << name
        @handlers[name] = { mime: mime, block: block }
      end
    end
  end
end
