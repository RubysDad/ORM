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
      SQL

      data = Hash[schema.keys.zip row[0]] # Takes an array of values and an array of keys and it shuffles them together and shoves them into a hash table.
      new(data)
    end
  end
end
