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

    def evaluate(template)
      eruby = Erubis::Eruby.new(template)
      eval eruby.src # rubocop:disable Security/Eval
    end

    def h(str)
      CGI.escapeHTML(str)
    end
  end
end
