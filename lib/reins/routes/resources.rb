module Reins
  module Routes
    class Resources
      def initialize(dsl, name)
        @dsl = dsl
        @plural = name.to_s
        @singular = singularize(@plural)
        @collection = "/#{@plural}"
        @member = "/#{@plural}/:id"
      end

      def expand!
        @dsl.get(@collection,            "#{@plural}#index",   as: @plural.to_sym)
        @dsl.get("#{@collection}/new",   "#{@plural}#new",     as: :"new_#{@singular}")
        @dsl.post(@collection,           "#{@plural}#create")
        @dsl.get(@member,                "#{@plural}#show",    as: @singular.to_sym)
        @dsl.get("#{@member}/edit",      "#{@plural}#edit",    as: :"edit_#{@singular}")
        @dsl.put(@member,                "#{@plural}#update")
        @dsl.patch(@member,              "#{@plural}#update")
        @dsl.delete(@member,             "#{@plural}#destroy")
      end

      private

      # Naive — sufficient for the v1 test set. M4+ may pull in a real inflector.
      def singularize(name)
        name.end_with?("ies") ? "#{name[0..-4]}y" : name.chomp("s")
      end
    end
  end
end
