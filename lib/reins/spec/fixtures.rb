require "yaml"

module Reins
  module Spec
    module Fixtures
      def self.load(model_class, yml_path)
        data = YAML.safe_load_file(yml_path, permitted_classes: [Symbol], aliases: true)
        data.each_with_object({}) do |(key, attrs), hash|
          hash[key.to_sym] = model_class.create!(attrs)
        end
      end
    end
  end
end
