require 'sqlite3'

module Juno
  class Sqlite < Base
    def initialize(options = {})
      raise 'No option :file specified' unless options[:file]
      table = options[:table] || 'juno'
      @db = ::SQLite3::Database.new(options[:file])
      @db.execute("create table if not exists #{table} (key string primary key, value string)")
      @select = @db.prepare("select value from #{table} where key = ?")
      @insert = @db.prepare("insert into #{table} values (?, ?)")
      @delete = @db.prepare("delete from #{table} where key = ?")
      @clear = @db.prepare("delete from #{table}")
    end

    def key?(key, options = {})
      !@select.execute!(key_for(key)).empty?
    end

    def load(key, options = {})
      rows = @select.execute!(key_for(key))
      rows.empty? ? nil : deserialize(rows.first.first)
    end

    def store(key, value, options = {})
      @insert.execute!(key_for(key), serialize(value))
      value
    end

    def delete(key, options = {})
      value = self[key]
      @delete.execute!(key_for(key))
      value
    end

    def clear(options = {})
      @clear.execute!
      nil
    end

    def close
      @select.close
      @insert.close
      @delete.close
      @clear.close
      @db.close
      nil
    end
  end
end
