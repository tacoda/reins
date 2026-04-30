module Reins
  module Model
    module Persistence
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def find(id)
          record = find_by(primary_key => id)
          raise Reins::Model::RecordNotFound, "#{name} with #{primary_key}=#{id} not found" if record.nil?

          record
        end

        def find_by(conditions)
          where(conditions).first
        end

        def create(attrs = {})
          record = new(attrs)
          record.save
          record
        end

        def create!(attrs = {})
          record = new(attrs)
          record.save!
          record
        end

        def transaction(&)
          Reins::Database.connection.transaction(&)
        end

        def instantiate_from_row(row)
          record = allocate
          record.send(:init_from_row, row)
          record
        end
      end

      def save
        return false if respond_to?(:valid?) && !valid?

        run_save_callbacks { persisted? ? update_record : insert_record }
        true
      end

      def save!
        save || raise(Reins::Model::RecordInvalid, self)
      end

      def update(attrs)
        attrs.each { |k, v| @attributes[k.to_s] = v }
        save
      end

      def update!(attrs)
        attrs.each { |k, v| @attributes[k.to_s] = v }
        save!
      end

      def destroy
        run_callbacks(:before_destroy) if respond_to?(:run_callbacks)
        sql = "DELETE FROM #{self.class.table_name} WHERE #{self.class.primary_key} = ?"
        Reins::Database.connection.execute(sql, [id])
        @persisted = false
        run_callbacks(:after_destroy) if respond_to?(:run_callbacks)
        self
      end

      def reload
        record = self.class.find(id)
        @attributes = record.send(:attributes_hash).dup
        @associations = nil
        self
      end

      def persisted? = @persisted == true
      def new_record? = !persisted?

      private

      def init_from_row(row)
        @attributes = row.transform_keys(&:to_s)
        @persisted = true
      end

      def attributes_hash
        @attributes
      end

      def run_save_callbacks
        run_callbacks(:before_save) if respond_to?(:run_callbacks)
        if persisted?
          run_callbacks(:before_update) if respond_to?(:run_callbacks)
          yield
          run_callbacks(:after_update) if respond_to?(:run_callbacks)
        else
          run_callbacks(:before_create) if respond_to?(:run_callbacks)
          yield
          run_callbacks(:after_create) if respond_to?(:run_callbacks)
        end
        run_callbacks(:after_save) if respond_to?(:run_callbacks)
      end

      def insert_record
        touch_timestamps_for_create
        cols = @attributes.keys - [self.class.primary_key]
        values = cols.map { |c| @attributes[c] }
        placeholders = (["?"] * cols.size).join(", ")
        sql = "INSERT INTO #{self.class.table_name} (#{cols.join(', ')}) VALUES (#{placeholders})"
        db = Reins::Database.connection
        db.execute(sql, values)
        @attributes[self.class.primary_key] = db.last_insert_row_id
        @persisted = true
      end

      def update_record
        touch_timestamps_for_update
        cols = @attributes.keys - [self.class.primary_key]
        values = cols.map { |c| @attributes[c] }
        set_clause = cols.map { |c| "#{c} = ?" }.join(", ")
        sql = "UPDATE #{self.class.table_name} SET #{set_clause} WHERE #{self.class.primary_key} = ?"
        Reins::Database.connection.execute(sql, values + [id])
      end

      def touch_timestamps_for_create
        now = current_timestamp
        @attributes["created_at"] ||= now if column?("created_at")
        @attributes["updated_at"] ||= now if column?("updated_at")
      end

      def touch_timestamps_for_update
        @attributes["updated_at"] = current_timestamp if column?("updated_at")
      end

      def column?(name)
        self.class.column_names.include?(name)
      end

      def current_timestamp
        Time.now.utc.strftime("%Y-%m-%d %H:%M:%S.%6N")
      end
    end
  end
end
