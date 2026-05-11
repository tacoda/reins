module Reins
  module Core
    module Cli
      module Commands
        # Core command for `reins routes` — formats a route rules collection
        # as a table. The Thor adapter is responsible for loading the
        # Reins::Application from config.ru and handing the rules in;
        # this command does no I/O of its own except writing to stdout.
        class Routes
          HEADERS = ['Prefix', 'Verb', 'URI Pattern', 'Controller#Action'].freeze

          def initialize(stdout: $stdout)
            @stdout = stdout
          end

          def run(rules)
            rows = build_rows(rules)
            widths = column_widths(rows)
            @stdout.puts(format_row(HEADERS, widths))
            rows.each { |row| @stdout.puts(format_row(row, widths)) }
          end

          private

          def build_rows(rules)
            rules.flat_map do |rule|
              rule.verbs_for_allow_header.map do |verb|
                [rule.name.to_s, verb, rule.pattern, rule.dest.to_s]
              end
            end
          end

          def column_widths(rows)
            (0..3).map do |i|
              ([HEADERS[i]] + rows.map { |r| r[i] }).map(&:length).max
            end
          end

          def format_row(row, widths)
            row.each_with_index.map { |cell, i| cell.ljust(widths[i]) }.join("  ")
          end
        end
      end
    end
  end
end
