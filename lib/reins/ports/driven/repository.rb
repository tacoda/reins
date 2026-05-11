module Reins
  module Ports
    module Driven
      # Driven port. Reads and writes records on behalf of the model layer.
      # The core never builds SQL — it builds Reins::Core::Model::Query values
      # and hands them to a Repository, which is the only place an adapter is
      # allowed to translate to its storage technology.
      #
      # Default adapter: Reins::Adapters::Driven::Sqlite::Repository.
      # Test adapter:    Reins::Adapters::Driven::Memory::Repository.
      module Repository
        CONTRACT = {
          find_all: 1,
          insert: 2,
          update: 4,
          delete: 3,
          count: 1,
          pluck: 2,
          transaction: 0
        }.freeze
      end
    end
  end
end
