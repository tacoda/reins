module Reins
  module Model
    class Errors
      def initialize
        @messages = Hash.new { |h, k| h[k] = [] }
      end

      def add(attr, message)
        @messages[attr.to_sym] << message
      end

      def [](attr)
        @messages[attr.to_sym]
      end

      def empty?
        @messages.values.all?(&:empty?)
      end

      def clear
        @messages.clear
      end

      def full_messages
        @messages.flat_map do |attr, msgs|
          label = humanize(attr.to_s)
          msgs.map { |m| "#{label} #{m}" }
        end
      end

      private

      def humanize(str)
        words = str.tr("_", " ").split
        return "" if words.empty?

        ([words.first.capitalize] + words[1..]).join(" ")
      end
    end
  end
end
