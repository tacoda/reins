module Reins
  module Model
    module Callbacks
      KINDS = %i[
        before_validation after_validation
        before_save after_save
        before_create after_create
        before_update after_update
        before_destroy after_destroy
        after_initialize
      ].freeze

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        KINDS.each do |kind|
          define_method(kind) do |method_name|
            own_callbacks[kind] << method_name.to_sym
          end
        end

        def own_callbacks
          @own_callbacks ||= Hash.new { |h, k| h[k] = [] }
        end

        def all_callbacks_for(kind)
          ancestors
            .select { |a| a.respond_to?(:own_callbacks) }
            .reverse
            .flat_map { |a| a.own_callbacks[kind] }
        end
      end

      def run_callbacks(kind)
        self.class.all_callbacks_for(kind).each { |method_name| send(method_name) }
      end
    end
  end
end
