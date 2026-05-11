require "reins/ports/driven/template_store"

module Reins
  module Adapters
    module Driven
      module Filesystem
        # Disk-backed implementation of the TemplateStore port. Resolves a
        # logical template name to a file under <views_root>/<name>.html.erb.
        # The framework's default; app authors configure the views_root at
        # the composition root when they want a non-standard location.
        class TemplateStore
          include Reins::Ports::Driven::TemplateStore

          EXTENSION = ".html.erb".freeze

          def initialize(views_root = "app/views")
            @views_root = views_root
          end

          def read(name)
            File.read(filename_for(name))
          end

          def exist?(name)
            File.exist?(filename_for(name))
          end

          private

          def filename_for(name)
            File.join(@views_root, "#{name}#{EXTENSION}")
          end
        end
      end
    end
  end
end
