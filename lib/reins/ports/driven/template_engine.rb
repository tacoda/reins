module Reins
  module Ports
    module Driven
      # Driven port. Compiles a Template::Source into a callable that, when
      # invoked with a binding-like context, returns the rendered string.
      module TemplateEngine
        CONTRACT = {
          compile: 1
        }.freeze
      end
    end
  end
end
