require "reins/routes/rule"
require "reins/routes/resources"
require "reins/routes/url_helpers"

module Reins
  module Routes
    class DSL
      attr_reader :rules

      def initialize
        @rules = []
      end

      def get(path, dest = nil, **) = add(:get, path, dest, **)
      def post(path, dest = nil, **) = add(:post, path, dest, **)
      def put(path, dest = nil, **) = add(:put, path, dest, **)
      def patch(path, dest = nil, **) = add(:patch, path, dest, **)
      def delete(path, dest = nil, **) = add(:delete, path, dest, **)

      def root(dest, **)
        get("/", dest, **, as: :root)
      end

      def match(path, dest = nil, **)
        add(:all, path, dest, **)
      end

      def resources(name)
        Resources.new(self, name).expand!
      end

      # Returns one of:
      #   - a Rack-callable (proc) when a rule matched verb+path
      #   - a Rack-callable returning [405, ...] when path matched but verb did not
      #   - nil when no rule matched the path
      def check(verb, path)
        path_only_match = false
        @rules.each do |rule|
          params = rule.match(verb, path)
          return resolve(rule.dest, params) if params

          path_only_match = true if rule.matches_path?(path)
        end

        return method_not_allowed(path) if path_only_match

        nil
      end

      private

      def add(verb, path, dest, as: nil, constraints: {})
        rule = Rule.new(verb: verb, pattern: path, dest: dest, name: as, constraints: constraints)
        @rules << rule
        UrlHelpers.define_for(rule)
        rule
      end

      def resolve(dest, params)
        return dest if dest.respond_to?(:call)

        controller, action = dest.to_s.split("#", 2)
        klass = Object.const_get("#{controller.split('_').map(&:capitalize).join}Controller")
        klass.action(action, params)
      end

      def method_not_allowed(path)
        allowed = @rules.select { |r| r.matches_path?(path) }
                        .flat_map(&:verbs_for_allow_header)
                        .uniq
        lambda { |_env|
          [405,
           { 'content-type' => 'text/html', 'Allow' => allowed.join(', ') },
           ['Method Not Allowed']]
        }
      end
    end
  end
end
