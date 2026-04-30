module Reins
  module Model
    module Associations
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def belongs_to(name, class_name: nil, foreign_key: nil)
          klass_name = class_name || classify(name.to_s)
          fk = foreign_key || "#{name}_id"

          define_method(name) do
            @_associations ||= {}
            return @_associations[name] if @_associations.key?(name)

            target_id = @attributes[fk.to_s]
            @_associations[name] = target_id ? Object.const_get(klass_name).find_by(id: target_id) : nil
          end
        end

        def has_many(name, class_name: nil, foreign_key: nil)
          klass_name = class_name || classify(singularize(name.to_s))
          fk = foreign_key || "#{singularize(self_underscored)}_id"

          define_method(name) do
            Object.const_get(klass_name).where(fk => id)
          end
        end

        def has_one(name, class_name: nil, foreign_key: nil)
          klass_name = class_name || classify(name.to_s)
          fk = foreign_key || "#{singularize(self_underscored)}_id"

          define_method(name) do
            Object.const_get(klass_name).where(fk => id).first
          end
        end

        private

        def classify(str)
          str.to_s.split("_").map(&:capitalize).join
        end

        def singularize(str)
          str.end_with?("ies") ? "#{str[0..-4]}y" : str.chomp("s")
        end

        def self_underscored
          Reins.to_underscore(name.split("::").last)
        end
      end
    end
  end
end
