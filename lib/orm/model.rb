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
  end
end
