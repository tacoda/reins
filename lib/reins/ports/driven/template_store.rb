require "reins/port"

module Reins
  module Ports
    module Driven
      # Driven port. Resolves a logical template name (e.g. "users/show",
      # "layouts/application") to a Reins::Core::View::Template::Source value.
      # The core renderer never touches the filesystem.
      module TemplateStore
        extend Reins::Port

        direction :driven

        contract  read: 1,
                  exist?: 1
      end
    end
  end
end
