require "reins/ports/driven/template_store"

module Reins
  module Adapters
    module Driven
      module Memory
        # In-memory implementation of the TemplateStore port. Constructed with
        # a Hash of template-name => source. Useful for view specs that want
        # to keep their fixtures in the test file rather than on disk.
        class TemplateStore
          include Reins::Ports::Driven::TemplateStore

          def initialize(templates = {})
            @templates = templates
          end

          def read(name)
            raise Errno::ENOENT, name unless @templates.key?(name)

            @templates[name]
          end

          def exist?(name)
            @templates.key?(name)
          end
        end
      end
    end
  end
end
