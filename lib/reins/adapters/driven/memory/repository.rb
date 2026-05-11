require "reins/ports/driven/repository"

module Reins
  module Adapters
    module Driven
      module Memory
        # In-memory implementation of the Repository port. Useful for fast
        # unit tests that don't want SQLite at all. Supports Hash-form wheres
        # and a small whitelist of string fragments ("col = ?", "col != ?",
        # "col <> ?") — the patterns Reins itself uses. Anything outside the
        # whitelist raises rather than silently being misinterpreted.
        class Repository
          include Reins::Ports::Driven::Repository

          FRAGMENT = /\A\s*(\w+)\s*(=|!=|<>)\s*\?\s*\z/

          def initialize
            @tables = Hash.new { |h, k| h[k] = [] }
            @next_id = Hash.new(0)
          end

          def insert(table, attrs)
            row = attrs.transform_keys(&:to_s)
            @next_id[table] += 1
            row["id"] ||= @next_id[table]
            @tables[table] << row
            row["id"]
          end

          def update(table, attrs, primary_key, primary_value)
            row = find_row(table, primary_key, primary_value)
            return unless row

            attrs.each { |k, v| row[k.to_s] = v }
          end

          def delete(table, primary_key, primary_value)
            @tables[table].reject! { |r| r[primary_key.to_s] == primary_value }
          end

          def find_all(query)
            apply_pagination(apply_order(apply_wheres(@tables[query.table].dup, query.wheres), query.orders),
                             query.limit, query.offset)
          end

          def count(query)
            apply_wheres(@tables[query.table].dup, query.wheres).size
          end

          def pluck(query, field)
            field = field.to_s
            apply_pagination(apply_order(apply_wheres(@tables[query.table].dup, query.wheres), query.orders),
                             query.limit, query.offset).map { |r| r[field] }
          end

          def transaction
            snapshot = deep_dup_state
            yield
          rescue StandardError
            @tables = snapshot[:tables]
            @next_id = snapshot[:next_id]
            raise
          end

          private

          def find_row(table, primary_key, primary_value)
            @tables[table].find { |r| r[primary_key.to_s] == primary_value }
          end

          def apply_wheres(rows, wheres)
            wheres.reduce(rows) { |acc, (fragment, params)| filter(acc, fragment, params) }
          end

          def filter(rows, fragment, params)
            m = FRAGMENT.match(fragment)
            unless m
              raise ArgumentError,
                    "Memory::Repository: where fragment #{fragment.inspect} not supported " \
                    "(only Hash conditions and 'col = ?' / 'col != ?' / 'col <> ?' string fragments)"
            end

            column = m[1]
            operator = m[2]
            value = params.first
            rows.select { |r| compare(r[column], operator, value) }
          end

          def compare(actual, operator, expected)
            case operator
            when "=" then actual == expected
            when "!=", "<>" then actual != expected
            end
          end

          def apply_order(rows, orders)
            return rows if orders.empty?

            rows.sort do |left, right|
              orders.each.lazy.map { |spec| compare_by_order(left, right, spec) }.find { |c| c != 0 } || 0
            end
          end

          def compare_by_order(left, right, order_spec)
            field, direction = order_spec.split(/\s+/)
            cmp = left[field] <=> right[field]
            direction&.upcase == "DESC" ? -cmp : cmp
          end

          def apply_pagination(rows, limit, offset)
            rows = rows.drop(offset) if offset
            rows = rows.take(limit) if limit
            rows
          end

          def deep_dup_state
            {
              tables: @tables.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(k, v), h|
                h[k] = v.map(&:dup)
              end,
              next_id: @next_id.dup
            }
          end
        end
      end
    end
  end
end
