require "reins/port"

module Reins
  module Ports
    module Driven
      # Driven port. Compiles a Template::Source into a callable that, when
      # invoked with a binding-like context, returns the rendered string.
      module TemplateEngine
        extend Reins::Port

        direction :driven

        contract compile: 1
      end
    end
  end
end
