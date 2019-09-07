require 'sqlite3'

DB = SQLite3::Database.new "test1.db"

module Orm
  class Model
    def self.schema
      return @schema if @schema

      table_info = DB.table_info(table)
      @schema = {}
      table_info.each do |row|
        @schema[row['name']] = row['type']
      end

      @schema
    end

    def self.table
      name.downcase
    end

    def initialize(data)
      @hash = data
    end

    def self.find(id)
      row = DB.execute <<-SQL
        SELECT #{schema.keys.join(',')} FROM #{table}
        WHERE id = #{id.to_i};
      SQL #

      data = Hash[schema.keys.zip row[0]] # Takes an array of values and an array of keys and it shuffles them together and shoves them into a hash table.
      new(data)
    end

    def self.insert(vals)
      k = schema.keys
      v = k.map { |key| vals[key] } # getting array of values

      DB.execute <<-SQL, v
        INSERT INTO #{name.downcase}
        (#{k.join ','})
        VALUES (#{k.map { '?' }.join ','});
      SQL
    end

    def [](name)
      @hash[name]
    end

    def []=(name, value)
      @hash[name] = value
    end

    def delete! # to_i for security reasons, so no one can pass in any random SQL code
      DB.execute <<-SQL
        DELETE FROM #{self.class.table}
        WHERE id = #{@hash['id'].to_i}
      SQL
    end

    def update!
      k = @hash.keys - ['id']
      sql_k = k.map { |key| '#{key}=?' }
      v = k.map { |key| @hash[key] }

      DB.execute <<-SQL, v
        UPDATE #{self.class.table}
        SET #{sql_k.join(',')}
        WHERE id = #{@hash['id'].to_i}
      SQL
    end

    def self.create(values)
      values.delete 'id'
      insert(values)

      sql = 'SELECT last_insert_row_id();' # returns the id of what was just created
      new_id = DB.execute(sql)[0][0]
      find(new_id)
    end
  end
end
