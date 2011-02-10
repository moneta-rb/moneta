begin
  require 'active_record'
rescue LoadError
  puts "You need the activerecord gem in order to use the ActiveRecord moneta store"
end

module Moneta
  class ActiveRecord
    include Moneta::Defaults

    def initialize(options = {})
      @options = options
      unless self.class.const_defined?('Store')
        self.class.const_set('Store', Class.new(::ActiveRecord::Base)) # this prevents loading issues when active_record gem is unavailable
      end
      Store.establish_connection(@options[:connection] || raise("Must specify :connection"))
      Store.set_table_name(@options[:table] || 'moneta_store')
    end

    def migrate
      unless Store.table_exists?
        Store.connection.create_table Store.table_name, :id => false do |t|
          t.string   'key', :primary => :true
          t.string   'value'
        end
      end
    end

    def key?(key)
      record = Store.find_by_key key_for(key)
      !record.nil?
    end

    def [](key)
      record = Store.find_by_key key_for(key)
      record ? deserialize(record.value) : nil
    end

    def delete(key)
      record = Store.find_by_key key_for(key)
      if record
        Store.where(:key => key_for(record.key)).delete_all
        deserialize record.value
      end
    end

    def store(key, value, options = {})
      record = Store.new :key => key_for(key), :value => serialize(value)
      record.save!
      value
    end

    def clear
      Store.delete_all
    end
  end
end
