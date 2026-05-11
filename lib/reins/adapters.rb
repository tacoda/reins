require "reins/adapters/driven/memory/file_system"
require "reins/adapters/driven/memory/repository"
require "reins/adapters/driven/memory/schema_inspector"
require "reins/adapters/driven/memory/template_store"
require "reins/adapters/driven/filesystem/real"
require "reins/adapters/driven/filesystem/template_store"
require "reins/adapters/driven/sqlite/repository"
require "reins/adapters/driven/sqlite/schema_inspector"
require "reins/adapters/driven/sqlite/schema_migrator"
require "reins/adapters/driven/erubis/template_engine"
require "reins/adapters/driven/zeitwerk/autoloader"
require "reins/adapters/driven/noop/autoloader"

module Reins
  module Adapters
    module Driving; end
    module Driven; end
  end
end
