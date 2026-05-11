require "erubis"
require "reins/ports/driven/template_engine"

module Reins
  module Adapters
    module Driven
      module Erubis
        # Erubis implementation of the TemplateEngine port. Wraps
        # ::Erubis::EscapedEruby so `<%= %>` HTML-escapes by default and
        # `<%== %>` is the raw-output opt-in. Returns compiled Ruby source —
        # the renderer is responsible for `eval`ing it against the right
        # binding so view instance variables, helpers, and yield work.
        class TemplateEngine
          include Reins::Ports::Driven::TemplateEngine

          def compile(source)
            ::Erubis::EscapedEruby.new(source).src
          end
        end
      end
    end
  end
end
