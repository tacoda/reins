module Reins
  module Ports
    module Driven
      # Driven port. Applies a Reins::Core::Migration::Operation to the
      # underlying store. The core migration class records operations as data;
      # the migrator is the only place where DDL is emitted.
      module SchemaMigrator
        CONTRACT = {
          create_table: 2,
          drop_table: 1,
          add_column: 3,
          remove_column: 2,
          add_index: 2,
          remove_index: 2,
          rename_column: 3,
          execute: 1
        }.freeze
      end
    end
  end
end
