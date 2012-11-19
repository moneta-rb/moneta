require 'active_record'

module Juno
  class ActiveRecord < Base
    def self.tables
      @tables ||= {}
    end

    attr_reader :table

    def initialize(options = {})
      table = options[:table] || 'juno'
      @table = self.class.tables[table] ||= begin
                                              c = Class.new(::ActiveRecord::Base)
                                              c.table_name = table
                                              c
                                            end
      @table.establish_connection(options[:connection]) if options[:connection]
      @table.connection.create_table @table.table_name do |t|
        t.binary 'key', :primary => :true
        t.binary 'value'
      end unless @table.table_exists?
    end

    def key?(key, options = {})
      !!@table.find_by_key(key_for(key))
    end

    def [](key)
      record = @table.find_by_key(key_for(key))
      record ? deserialize(record.value) : nil
    end

    def delete(key, options = {})
      record = @table.find_by_key(key_for(key))
      if record
        @table.where(:key => key_for(record.key)).delete_all
        deserialize(record.value)
      end
    end

    def store(key, value, options = {})
      record = @table.find_by_key(key_for(key))
      record ||= @table.new(:key => key_for(key))
      record.value = serialize(value)
      record.save!
      value
    end

    def clear(options = {})
      @table.delete_all
      nil
    end
  end
end
