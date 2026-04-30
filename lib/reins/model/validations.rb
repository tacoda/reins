module Reins
  module Model
    module Validations
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def validators
          @validators ||= []
        end

        def all_validators
          ancestors.select { |a| a.respond_to?(:validators) }.flat_map(&:validators).uniq
        end

        def validates(attr, **rules)
          rules.each do |type, options|
            klass = validator_class(type)
            validators << klass.new(attr, options, self)
          end
        end

        private

        def validator_class(type)
          case type
          when :presence then PresenceValidator
          when :length then LengthValidator
          when :format then FormatValidator
          when :uniqueness then UniquenessValidator
          else raise ArgumentError, "unknown validator: #{type}"
          end
        end
      end

      def valid?
        errors.clear
        run_callbacks(:before_validation) if respond_to?(:run_callbacks)
        self.class.all_validators.each { |v| v.validate(self, errors) }
        run_callbacks(:after_validation) if respond_to?(:run_callbacks)
        errors.empty?
      end

      def errors
        @errors ||= Errors.new
      end

      class Validator
        def initialize(attr, options, model)
          @attr = attr
          @options = options
          @model = model
        end

        protected

        def value_for(record)
          record[@attr]
        end
      end

      class PresenceValidator < Validator
        def validate(record, errors)
          value = value_for(record)
          errors.add(@attr, "can't be blank") if blank?(value)
        end

        private

        def blank?(value)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end

      class LengthValidator < Validator
        def validate(record, errors)
          value = value_for(record)
          return if value.nil?

          length = value.to_s.length
          errors.add(@attr, "is the wrong length") if @options[:in] && !@options[:in].include?(length)
          errors.add(@attr, "is too short") if @options[:minimum] && length < @options[:minimum]
          errors.add(@attr, "is too long") if @options[:maximum] && length > @options[:maximum]
        end
      end

      class FormatValidator < Validator
        def validate(record, errors)
          value = value_for(record)
          return if value.nil?

          regex = @options.is_a?(Regexp) ? @options : @options[:with]
          errors.add(@attr, "is invalid") unless regex.match?(value.to_s)
        end
      end

      class UniquenessValidator < Validator
        def validate(record, errors)
          value = value_for(record)
          return if value.nil?

          scope = @model.where(@attr => value)
          scope = scope.where("#{@model.primary_key} != ?", record.id) if record.persisted?
          errors.add(@attr, "has already been taken") if scope.first
        end
      end
    end
  end
end
