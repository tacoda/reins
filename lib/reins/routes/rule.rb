module Reins
  module Routes
    class Rule
      attr_reader :verb, :pattern, :regexp, :vars, :dest, :name, :constraints

      def initialize(verb:, pattern:, dest:, name: nil, constraints: {})
        @verb = verb
        @pattern = pattern
        @dest = dest
        @name = name
        @constraints = constraints
        @vars, @regexp = compile(pattern)
      end

      # Returns extracted params Hash on a full match, nil otherwise.
      def match(request_verb, path)
        return nil unless verb_matches?(request_verb)

        match_path(path)
      end

      # True if the path (and constraints) match — verb-agnostic.
      # Used to distinguish 404 from 405.
      def matches_path?(path)
        !match_path(path).nil?
      end

      def verb_matches?(request_verb)
        @verb == :all || @verb == request_verb
      end

      def verbs_for_allow_header
        @verb == :all ? %w[GET POST PUT PATCH DELETE] : [@verb.to_s.upcase]
      end

      private

      def match_path(path)
        m = @regexp.match(path)
        return nil unless m

        params = {}
        @vars.each_with_index { |v, i| params[v] = m.captures[i] }
        return nil unless constraints_satisfied?(params)

        params
      end

      def constraints_satisfied?(params)
        @constraints.all? do |var, regexp|
          value = params[var.to_s]
          !value.nil? && regexp.match?(value)
        end
      end

      def compile(pattern)
        parts = pattern.split("/").reject(&:empty?)
        vars = []
        regexp_parts = parts.map do |part|
          case part[0]
          when ":"
            vars << part[1..]
            "([^/]+)"
          when "*"
            vars << part[1..]
            "(.*)"
          else
            part
          end
        end
        [vars, Regexp.new("^/#{regexp_parts.join('/')}$")]
      end
    end
  end
end
