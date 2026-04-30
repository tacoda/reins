require "erubis"
require "cgi"
require "reins/routes/url_helpers"

module Reins
  class View
    include Reins::Routes::UrlHelpers

    # rubocop:disable Naming/AccessorMethodName
    def set_vars(instance_vars)
      instance_vars.each do |name, value|
        instance_variable_set(name, value)
      end
    end
    # rubocop:enable Naming/AccessorMethodName

    def evaluate(template, locals = {})
      eruby = Erubis::Eruby.new(template)
      bind = binding
      locals.each { |k, v| bind.local_variable_set(k, v) }
      eval(eruby.src, bind) # rubocop:disable Security/Eval
    end

    def h(str)
      CGI.escapeHTML(str)
    end
  end
end
